var configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
    .Build();

var modelId = configuration["OpenAI:ModelId"]!;
var endpoint = configuration["OpenAI:Endpoint"]!;
var apiKey = configuration["OpenAI:APIKey"]!;
var embedding_deployment = configuration["OpenAI:EmbeddingDeployment"]!;
var memoryEndpoint = configuration["Memory:Endpoint"]!;
var weatherEndpoint = configuration["Plugins:WeatherEndpoint"]!;
var greetEndpoint = configuration["Plugins:GreetEndpoint"]!;

// Serveles Mewmory Sample
// UserServerlesKernelMemory(endpoint, apiKey, modelId, embedding_deployment);

// Kernel Memory Service Sample
// UseKernelMemoryService(memoryEndpoint);

var builder = Kernel.CreateBuilder();
builder.Services.AddLogging(c => c.SetMinimumLevel(LogLevel.Trace).AddDebug());
builder.Services.AddAzureOpenAIChatCompletion(modelId, endpoint, apiKey);
builder.Plugins.AddFromType<AuthorEmailPlanner>();
builder.Plugins.AddFromType<EmailPlugin>();
Kernel kernel = builder.Build();

// Import the memory plugin using the Kernel Memory Service.
kernel.ImportPluginFromObject(new MemoryPlugin(new Uri(memoryEndpoint)));

#pragma warning disable SKEXP0042 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
// Import Wetaher and Greet plugins form endpoints
// await kernel.ImportPluginFromOpenAIAsync("WeatherForecastPlugin", new Uri(weatherEndpoint)).ConfigureAwait(false);
// await kernel.ImportPluginFromOpenAIAsync("GreetPlugin", new Uri(greetEndpoint)).ConfigureAwait(false);
#pragma warning restore SKEXP0042 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.

// Retrieve the chat completion service from the kernel
IChatCompletionService chatCompletionService = kernel.GetRequiredService<IChatCompletionService>();

// Create the chat history
ChatHistory chatMessages = new ChatHistory("""
You are a friendly assistant who likes to follow the rules. You will complete required steps
and request approval before taking any consequential actions. If the user doesn't provide
enough information for you to complete a task, you will keep asking questions until you have
enough information to complete the task.
USE THE SAME LANGAUGE THE USER USES.
TRANSLATE TO THE USER LANGUAGE IF NEEDED.
""");

// Start the conversation
while (true)
{
    // Get user input
    System.Console.Write("User > ");
    chatMessages.AddUserMessage(Console.ReadLine()!);

    // Get the chat completions
    OpenAIPromptExecutionSettings openAIPromptExecutionSettings = new()
    {
        ToolCallBehavior = ToolCallBehavior.AutoInvokeKernelFunctions
    };
    var result = chatCompletionService.GetStreamingChatMessageContentsAsync(
        chatMessages,
        executionSettings: openAIPromptExecutionSettings,
        kernel: kernel);

    // Stream the results
    string fullMessage = "";
    Console.Write("Assistant > ");
    await foreach (var content in result)
    {
        Console.Write(content.Content);
        fullMessage += content.Content;
    }
    Console.WriteLine();

    // Add the message from the agent to the chat history
    chatMessages.AddAssistantMessage(fullMessage);
}

void UserServerlesKernelMemory(string endpoint, string apiKey, string modelId, string embedding_deployment)
{
    var azureOpenAITextConfig = new AzureOpenAIConfig()
    {
        Auth = AzureOpenAIConfig.AuthTypes.APIKey,
        Endpoint = endpoint,
        APIKey = apiKey,
        APIType = AzureOpenAIConfig.APITypes.ChatCompletion,
        Deployment = modelId,
        MaxTokenTotal = 8191,
        MaxRetries = 10,
    };

    var azureOpenAITextEmbeddingConfig = new AzureOpenAIConfig()
    {
        Auth = AzureOpenAIConfig.AuthTypes.APIKey,
        Endpoint = endpoint,
        APIKey = apiKey,
        APIType = AzureOpenAIConfig.APITypes.EmbeddingGeneration,
        Deployment = embedding_deployment,
        MaxTokenTotal = 8191,
        MaxRetries = 10,
    };

    var memory = new KernelMemoryBuilder()
        .WithAzureOpenAITextGeneration(azureOpenAITextConfig)
        .WithAzureOpenAITextEmbeddingGeneration(azureOpenAITextEmbeddingConfig)
        .Build<MemoryServerless>();

    memory.ImportTextAsync(
        "Carlos Mendible is a Sr Cloud Solution Architect at Microsoft. He is a great team player and has a lot of experience in the cloud",
        tags: new() { { "user", "Carlos" } }).Wait();

    var answer1 = memory.AskAsync("Tell me about Carlos").Result;
    Console.WriteLine(answer1.Result);
}

void UseKernelMemoryService(string memoryEndpoint)
{
    var memory = new MemoryWebClient(memoryEndpoint);
    memory.ImportDocumentAsync("./assets/agendabuild.png").Wait();
    memory.ImportDocumentAsync("./assets/BOE-S-2024-61.pdf").Wait();

    var answer1 = memory.AskAsync("Que session del Build viene despues de la de Carlos y David?").Result;
    Console.WriteLine(answer1.Result);
}
