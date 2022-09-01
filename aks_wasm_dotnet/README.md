``` bash
az feature register --namespace "Microsoft.ContainerService" --name "WasmNodePoolPreview"

az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/WasmNodePoolPreview')].{Name:name,State:properties.state}"

az provider register --namespace Microsoft.ContainerService

az extension add --name aks-preview

az extension add --name aks-preview

az aks nodepool add --resource-group wasm --cluster-name wasm --name mywasipool --node-count 1 --workload-runtime wasmwasi

./wasm-to-oci push dotnet_wasm.wasm wasmcfm.azurecr.io/sample:v1

az acr update --name wasmcfm --anonymous-pull-enabled

kubectl apply -f ./deploy.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install hello-wasi bitnami/nginx -f values.yaml
```

Reference:

[AKS: Use WASI Node Pools](https://docs.microsoft.com/en-us/azure/aks/use-wasi-node-pools)