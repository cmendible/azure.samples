var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDaprClient();
builder.Services.AddActors(options =>
{
    options.Actors.RegisterActor<RunnerActor>();
});

var app = builder.Build();

// configure web-app
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.UseCloudEvents();

// configure routing
app.MapActorsHandlers();
app.UseRouting();

app.UseEndpoints(e =>
    {
        e.MapPost("/race-control", async (RunnerRegistered msg, ILogger<Program> logger) =>
            {
                try
                {
                    logger.LogInformation($"Received change for runner {msg.BibNumber.ToString()}");
                    var actorId = new ActorId(msg.BibNumber.ToString());
                    var proxy = ActorProxy.Create<IRunnerActor>(actorId, nameof(RunnerActor));
                    switch (msg.CheckPoint)
                    {
                        case CheckPoint.Start:
                            await proxy.RegisterStartAsync(msg);
                            break;
                        case CheckPoint.HalfMarathon:
                            await proxy.RegisterHalfAsync(msg);
                            break;
                        case CheckPoint.Marathon:
                            await proxy.RegisterFinisherAsync(msg);
                            break;
                    }
                    return Results.Ok();
                }
                catch
                {
                    return Results.StatusCode(500);
                }
            }).WithTopic("pubsub", "race-control");

        e.MapSubscribeHandler();
    });

app.Run();
