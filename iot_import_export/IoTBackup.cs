using Azure.Storage.Blobs;
using Azure.Storage.Sas;
using Microsoft.Azure.Devices;

namespace IoT.Backup
{
    public class ImportExportDevicesSample
    {
        private const int BlobWriteBytes = 500;

        private readonly string _IotHubConnectionString;
        private readonly string _storageAccountConnectionString;
        private readonly string _containerName;
        private readonly string _blobNamePrefix;

        private readonly string _hubDevicesBlobName;
        private readonly string _hubConfigsBlobName;

        private const string DeviceImportErrorsBlobName = "importErrors.log";
        private const string ConfigImportErrorsBlobName = "importConfigErrors.log";

        // The container used to hold the blob containing the list of import/export files.
        // This is a sample-wide variable. If this project doesn't find this container, it will create it.
        private BlobContainerClient _blobContainerClient;
        private string _containerUri;

        public ImportExportDevicesSample(
            string sourceIotHubConnectionString,
            string sourceStorageAccountConnectionString,
            string containerName,
            string blobNamePrefix)
        {
            _IotHubConnectionString = sourceIotHubConnectionString;
            _storageAccountConnectionString = sourceStorageAccountConnectionString;
            _containerName = containerName;
            _blobNamePrefix = blobNamePrefix;

            _hubDevicesBlobName = _blobNamePrefix + "ExportDevices.txt";
            _hubConfigsBlobName = _blobNamePrefix + "ExportConfigs.txt";
        }

        public async Task ExportAsync(
            bool includeConfigurations)
        {
            using var registryManager = RegistryManager.CreateFromConnectionString(_IotHubConnectionString);

            // This sets cloud blob container and returns container URI (w/shared access token).
            await PrepareStorageForImportExportAsync(_storageAccountConnectionString);

            // Read the devices from the hub and write them to blob storage.
            await ExportDevicesAsync(registryManager, _hubDevicesBlobName, _hubConfigsBlobName, includeConfigurations);
        }

        public async Task ImportAsync(
            bool includeConfigurations)
        {
            using var registryManager = RegistryManager.CreateFromConnectionString(_IotHubConnectionString);

            // This sets cloud blob container and returns container URI (w/shared access token).
            await PrepareStorageForImportExportAsync(_storageAccountConnectionString);

            // Read the devices from the hub and write them to blob storage.
            await ImportDevicesAsync(registryManager, includeConfigurations);
        }

        /// <summary>
        /// Sets up references to the blob hierarchy objects, sets containerURI with an SAS for access.
        /// Create the container if it doesn't exist.
        /// </summary>
        /// <returns>URI to blob container, including SAS token</returns>
        private async Task PrepareStorageForImportExportAsync(string storageAccountConnectionString)
        {
            Console.WriteLine("Preparing storage.");

            try
            {
                // Get reference to storage account.
                // This is the storage account used to hold the import and export file lists.
                var blobServiceClient = new BlobServiceClient(storageAccountConnectionString);

                _blobContainerClient = blobServiceClient.GetBlobContainerClient(_containerName);
                await _blobContainerClient.CreateIfNotExistsAsync();

                // Get the URI to the container.
                _containerUri = _blobContainerClient
                    .GenerateSasUri(
                        BlobContainerSasPermissions.Write
                            | BlobContainerSasPermissions.Read
                            | BlobContainerSasPermissions.Delete,
                        DateTime.UtcNow.AddHours(24)).ToString();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error setting up storage account. Msg = {ex.Message}");
                throw;
            }
        }

        /// Get the list of devices registered to the IoT hub
        ///   and export it to a blob as deserialized objects.
        private async Task ExportDevicesAsync(RegistryManager registryManager, string devicesBlobName, string configsBlobName, bool includeConfigurations)
        {
            try
            {
                Console.WriteLine("Running a registry manager job to export devices from the hub.");

                // Call an export job on the IoT hub to retrieve all devices.
                // This writes them to the container.
                var exportJob = JobProperties.CreateForExportJob(
                    _containerUri,
                    excludeKeysInExport: false,
                    devicesBlobName);
                exportJob.IncludeConfigurations = includeConfigurations;
                exportJob.ConfigurationsBlobName = configsBlobName;
                exportJob = await registryManager.ExportDevicesAsync(exportJob);
                await WaitForJobAsync(registryManager, exportJob);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error exporting devices to blob storage. Exception message = {ex.Message}");
            }
        }

        private async Task ImportDevicesAsync(RegistryManager registryManager, bool includeConfigurations)
        {
            Console.WriteLine("Running a registry manager job to import the entries from the devices file to the destination IoT hub.");

            // Step 3: Call import using the same blob to create all devices.
            // Loads and adds the devices to the destination IoT hub.
            var importJob = JobProperties.CreateForImportJob(
                _containerUri,
                _containerUri,
                _hubDevicesBlobName);
            importJob.IncludeConfigurations = includeConfigurations;
            importJob.ConfigurationsBlobName = _hubConfigsBlobName;
            importJob = await registryManager.ImportDevicesAsync(importJob);
            await WaitForJobAsync(registryManager, importJob);
        }
        private static async Task WaitForJobAsync(RegistryManager registryManager, JobProperties job)
        {
            // Wait until job is finished
            while (true)
            {
                job = await registryManager.GetJobAsync(job.JobId);
                if (job.Status == JobStatus.Completed
                    || job.Status == JobStatus.Failed
                    || job.Status == JobStatus.Cancelled)
                {
                    // Job has finished executing
                    break;
                }
                Console.WriteLine($"\tJob status is {job.Status}...");

                await Task.Delay(TimeSpan.FromSeconds(5));
            }

            Console.WriteLine($"Job finished with status of {job.Status}.");
        }
    }
}