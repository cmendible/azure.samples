Console.WriteLine("Starting NatyBuilder...");

// environment variables
var subscriptionId = Environment.GetEnvironmentVariable("SUBSCRIPTION_ID");
var registryName = Environment.GetEnvironmentVariable("REGISTRY_NAME");
var agentPool = Environment.GetEnvironmentVariable("AGENT_POOL");
var imageName = Environment.GetEnvironmentVariable("IMAGE_NAME");

// Get azure credentials
var clientId = Environment.GetEnvironmentVariable("ARM_CLIENT_ID");
var clientSecret = Environment.GetEnvironmentVariable("ARM_CLIENT_SECRET");
var tenantId = Environment.GetEnvironmentVariable("ARM_TENANT_ID");

// check 
if (string.IsNullOrEmpty(subscriptionId))
{
    Console.WriteLine("SUBSCRIPTION_ID is not set");
    return;
}

if (string.IsNullOrEmpty(registryName))
{
    Console.WriteLine("REGISTRY_NAME is not set");
    return;
}

if (string.IsNullOrEmpty(agentPool))
{
    Console.WriteLine("AGENT_POOL is not set");
    return;
}

if (string.IsNullOrEmpty(imageName))
{
    Console.WriteLine("IMAGE_NAME is not set");
    return;
}

Console.WriteLine($"SUBSCRIPTION_ID: {subscriptionId}");
Console.WriteLine($"REGISTRY_NAME: {registryName}");
Console.WriteLine($"AGENT_POOL: {agentPool}");
Console.WriteLine($"IMAGE_NAME: {imageName}");

if (clientId == null && clientSecret == null && tenantId == null)
{
    Console.WriteLine("az login using Managed Identity...");
    "az".Run(".", "login", "--identity");
}
else
{
    Console.WriteLine("az login using env variables...");
    "az".Run(".", "login", "--service-principal", "-u", $"{clientId}", "-p", $"{clientSecret}", "--tenant", $"{tenantId}");
}

"az".Run(".", "account", "set", "--subscription", $"{subscriptionId}");
"az".Run(".", "acr", "build", "--registry", $"{registryName}", "--agent-pool", $"{agentPool}", "--image", $"{imageName}", "--file", "./app/Dockerfile", "./app");