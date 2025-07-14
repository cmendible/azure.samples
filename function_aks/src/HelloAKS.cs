using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace src
{
    public class HelloAKS
    {
        private readonly ILogger<HelloAKS> _logger;

        public HelloAKS(ILogger<HelloAKS> logger)
        {
            _logger = logger;
        }

        [Function("HelloAKS")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");
            return new OkObjectResult("Welcome to Azure Functions!");
        }
    }
}
