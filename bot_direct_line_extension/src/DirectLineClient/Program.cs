using System;
using System.Configuration;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Bot.Connector.DirectLine;
using Newtonsoft.Json;

var directLineSecret = Environment.GetEnvironmentVariable("DirectLineSecret");
var botId = Environment.GetEnvironmentVariable("BotId");
var fromUser = "dummy";

async Task StartBotConversation()
{
    // if you are using a region-specific endpoint, change the uri and uncomment the code
    // var directLineUri = "https://bot-direct-line-6334.azurewebsites.net/.bot/v3/directline/"; // endpoint in Azure Public Cloud
    // var client = new DirectLineClient(new Uri(directLineUri), new DirectLineClientCredentials(directLineSecret));

    DirectLineClient client = new DirectLineClient(directLineSecret)!;

    // Force 429
    // var numbers = Enumerable.Range(0, 10000).ToList();

    // Parallel.ForEach(numbers, number =>
    //     {
    //         var a = client.Conversations.StartConversationAsync();
    //         Console.WriteLine(number);
    //     });

    var conversation = await client.Conversations.StartConversationAsync();

    Console.WriteLine(conversation.ConversationId);

    new System.Threading.Thread(async () => await ReadBotMessagesAsync(client, conversation.ConversationId)).Start();

    Console.Write("Command> ");

    while (true)
    {
        var input = Console.ReadLine().Trim();

        if (input.ToLower() == "exit")
        {
            break;
        }
        else
        {
            if (input.Length > 0)
            {
                Activity userMessage = new Activity
                {
                    From = new ChannelAccount(fromUser),
                    Text = input,
                    Type = ActivityTypes.Message
                };

                await client.Conversations.PostActivityAsync(conversation.ConversationId, userMessage);
            }
        }
    }
}

async Task ReadBotMessagesAsync(DirectLineClient client, string conversationId)
{
    string? watermark = null;

    while (true)
    {
        var activitySet = await client.Conversations.GetActivitiesAsync(conversationId, watermark);
        watermark = activitySet?.Watermark;

        var activities = from x in activitySet.Activities
                         where x.From.Id == botId
                         select x;

        foreach (Activity activity in activities)
        {
            Console.WriteLine(activity.Text);

            Console.Write("Command> ");
        }

        await Task.Delay(TimeSpan.FromSeconds(1)).ConfigureAwait(false);
    }
}

StartBotConversation().Wait();