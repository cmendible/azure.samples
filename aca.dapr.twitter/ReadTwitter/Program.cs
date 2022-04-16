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
        e.MapSubscribeHandler();
        e.MapPost("/tweets", async (ReadTwitter.TwitterQueryResponse tweet, DaprClient daprClient, ILogger<Program> log) =>
            {
                await daprClient.SaveStateAsync("statestore", tweet!.IdStr, tweet);

                var content = tweet.FullText;
                if (content == "")
                {
                    content = tweet.Text;
                }

                var message = $"{tweet.User.ScreenName} said: {content}";

                // Log tweet
                log.LogInformation(message);

                // Publish tweet
                await daprClient.PublishEventAsync("messagebus", "tweets", tweet);
            });
    });

app.Run();
