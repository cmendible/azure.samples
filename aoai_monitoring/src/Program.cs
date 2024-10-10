using System.Diagnostics.Tracing;
using Azure.AI.OpenAI;
using Azure.Core.Diagnostics;
using Azure.Identity;
using OpenAI.Chat;

// Setup a listener to monitor logged events.
using AzureEventSourceListener listener = AzureEventSourceListener.CreateConsoleLogger(EventLevel.Verbose);
using AzureEventSourceListener traceListener = AzureEventSourceListener.CreateTraceLogger(EventLevel.Verbose);

string endpoint = Environment.GetEnvironmentVariable("OPENAI_ENDPOINT");

AzureOpenAIClient azureClient = new(
    new Uri(endpoint),
    new DefaultAzureCredential());

ChatClient chatClient = azureClient.GetChatClient("gpt-35-turbo");

for (int i = 0; i < 100; i++)
{
    ChatCompletion completion = await chatClient.CompleteChatAsync(
    [
        // System messages represent instructions or other guidance about how the assistant should behave
        new SystemChatMessage("You are a helpful assistant that knows math."),
        // User messages represent user input, whether historical or the most recent input
        new UserChatMessage($"Hi, what is the nect number after {i}?"),
    ]);

    Console.WriteLine($"{completion.Role}: {completion.Content[0].Text}");
}
