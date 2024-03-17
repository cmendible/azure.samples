using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Extensions.Logging;
using Models;

namespace OpenAI.Plugin
{
    public class Greet
    {
        private static readonly JsonSerializerOptions _jsonOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        private readonly ILogger _logger;
        private readonly Kernel _kernel;

        public Greet(ILoggerFactory loggerFactory, Kernel kernel)
        {
            _logger = loggerFactory.CreateLogger<Greet>();
            _kernel = kernel;
        }

        [Function("Greet Plugin")]
        [OpenApiOperation(operationId: "GreetPlugin", tags: new[] { "GreetPlugin" }, Description = "Used to greet a a person given it's name and age.")]
        [OpenApiParameter(name: "name", Description = "Name of the person to greet'", Required = true)]
        [OpenApiParameter(name: "age", Description = "Age of the person to greet", Required = true)]
        // [OpenApiRequestBody("application/json", typeof(ExecuteFunctionRequest), Description = "Variables to use when executing the specified function.", Required = true)]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "application/json", bodyType: typeof(ExecuteFunctionResponse), Description = "Returns the response from the AI.")]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.BadRequest, contentType: "application/json", bodyType: typeof(ErrorResponse), Description = "Returned if the request body is invalid.")]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.NotFound, contentType: "application/json", bodyType: typeof(ErrorResponse), Description = "Returned if the semantic function could not be found.")]
        public async Task<HttpResponseData> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "plugins/greet/{name}/{age:int:min(1)}")] HttpRequestData req,
            FunctionContext executionContext,
            string name,
            string age)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            // #pragma warning disable CA1062
            //             var functionRequest = await JsonSerializer.DeserializeAsync<ExecuteFunctionRequest>(req.Body, _jsonOptions).ConfigureAwait(false);
            // #pragma warning disable CA1062
            // if (functionRequest == null)
            // {
            //     return await CreateResponseAsync(req, HttpStatusCode.BadRequest, new ErrorResponse() { Message = $"Invalid request body {functionRequest}" }).ConfigureAwait(false);
            // }

            var context = new KernelArguments
            {
                { "name", name },
                { "age", age }
            };

            var result = await _kernel.InvokeAsync("Greet", $"Greet", context).ConfigureAwait(false);

            return await CreateResponseAsync(req, HttpStatusCode.OK, new ExecuteFunctionResponse() { Response = result.ToString() }).ConfigureAwait(false);
        }

        private static async Task<HttpResponseData> CreateResponseAsync(HttpRequestData requestData, HttpStatusCode statusCode, object responseBody)
        {
            var responseData = requestData.CreateResponse(statusCode);
            await responseData.WriteAsJsonAsync(responseBody).ConfigureAwait(false);
            return responseData;
        }
    }
}
