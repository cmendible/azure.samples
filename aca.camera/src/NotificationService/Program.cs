var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDaprClient();

var app = builder.Build();

app.UseCloudEvents();

app.UseRouting();

app.UseEndpoints(e =>
    {
        e.MapPost("/camera-control", async (CameraMotionDetected msg, DaprClient daprClient, ILogger<Program> log) =>
            {
                var result = daprClient.CreateInvokeMethodRequest(HttpMethod.Get, "camera-service", $"/{msg.CameraId}");
                var camera = await daprClient.InvokeMethodAsync<Camera>(result);

                log.LogInformation($"Motion Detected!!! Notification should be sent to owner {camera.Owner} with Camera Id: {msg.CameraId}!!!");

                return Results.Ok();
            }).WithTopic("pubsub", "camera-control");

        e.MapSubscribeHandler();
    });

app.Run();
