var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDaprClient();
builder.Services.AddActors(options =>
{
    options.Actors.RegisterActor<CameraActor>();
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
        e.MapPost("/camera-control", async (CameraMotionDetected msg, ILogger<Program> logger) =>
            {
                try
                {
                    logger.LogInformation($"Received change for camwera {msg.CameraId.ToString()}");
                    var actorId = new ActorId(msg.CameraId.ToString());
                    var proxy = ActorProxy.Create<ICameraActor>(actorId, nameof(CameraActor));
                    await proxy.RegisterMotionAsync(msg);
                    return Results.Ok();
                }
                catch
                {
                    return Results.StatusCode(500);
                }
            }).WithTopic("pubsub", "camera-control");

        e.MapSubscribeHandler();
    });

app.Run();
