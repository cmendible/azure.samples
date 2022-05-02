var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDaprClient();

var app = builder.Build();

app.UseCloudEvents();

app.UseRouting();

app.UseEndpoints(e =>
    {
        e.MapPost("/race-control", async (RunnerRegistered msg, DaprClient daprClient, ILogger<Program> log) =>
            {
                var result = daprClient.CreateInvokeMethodRequest(HttpMethod.Get, "runner-service", $"/{msg.BibNumber}");
                var runner = await daprClient.InvokeMethodAsync<Runner>(result);

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
