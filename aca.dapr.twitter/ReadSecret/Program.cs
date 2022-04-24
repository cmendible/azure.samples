using Dapr.Client;
using Dapr.Extensions.Configuration;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddDaprClient();

// Create Dapr Client
var client = new DaprClientBuilder()
    .Build();

builder.Configuration.AddDaprSecretStore("demosecrets", client, TimeSpan.FromSeconds(10));

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

app.MapGet("/", (IConfiguration configuration) =>
    {
        var secretValue = configuration["super-secret"];

        return secretValue;
    });

app.Run();
