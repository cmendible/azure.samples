Requires [kubelogin](https://github.com/Azure/kubelogin)

``` powershell
Invoke-WebRequest https://github.com/Azure/kubelogin/releases/download/v0.0.11/kubelogin-win-amd64.zip  -OutFile kubelogin.zip
Expand-Archive .\kubelogin.zip
mv .\kubelogin\bin\windows_amd64\kubelogin.exe .\kubelogin.exe
rm .\kubelogin\
rm .\kubelogin.zip
```

```bash
wget -O- https://github.com/Azure/kubelogin/releases/download/v0.0.28/kubelogin-linux-arm64.zip > kubelogin.zip
unzip kubelogin.zip
mv ./bin/linux_arm64/kubelogin kubelogin
rm kubelogin.zip
rm -rf ./bin
sudo mv kubelogin /usr/local/bin/kubelogin
```

## Install

``` shell
terraform init
terraform apply -auto-approve
```

```bash
az aks get-credentials --resource-group aks-no-local-accounts --name aksnolocalaccounts
kubectl get po
```