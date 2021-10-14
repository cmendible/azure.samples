using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using System.Text.Json;
using Microsoft.Identity.Web;
using Microsoft.Extensions.Configuration;
using System.IO;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using System.Collections.Generic;

var config = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json")
                    .AddEnvironmentVariables()
                    .Build();

WebHost.CreateDefaultBuilder().
ConfigureServices(s =>
{
    s.AddSingleton(new JsonSerializerOptions()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
    });

    s.AddMicrosoftIdentityWebApiAuthentication(config);

    s.Configure<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme, options =>
    {
        options.TokenValidationParameters.ValidAudiences = new List<string>() { config["Audience"] };
    });
}).
Configure(app =>
{
    app.UseRouting();
    app.UseAuthentication();
    app.UseAuthorization();

    app.UseEndpoints(e =>
    {
        e.MapGet("/protected",
            async c =>
            {
                var serializerOptions = e.ServiceProvider.GetRequiredService<JsonSerializerOptions>();
                var data = new { message = "This message is protected" };

                c.Response.ContentType = "application/json";
                await JsonSerializer.SerializeAsync(c.Response.Body, data, serializerOptions);
            })
            .RequireAuthorization()
            .RequireScope("read");
    });
}).Build().Run();