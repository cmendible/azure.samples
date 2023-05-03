## To deploy and test the mock

``` shell
terraform apply
apim_url=$(terraform output -raw url)
curl -k -i $apim_url
```

### Since no subscription was provided:

``` shell
HTTP/1.1 401 Access Denied
Content-Length: 152
Content-Type: application/json
WWW-Authenticate: AzureApiManagementKey realm="https://apim-cfm.azure-api.net/mock",name="Ocp-Apim-Subscription-Key",type="header"
Date: Thu, 20 May 2021 06:51:05 GMT

{ "statusCode": 401, "message": "Access denied due to missing subscription key. Make sure to include subscription key when making requests to an API." }
```

### Providing a subscription:

``` shell
apim_url=$(terraform output -raw url)
key=<Get Built-in all-access subscription key from portal>
curl -k -i -H "Ocp-Apim-Subscription-Key: $key" $apim_url
```

``` shell
docker run -d -p 8080:8080 -p 8081:8081 --name apim-docker-test --env-file env.conf mcr.microsoft.com/azure-api-management/gateway:latest
key=<Get Built-in all-access subscription key from portal>
curl -k -i -H "Ocp-Apim-Subscription-Key: $key" https://localhost:8081/mock
curl -k -i -H "Ocp-Apim-Subscription-Key: $key" https://localhost:8081/ip
```

## Purge APIM

``` shell
az apim deletedservice list
az apim deletedservice purge --location <location> --service-name <apim name>
```

## Service Principal

``` shell
az ad sp create-for-rbac --name <sp name> --role contributor --scopes /subscriptions/<subscription id> --sdk-auth
```

## Github Secrets

Create the a secret with json value resulting from the previous step:

AZURE_CREDENTIALS = <JSON_SP_FOR_GITHUB>
