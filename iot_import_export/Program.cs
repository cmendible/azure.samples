using System.Diagnostics;
using CommandLine;

namespace IoT.Backup
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            // Parse application parameters
            Parameters parameters = null;
            ParserResult<Parameters> result = Parser.Default.ParseArguments<Parameters>(args)
                .WithParsed(
                    parsedParams =>
                    {
                        parameters = parsedParams;
                    })
                .WithNotParsed(
                    errors =>
                    {
                        Console.WriteLine(parameters);
                        Environment.Exit(1);
                    });

            if (!parameters.Validate())
            {
                Console.WriteLine(CommandLine.Text.HelpText.AutoBuild(result, null, null));
                Environment.Exit(1);
            }

            try
            {
                // Instantiate the class and run the sample.
                var importExportDevicesSample = new ImportExportDevicesSample(
                    parameters.IotHubConnectionString,
                    parameters.StorageConnectionString,
                    parameters.ContainerName,
                    parameters.BlobNamePrefix);

                if (parameters.Import)
                {
                    Console.WriteLine("Importing devices from the storage account to the IoT hub.");
                    await importExportDevicesSample
                        .ImportAsync(
                            parameters.IncludeConfigurations
                        );
                }
                else
                {
                    Console.WriteLine("Exporting devices from the IoT hub to the storage account.");
                    await importExportDevicesSample
                        .ExportAsync(
                            parameters.IncludeConfigurations
                        );
                }
            }
            catch (Exception ex)
            {
                Debug.Print($"Error. Description = {ex.Message}");
                Console.WriteLine($"Error. Description = {ex.Message}\n{ex.StackTrace}");
            }

            Console.WriteLine("Sample finished.");
        }
    }
}
