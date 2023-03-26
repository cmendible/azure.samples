## ASP.NET Core WASM sample

```bash
dotnet build
wasmtime .\bin\Debug\net7.0\aspnetcore_wasm.wasm --tcplisten localhost:8000
```

## .NET WASM sample on k3d/spin/runwasi 

### Azure Container Registry

```bash
az group create --name wasm --location westeurope
az acr create --resource-group wasm --name wasmcfm --sku Standard
az acr update --name wasmcfm --anonymous-pull-enabled
```

### Build .NET sample and image

```bash	
cd ./dotnet_wasm
dotnet build
docker build -t wasmcfm.azurecr.io/sample:v1 .
az acr login -n wasmcfm
docker push wasmcfm.azurecr.io/sample:v1
```

### Install on AKS

```bash
az aks create --name wasmaks --resource-group wasm -s Standard_DS3_v2 --node-osdisk-type Ephemeral
az aks nodepool add --resource-group wasm --cluster-name wasmaks --name mywasipool --node-count 1 --workload-runtime WasmWasi
az aks get-credentials --resource-group wasm --name wasmaks
kubectl apply -f ./deploy/aks/runtime.yml
kubectl apply -f ./deploy/aks/workload.yml
kubectl run -it busybox --image busybox -- sh
wget http://wasm-dotnet/ -O-
```

### Install k3d Clsuter

```bash
k3d cluster create netcoreconf --image ghcr.io/deislabs/containerd-wasm-shims/examples/k3d:latest -p "8081:80@loadbalancer" --agents 2
```

### Deploy RuntimeClass

```bash
kubectl apply -f ./deploy/runtime.yml
```

### Deploy .NET sample

```bash
kubectl apply -f ./deploy/workload.yml
```

### Test .NET sample

```bash
curl http://localhost:8081
```

### Delete k3d Cluster

```bash
k3d cluster delete netcoreconf
```
