using System.Net.Http;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Function.HttpHandler.Ssl
{
    public class CallExternalService
    {
        private readonly ILogger<CallExternalService> _logger;
        private readonly IHttpClientFactory _httpClientFactory;

        public CallExternalService(IHttpClientFactory httpClientFactory, ILogger<CallExternalService> logger)
        {
            _logger = logger;
            _httpClientFactory = httpClientFactory;
        }

        [Function("call")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            // Use httpClient to call self-signed.badssl.com
            using var httpClient = _httpClientFactory.CreateClient("CustomClient");
            var response = await httpClient.GetAsync("https://self-signed.badssl.com/");
            if (response.IsSuccessStatusCode)
            {
                return new OkObjectResult("Called external service with self-signed certificate successfully.");
            }
            else
            {
                Console.WriteLine($"Failed to retrieve content. Status code: {response.StatusCode}");
                return new BadRequestObjectResult("Failed to call external service with self-signed certificate.");
            }
        }
    }
}
