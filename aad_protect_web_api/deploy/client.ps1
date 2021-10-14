param(
    [Parameter(Mandatory=$true)]
    [string]
    $tenantId,
    [Parameter(Mandatory=$true)]
    [string]
    $clientId
)

if ((get-module MSAL.PS) -eq $null)
{
    echo "installing MSAL.PS"
    Install-Module -Name MSAL.PS -Scope CurrentUser -AcceptLicense -Force 
    # If you encounter this error:
    # WARNING: The specified module 'MSAL.PS' with PowerShellGetFormatVersion '2.0' is not supported by the current version of PowerShellGet. 
    # Get the latest version of the PowerShellGet module to install this module, 'MSAL.PS'
    # Install as Admin:
    # Install-PackageProvider NuGet -Force
    # Install-Module PowerShellGet -Force
}

$scope = "api://passport-test-api/read"
$redirectUri = "http://localhost"
$url = "http://localhost:1000/protected"
$token = Get-MsalToken -TenantId $tenantId -ClientId $clientId -Interactive -Scope $scope -RedirectUri $redirectUri

echo "Please Complete Azure AD Login"
echo ""
echo "Bearer Token:"
echo $($token.AccessToken)
echo ""
echo "Protect API Call:"
curl -k -i -H "Authorization: Bearer $($token.AccessToken)" $url