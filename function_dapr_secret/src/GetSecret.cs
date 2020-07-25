namespace Function.DaprSecret
{
    using Microsoft.Azure.WebJobs;
    using Microsoft.Extensions.Logging;
    using Dapr.AzureFunctions.Extension;
    using System.Collections.Generic;

    public static class GetSecret
    {
        /// <summary>
        /// Get Secret
        /// </summary>
        [FunctionName("GetSecret")]
        public static void Run(
            [DaprServiceInvocationTrigger] object args,
            [DaprSecret("demosecrets", "redisPass")] IDictionary<string, string> secret,
            ILogger log)
        {
            log.LogInformation("C# function processed a GetSecret request from the Dapr Runtime.");

            log.LogInformation("Stored secret: Key = {0}, Value = {1}", "redisPass", secret["redisPass"]);
        }
    }
}