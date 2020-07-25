namespace Function.ReadTwitter
{
    using Microsoft.Azure.WebJobs;
    using Microsoft.Extensions.Logging;
    using Dapr.AzureFunctions.Extension;
    using System.Text.Json;
    using System.Threading.Tasks;

    public static class ReadTwitter
    {
        /// <summary>
        /// Read, save, and queue Tweets
        /// </summary>
        [FunctionName("ReadTwitter")]
        public static async Task Run(
            [DaprBindingTrigger(BindingName = "twitter")] TwitterQueryResponse twitterResponse,
            [DaprState("statestore", Key = "{twitterResponse.IdStr}")] IAsyncCollector<Tweet> state,
            [DaprPublish(Topic = "feed")] IAsyncCollector<DaprPubSubEvent> tweetEvent,
            ILogger log)
        {
            log.LogInformation("C# function processed a ReadTwitter request from the Dapr Runtime.");

            var content = twitterResponse.FullText;
            if (content == "")
            {
                content = twitterResponse.Text;
            }

            log.LogInformation($"Received tweet text {content} from {twitterResponse.User.ScreenName}.");

            var tweet = new Tweet() { Text = content, User = twitterResponse.User.ScreenName };

            await state.AddAsync(tweet);

            await tweetEvent.AddAsync(new DaprPubSubEvent(JsonSerializer.Serialize(tweet)));

            // https://github.com/mchmarny/dapr-pipeline/blob/master/src/processor/handler.go
        }
    }
}
