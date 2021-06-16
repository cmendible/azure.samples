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
    var redisPassword = Environment.GetEnvironmentVariable("RedisPassword");

    services.AddSignalR(hubOptions =>
    {
        hubOptions.EnableDetailedErrors = true;
        // hubOptions.KeepAliveInterval = TimeSpan.FromMinutes(1);
    })
    .AddStackExchangeRedis($"redis-master.redis.svc.cluster.local,password={redisPassword}");
}).
Configure(app =>
{
    app.UseHttpsRedirection();

    app.UseRouting();

    app.UseEndpoints(endpoints =>
    {
        endpoints.MapHub<Chat>("/default", options =>
            {
                options.Transports = HttpTransportType.WebSockets;
            });

        endpoints.MapGet("/", c => c.Response.WriteAsync("Hello from SignalR!"));
    });
}).Build().Run();

public class Chat : Hub
{
    public override Task OnConnectedAsync()
    {
        var name = Context.GetHttpContext().Request.Query["name"];
        return Clients.All.SendAsync("Send", $"{name} joined the chat");
    }

    public override Task OnDisconnectedAsync(Exception exception)
    {
        var name = Context.GetHttpContext().Request.Query["name"];
        return Clients.All.SendAsync("Send", $"{name} left the chat");
    }

    public Task Send(string name, string message)
    {
        return Clients.All.SendAsync("Send", $"{name}: {message}");
    }

    public Task SendToOthers(string name, string message)
    {
        return Clients.Others.SendAsync("Send", $"{name}: {message}");
    }

    public Task SendToConnection(string connectionId, string name, string message)
    {
        return Clients.Client(connectionId).SendAsync("Send", $"Private message from {name}: {message}");
    }

    public Task SendToGroup(string groupName, string name, string message)
    {
        return Clients.Group(groupName).SendAsync("Send", $"{name}@{groupName}: {message}");
    }

    public Task SendToOthersInGroup(string groupName, string name, string message)
    {
        return Clients.OthersInGroup(groupName).SendAsync("Send", $"{name}@{groupName}: {message}");
    }

    public async Task JoinGroup(string groupName, string name)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);

        await Clients.Group(groupName).SendAsync("Send", $"{name} joined {groupName}");
    }

    public async Task LeaveGroup(string groupName, string name)
    {
        await Clients.Group(groupName).SendAsync("Send", $"{name} left {groupName}");

        await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
    }

    public async Task Echo(string name, string message)
    {
        await Clients.Caller.SendAsync("Send", $"{name}: {message}");
    }
}