var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDaprClient();

// Create Dapr Client
var client = new DaprClientBuilder()
    .Build();

var app = builder.Build();

app.UseCloudEvents();

app.UseRouting();

var rnd = new Random();
var nameGenerator = new PersonNameGenerator(rnd);

var inMemoryCameras = new Dictionary<int, Camera>();

app.MapGet("/{cameraId:int}", (int cameraId) =>
    {
        Camera camera = default;
        if (!inMemoryCameras.Keys.Contains(cameraId))
        {
            var owner = nameGenerator.GenerateRandomFirstAndLastName();
            camera = new Camera(cameraId, owner);
        }
        else
        {
            camera = inMemoryCameras[cameraId];
        }

        return camera;
    });

app.Run();
