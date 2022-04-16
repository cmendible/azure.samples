using Azure;
using Azure.AI.TextAnalytics;
using Dapr.Client;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddDaprClient();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCloudEvents();

app.UseRouting();

app.UseAuthorization();

app.UseEndpoints(e =>
    {
        e.MapPost("/tweets", async (ReadTwitter.TwitterQueryResponse tweet, DaprClient daprClient, IConfiguration config, ILogger<Program> log) =>
            {
                var credentials = new AzureKeyCredential(config["COGNITIVE_SERVICE_KEY"]);
                var endpoint = new Uri("https://eastus.api.cognitive.microsoft.com/");
                var client = new TextAnalyticsClient(endpoint, credentials);

                var result = client.AnalyzeSentiment(tweet.Text);
                log.LogInformation($"Sentiment Score: {result.Value.ConfidenceScores.Positive:0.00}");

                // if (result.Score < 0.3)
                // {
                //     await messages.AddAsync(new DaprBindingMessage($"Negative tweet: {tweet.Text} with score {result.Score:0.00}"));
                // }
            }).WithTopic("messagebus", "tweets");
        e.MapSubscribeHandler();
    });

app.Run();
