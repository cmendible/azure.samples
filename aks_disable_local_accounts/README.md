Requieres [kubelogin](https://github.com/Azure/kubelogin)

``` powershell
Invoke-WebRequest https://github.com/Azure/kubelogin/releases/download/v0.0.11/kubelogin-win-amd64.zip  -OutFile kubelogin.zip
Expand-Archive .\kubelogin.zip
mv .\kubelogin\bin\windows_amd64\kubelogin.exe .\kubelogin.exe
rm .\kubelogin\
rm .\kubelogin.zip
```

## Install

``` shell
terraform init
terraform apply -auto-approve
```
