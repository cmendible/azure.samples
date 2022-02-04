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
using Microsoft.IdentityModel.Clients.ActiveDirectory;

var config = new ConfigurationBuilder()
                    .AddEnvironmentVariables()
                    .Build();

var authorityUri = $"https://login.microsoftonline.com/{config["tenant_id"]}";
var clientId = config["client_id"];
var clientSecret = config["client_secret"];

var authContext = new AuthenticationContext(authorityUri);
var clientCredential = new ClientCredential(clientId, clientSecret);
var authResult = await authContext.AcquireTokenAsync("https://batch.core.windows.net", clientCredential);

var batchUrl = config["batch_url"];
var storageName = config["storage_name"];
var storageKey = config["storage_key"];
var cred = new BatchTokenCredentials(batchUrl, authResult.AccessToken);
var storageCred = new StorageCredentials(storageName, storageKey);

var storageAccount = new CloudStorageAccount(storageCred, true);
var batchClient = BatchClient.Open(cred);

var jobId = "myJob";
var taskId = "myTask";
var containerName = taskId.ToLower();

var job = await batchClient.JobOperations.GetJobAsync(jobId);

var container = storageAccount.CreateCloudBlobClient().GetContainerReference(containerName);

await container.CreateIfNotExistsAsync();

var containerSas = container.GetSharedAccessSignature(new SharedAccessBlobPolicy()
{
    Permissions = SharedAccessBlobPermissions.Write,
    SharedAccessExpiryTime = DateTimeOffset.UtcNow.AddDays(1)
});
var containerUrl = container.Uri.AbsoluteUri + containerSas;

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