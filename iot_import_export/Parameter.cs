using CommandLine;

namespace IoT.Backup
{
    /// <summary>
    /// Configurable parameters for the sample.
    /// </summary>
    /// <remarks>
    /// To get these connection strings, log into https://portal.azure.com, go to Resources, open the IoT hub, open Shared Access Policies, open iothubowner, and copy a connection string.
    /// </remarks>
    internal class Parameters
    {
        [Option(
            'i',
            "IoTHubConnectionString",
            Required = false,
            HelpText = "The service connection string with permissions to manage devices for the IoT hub. "
                + "Defaults to environment variable 'IOTHUB_CONN_STRING'.")]
        public string IotHubConnectionString { get; set; } = Environment.GetEnvironmentVariable("SOURCE_IOTHUB_CONN_STRING");


        [Option(
            's',
            "StorageConnectionString",
            Required = false,
            HelpText = "The storage account connection string to use with the IoT hub for migrating device data "
                + "Defaults to environment variable 'STORAGE_CONN_STRING'.")]
        public string StorageConnectionString { get; set; } = Environment.GetEnvironmentVariable("STORAGE_CONN_STRING");

        [Option(
            "ContainerName",
            Default = "iothub",
            HelpText = "The storage account container name for importing and exporting IoT hub devices (and configurations, if specified).")]
        public string ContainerName { get; set; }

        [Option(
            "BlobNamePrefix",
            Default = "ImportExportSample-",
            HelpText = "The prefix of the blob names to use in the storage account container for importing and exporting devices. That prefix will be used to create unique names for each step in the sample.")]
        public string BlobNamePrefix { get; set; }

        [Option(
            "IncludeConfigurations",
            Default = false,
            HelpText = "Include configurations in the generation, import, export, and clean-up. See https://docs.microsoft.com/azure/iot-hub/iot-hub-automatic-device-management.")]
        public bool IncludeConfigurations { get; set; }

        [Option(
            "Import",
            Default = false,
            HelpText = "If true, import devices from the storage account to the IoT hub. If false, export devices from the IoT hub to the storage account.")]
        public bool Import { get; set; }

        /// <summary>
        /// Loads up from environment variables for types that require parsing.
        /// </summary>
        public Parameters() { }

        public bool Validate()
        {
            return !string.IsNullOrWhiteSpace(IotHubConnectionString)
                && !string.IsNullOrWhiteSpace(StorageConnectionString);
        }
    }
}