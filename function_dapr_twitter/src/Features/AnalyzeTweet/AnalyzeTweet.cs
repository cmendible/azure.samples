namespace Function.ReadTwitter
{
    using Microsoft.Azure.WebJobs;
    using Dapr.AzureFunctions.Extension;
    using System.Threading.Tasks;
    using CloudNative.CloudEvents;
    using Microsoft.Extensions.Logging;

    public static class AnalyzeTweet
    {
        /// <summary>
        /// Read, save, and queue Tweets
        /// </summary>
        [FunctionName("AnalyzeTweet")]
        public static async Task Run(
            [DaprTopicTrigger(Topic = "feed")] CloudEvent @event,
            ILogger log)
        {
            log.LogInformation($"RECEIVED {@event.Data}");
        }
    }
}