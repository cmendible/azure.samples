using System.Net.Http;
using System.Net.Security;
using System.Security.Authentication;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;

var allSuites = Enum.GetValues(typeof(TlsCipherSuite)).Cast<TlsCipherSuite>().ToArray();

var handler = new SocketsHttpHandler
{
    SslOptions = new SslClientAuthenticationOptions
    {
        // Specify allowed TLS protocols
        EnabledSslProtocols = SslProtocols.Tls | SslProtocols.Tls11 | SslProtocols.Tls12 | SslProtocols.Tls13,

        // Ignore certificate validation (for dev/test only!)
        RemoteCertificateValidationCallback = (sender, certificate, chain, errors) => true,

        // Specify allowed cipher suites
        CipherSuitesPolicy = new CipherSuitesPolicy(allSuites)
    }
};

var builder = FunctionsApplication.CreateBuilder(args);

builder.Services.AddHttpClient("CustomClient")
    .ConfigurePrimaryHttpMessageHandler(() => handler);

builder.ConfigureFunctionsWebApplication();

// Application Insights isn't enabled by default. See https://aka.ms/AAt8mw4.
// builder.Services
//     .AddApplicationInsightsTelemetryWorkerService()
//     .ConfigureFunctionsApplicationInsights();

builder.Build().Run();
