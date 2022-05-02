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

var inMemoryRunners = new Dictionary<int, Runner>();

app.MapGet("/{bibNumber:int}", (int bibNumber) =>
    {
        Runner runner = default;
        if (!inMemoryRunners.Keys.Contains(bibNumber))
        {
            var name = nameGenerator.GenerateRandomFirstAndLastName();
            runner = new Runner(bibNumber, name);
        }
        else
        {
            runner = inMemoryRunners[bibNumber];
        }

        return runner;
    });

app.Run();
