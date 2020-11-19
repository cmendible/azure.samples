namespace Function.ReadTwitter
{
    using Microsoft.Azure.WebJobs;
    using Dapr.AzureFunctions.Extension;
    using System.Threading.Tasks;
    using CloudNative.CloudEvents;
    using Microsoft.Extensions.Logging;
    using System.Collections.Generic;
    using Microsoft.Azure.CognitiveServices.Language.TextAnalytics;
    using Microsoft.Azure.CognitiveServices.Language.LUIS.Authoring;
    using System.Text.Json;

    public static class AnalyzeTweet
    {
        /// <summary>
        /// Read, save, and queue Tweets
        /// </summary>
        [FunctionName("AnalyzeTweet")]
        public static async Task Run(
            [DaprTopicTrigger("messagebus", Topic = "feed")] CloudEvent @event,
            [DaprSecret("demosecrets", "cognitiveServicesKey")] IDictionary<string, string> secret,
            [DaprBinding(BindingName = "sendgrid", Operation = "create")] IAsyncCollector<DaprBindingMessage> messages,
            ILogger log)
        {
            var credentials = new ApiKeyServiceClientCredentials(secret["cognitiveServicesKey"]);
            var client = new TextAnalyticsClient(credentials)
            {
                Endpoint = "https://westeurope.api.cognitive.microsoft.com/"
            };

            var tweet = JsonSerializer.Deserialize<Tweet>(@event.Data.ToString());

            var result = await client.SentimentAsync(tweet.Text);
            log.LogInformation($"Sentiment Score: {result.Score:0.00}");

            if (result.Score < 0.3)
            {
                await messages.AddAsync(new DaprBindingMessage($"Negative tweet: {tweet.Text} with score {result.Score:0.00}"));
            }
        }
    }
}