using System.Text;
using Azure.AI.Projects;
using Azure.Identity;

var prompt = "How does wikipedia explain Euler's Identity?";

var connectionString = System.Environment.GetEnvironmentVariable("AI_FOUNDRY_PROJECT_CONNECTION_STRING");
var modelDeploymentName = System.Environment.GetEnvironmentVariable("AI_SERVICES_MODEL_DEPLOYMENT_NAME");
var bingConnectionName = System.Environment.GetEnvironmentVariable("BING_CONNECTION_NAME");

var projectClient = new AIProjectClient(connectionString, new DefaultAzureCredential());
var agentClient = projectClient.GetAgentsClient();

ConnectionResponse bingConnection = await projectClient.GetConnectionsClient().GetConnectionAsync(bingConnectionName);
var connectionId = bingConnection.Id;

ToolConnectionList connectionList = new()
{
    ConnectionList = { new ToolConnection(connectionId) }
};
BingGroundingToolDefinition bingGroundingTool = new(connectionList);

Agent agent = await agentClient.CreateAgentAsync(
    model: modelDeploymentName,
    name: "my-bing-grounded-assistant",
    instructions: $"You are a helpful assistant",
    tools: [bingGroundingTool]);

var agentId = agent.Id; AgentThread thread = await agentClient.CreateThreadAsync();

// Create message to thread
ThreadMessage message = await agentClient.CreateMessageAsync(
    thread.Id,
    MessageRole.User,
    prompt);

// Run the agent
ThreadRun run = await agentClient.CreateRunAsync(thread, agent);
do
{
    await Task.Delay(TimeSpan.FromMilliseconds(500));
    run = await agentClient.GetRunAsync(thread.Id, run.Id);
}
while (run.Status == RunStatus.Queued
    || run.Status == RunStatus.InProgress);

PageableList<ThreadMessage> messages = await agentClient.GetMessagesAsync(
    threadId: thread.Id,
    order: ListSortOrder.Ascending
);

StringBuilder sb = new();

foreach (ThreadMessage threadMessage in messages)
{
    foreach (MessageContent contentItem in threadMessage.ContentItems)
    {
        if (contentItem is MessageTextContent textItem)
        {
            string response = textItem.Text;
            if (textItem.Annotations != null)
            {
                foreach (MessageTextAnnotation annotation in textItem.Annotations)
                {
                    if (annotation is MessageTextUrlCitationAnnotation urlAnnotation)
                    {
                        response = response.Replace(urlAnnotation.Text, $" [{urlAnnotation.UrlCitation.Title}]({urlAnnotation.UrlCitation.Url})");
                    }
                }
            }
            sb.AppendLine(response);

        }
    }
}

Console.WriteLine("All messages:");
Console.WriteLine(sb.ToString());