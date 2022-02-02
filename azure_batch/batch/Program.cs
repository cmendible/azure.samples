using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Azure.Batch;
using Microsoft.Azure.Batch.Auth;
using Microsoft.Azure.Batch.Common;
using Microsoft.Extensions.Configuration;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Blob;

var config = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json")
                    .AddEnvironmentVariables()
                    .Build();

var cred = new BatchSharedKeyCredentials(config["batch.url"], config["batch.accountName"], config["batch.key"]);
var storageCred = new StorageCredentials(config["storage.name"], config["storage.key"]);

var storageAccount = new CloudStorageAccount(storageCred, true);
var batchClient = BatchClient.Open(cred);
var poolId = "cfm";
var jobId = "myJob";
var taskId = "myTask";
var containerName = taskId.ToLower();

CloudJob job = null;
try
{
    job = await batchClient.JobOperations.GetJobAsync(jobId);
}
catch
{
    job = batchClient.JobOperations.CreateJob(jobId, new PoolInformation { PoolId = poolId });
}

var container = storageAccount.CreateCloudBlobClient().GetContainerReference(containerName);

await container.CreateIfNotExistsAsync();

var containerSas = container.GetSharedAccessSignature(new SharedAccessBlobPolicy()
{
    Permissions = SharedAccessBlobPermissions.Write,
    SharedAccessExpiryTime = DateTimeOffset.UtcNow.AddDays(1)
});
var containerUrl = container.Uri.AbsoluteUri + containerSas;

// Commit the job to the Batch service
await job.CommitAsync();
Console.WriteLine($"Created job {jobId}");

// Obtain the bound job from the Batch service
await job.RefreshAsync();

// Create a series of simple tasks which dump the task environment to a file and then write random values to a text file
var tasksToAdd = new CloudTask[]
    {
        new CloudTask(taskId, "sh -c \"echo 'hello' > output.txt\"")
        {
            OutputFiles = new List<OutputFile>
                {
                    new OutputFile(
                        filePattern: @"../std*.txt",
                        destination: new OutputFileDestination(new OutputFileBlobContainerDestination(
                            containerUrl: containerUrl,
                            path: taskId)),
                        uploadOptions: new OutputFileUploadOptions(
                            uploadCondition: OutputFileUploadCondition.TaskCompletion)),
                    new OutputFile(
                        filePattern: @"output.txt",
                        destination: new OutputFileDestination(new OutputFileBlobContainerDestination(
                            containerUrl: containerUrl,
                            path: taskId + @"./output.txt")),
                        uploadOptions: new OutputFileUploadOptions(
                            uploadCondition: OutputFileUploadCondition.TaskCompletion)),
                }
        }
    };

// Add the tasks to the job; the tasks are automatically
// scheduled for execution on the nodes by the Batch service.
await job.AddTaskAsync(tasksToAdd);
Console.WriteLine($"All tasks added to job {job.Id}");
Console.WriteLine();