## Install

``` powershell
az extension add --name aks-preview
az feature register --namespace "Microsoft.ContainerService" --name "PodSubnetPreview"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/PodSubnetPreview')].{Name:name,State:properties.state}"
```

``` powershell
terraform init
terraform apply --auto-approve
```

``` powershell
$resource_group=$(terraform output resource_group)
$aks_name=$(terraform output aks_name)
az aks get-credentials --resource-group $resource_group --name $aks_name
```

``` powershell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace ingress -f internal-ingress.yaml
```

``` powershell
kubectl apply -f demo.yaml
```

## References:

* [Dynamic allocation of IPs and enhanced subnet support (preview)](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni#dynamic-allocation-of-ips-and-enhanced-subnet-support-preview)

> Systems in the same virtual network as the AKS cluster see the pod IP as the source address for any traffic from the pod. Systems outside the AKS cluster virtual network see the node IP as the source address for any traffic from the pod.
