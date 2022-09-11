
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

### Install k3d Clsuter

```bash
k3d cluster create netcoreconf --image ghcr.io/deislabs/containerd-wasm-shims/examples/k3d:latest -p "8081:80@loadbalancer" --agents 2
```

### Deploy RuntimeClass

```bash
kubectl apply -f ./deploy/runtime.yaml
```

### Deploy .NET sample

```bash
kubectl apply -f ./deploy/workload.yaml
```

### Test .NET sample

```bash
curl http://localhost:8081
```

### Delete k3d Cluster

```bash
k3d cluster delete netcoreconf
```
