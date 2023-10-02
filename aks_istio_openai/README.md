https://learn.microsoft.com/en-us/azure/aks/istio-deploy-addon#register-the-azureservicemeshpreview-feature-flag

az feature register --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
az feature show --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"

az feature register --namespace "Microsoft.ContainerService" --name "AKS-KedaPreview"
az feature show --namespace "Microsoft.ContainerService" --name "AKS-KedaPreview"
az provider register --namespace Microsoft.ContainerService

---
kubectl label namespace default istio.io/rev=asm-1-17


