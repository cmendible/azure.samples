## Install

### Register the AKS preview extension

``` bash
az extension add --name aks-preview
az extension update --name aks-preview
```

### Register the Azure Overlay Preview feature

``` bash
az feature register --namespace "Microsoft.ContainerService" --name "AzureOverlayPreview"
az feature show --namespace "Microsoft.ContainerService" --name "AzureOverlayPreview"
```

### Deploy the AKS cluster
``` bash
terraform init
terraform apply --auto-approve
```

``` bash
resource_group=$(terraform output -raw resource_group)
aks_name=$(terraform output -raw aks_name)
az aks get-credentials --resource-group $resource_group --name $aks_name
kubectl apply -f k8s/
```

## References:

* [https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay)
* [Control egress traffic for cluster nodes in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/limit-egress-traffic#restrict-egress-traffic-using-azure-firewall)
