var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDaprClient();

var app = builder.Build();

app.UseCloudEvents();

app.UseRouting();

app.UseAuthorization();

app.UseEndpoints(e =>
    {
        e.MapPost("/NotifyRunnerStatus", async (RunnerRegistered msg, DaprClient daprClient, ILogger<Program> log) =>
            {
                var runner = await daprClient.InvokeMethodAsync<Runner>("runner-service", $"/{msg.BibNumber}");

                switch (msg.CheckPoint)
                {
                    case CheckPoint.Start:
                        log.LogInformation($"Runner {runner.Name} with bib number: {msg.BibNumber} has started the race!!!");
                        break;
                    case CheckPoint.HalfMarathon:
                        log.LogInformation($"Runner {runner.Name} with bib number: {msg.BibNumber} is half way!!!");
                        break;
                    case CheckPoint.Marathon:
                        log.LogInformation($"Runner {runner.Name} with bib number: {msg.BibNumber} has finished!!!");
                        break;
                }
                return Results.Ok();
            }).WithTopic("pubsub", "race-control");

        e.MapSubscribeHandler();
    });

app.Run();
