var builder = WebApplication.CreateBuilder(args)
    .UseWasiConnectionListener();

var app = builder.Build();

app.MapGet("/", () => "Hello, world! from WASI");

app.Start();