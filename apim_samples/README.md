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
WWW-Authenticate: AzureApiManagementKey realm="https://apim-cfm-demo.azure-api.net/mock",name="Ocp-Apim-Subscription-Key",type="header"
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
az rest --method delete --header "Accept=application/json" -u 'https://management.azure.com/subscriptions/<subscription id>/providers/Microsoft.ApiManagement/locations/<location>/deletedservices/<apim name>?api-version=2020-06-01-preview'
```