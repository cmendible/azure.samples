using Azure.Core;
using Azure.Identity;

var credential = new DefaultAzureCredential();
var token = credential.GetToken(new TokenRequestContext(new[] { "api://passport-test-api/read" }));
Console.WriteLine(token.Token);