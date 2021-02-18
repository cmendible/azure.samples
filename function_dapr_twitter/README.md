
## Run Function App with Dapr

```shell
dapr run -a functionapp -p 3001 -H 3501 --components-path .\components\ --config .\config.yaml -- func host start
```

or 

```shell
dapr run -a functionapp -p 3001 -H 3501 --components-path .\components\ --config .\config.yaml
```

----

func init

dotnet new globaljson --sdk-version 3.1.301

dotnet add package Microsoft.Azure.WebJobs.Extensions.Storage

dotnet add package Dapr.AzureFunctions.Extension -v 0.10.0-preview01

---

func new -l c# -n ReadTwitter

---

Copy TwitterQueryResponse.cs

Copy components foldeer

[DaprBindingTrigger(BindingName = "twitter")] TwitterQueryResponse twitterResponse,

 var content = twitterResponse.FullText;
            if (content == "")
            {
                content = twitterResponse.Text;
            }

            log.LogInformation($"Received tweet text {content} from {twitterResponse.User.ScreenName}.");

---

dapr run -a functionapp -p 3001 -H 3501 --components-path .\components\ --config .\config.yaml -- func host start

---

[DaprState("statestore", Key = "{twitterResponse.IdStr}")] IAsyncCollector<Tweet> state,


var tweet = new Tweet() { Text = content, User = twitterResponse.User.ScreenName };

await state.AddAsync(tweet);

---

using System.Text.Json;

[DaprPublish(PubSubName = "messagebus",  Topic = "feed")] IAsyncCollector<DaprPubSubEvent> tweetEvent,

await tweetEvent.AddAsync(new DaprPubSubEvent(JsonSerializer.Serialize(tweet)));

---

func new -l c# -n AnalizeTweet

[DaprTopicTrigger("messagebus", Topic = "feed")] CloudEvent @event,

var tweet = JsonSerializer.Deserialize<Tweet>(@event.Data.ToString());

log.LogInformation($"Tweet Content: {tweet.Text}");

---

dotnet add package Microsoft.Azure.CognitiveServices.Language.LUIS.Authoring
    
dotnet add package Microsoft.Azure.CognitiveServices.Language.TextAnalytics

[DaprSecret("demosecrets", "cognitiveServicesKey")] IDictionary<string, string> secret,

var credentials = new ApiKeyServiceClientCredentials(secret["cognitiveServicesKey"]);
var client = new TextAnalyticsClient(credentials)
{
    Endpoint = "https://westeurope.api.cognitive.microsoft.com/"
};

var tweet = JsonSerializer.Deserialize<Tweet>(@event.Data.ToString());

var result = await client.SentimentAsync(tweet.Text);
log.LogInformation($"Sentiment Score: {result.Score:0.00}");

---

[DaprBinding(BindingName = "sendgrid", Operation = "create")] IAsyncCollector<DaprBindingMessage> messages,

if (result.Score < 0.3)
{
    await messages.AddAsync(new DaprBindingMessage($"Negative tweet: {tweet.Text} with score {result.Score:0.00}"));
}