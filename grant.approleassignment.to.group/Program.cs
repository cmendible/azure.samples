using Azure.Identity;
using Microsoft.Graph;

// Choose a Microsoft Graph authentication provider based on scenario
// https://docs.microsoft.com/en-us/graph/sdks/choose-authentication-providers?tabs=CS#client-credentials-provider

// The client credentials flow requires that you request the
// /.default scope, and preconfigure your permissions on the
// app registration in Azure. An administrator must grant consent
// to those permissions beforehand.
var scopes = new[] { "https://graph.microsoft.com/.default" };

// Multi-tenant apps can use "common",
// single-tenant apps must use the tenant ID from the Azure portal
var tenantId = "<teant id>";

// Values from app registration
var clientId = "<client id>";
var clientSecret = "<client secret>";

// using Azure.Identity;
var options = new TokenCredentialOptions
{
    AuthorityHost = AzureAuthorityHosts.AzurePublicCloud
};

// https://docs.microsoft.com/dotnet/api/azure.identity.clientsecretcredential
var clientSecretCredential = new ClientSecretCredential(
    tenantId, clientId, clientSecret, options);

var graphClient = new GraphServiceClient(clientSecretCredential, scopes);

// https://docs.microsoft.com/en-us/graph/api/group-post-approleassignments?view=graph-rest-1.0&tabs=http
var groupId = "1af2c7ce-0fa0-4a38-8c92-cc933ee70609";

var appRoleAssignment = new AppRoleAssignment
{
	PrincipalId = Guid.Parse(groupId),
	ResourceId = Guid.Parse("<enterprise application object id>"), // ObjectId of the related Enterprise Application 
	AppRoleId = Guid.Parse("<app role dd>") // AppRole Id 
};

await graphClient.Groups[groupId].AppRoleAssignments
	.Request()
	.AddAsync(appRoleAssignment);