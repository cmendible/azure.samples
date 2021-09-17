## Deploy the sample

Run:

``` shell
terraform init
terraform apply
```

## Test the static website

Login to the jumpbox server 

``` shell
$jumpboxIp=$(terraform output jumpbox_ip)
ssh adminuser@$jumpboxIp
```

Run the following command, to test the static website:

``` shell
curl -i https://<storage account name>.z6.web.core.windows.net/index.html
```

Response should be similar to:

``` shell
HTTP/1.1 200 OK
Content-Length: 180
Content-Type: application/octet-stream
Last-Modified: Fri, 17 Sep 2021 11:59:00 GMT
Accept-Ranges: bytes
ETag: "0x8D979D28981C913"
Server: Windows-Azure-Web/1.0 Microsoft-HTTPAPI/2.0
x-ms-request-id: fb6880b7-a01e-0014-42bb-ab0938000000
x-ms-version: 2018-03-28
Date: Fri, 17 Sep 2021 12:01:41 GMT

<!doctype html>
<html>
  <head>
    <title>This is your private static web app.</title>
  </head>
  <body>
    <p>This is your private static web app.</p>
  </body>
</html>
```