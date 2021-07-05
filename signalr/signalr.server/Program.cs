using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http.Connections;
using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;
using System;

WebHost.CreateDefaultBuilder().
ConfigureServices(services =>
{
    var signalRServiceBuilder = services.AddSignalR(hubOptions =>
    {
        hubOptions.EnableDetailedErrors = true;
    });

    var redisConnectionString = Environment.GetEnvironmentVariable("redisConnectionString");
    if (string.IsNullOrEmpty(redisConnectionString))
    {
        signalRServiceBuilder.AddAzureSignalR();
    }
    else
    {
        signalRServiceBuilder.AddStackExchangeRedis(redisConnectionString);
    }
})
.Configure(app =>
{
    app.UseHttpsRedirection();

    app.UseRouting();

    app.UseEndpoints(endpoints =>
    {
        endpoints.MapHub<Chat>("/default", options =>
            options.Transports = HttpTransportType.WebSockets);

        endpoints.MapGet("/", c => c.Response.WriteAsync("Hello from SignalR!"));
    });
})
.Build().Run();

public class Chat : Hub
{
    public override Task OnConnectedAsync()
    {
        return Clients.All.SendAsync("Send", $"joined the chat");
    }

    public override Task OnDisconnectedAsync(Exception exception)
    {
        return Clients.All.SendAsync("Send", $"left the chat");
    }

    public async Task Echo(string name, string message) =>
        await Clients.Caller.SendAsync("Send", $"{name}: {message}");
}