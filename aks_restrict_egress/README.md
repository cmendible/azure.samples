## Install

``` powershell
terraform init
terraform apply --auto-approve
```

``` powershell
$resource_group=$(terraform output resource_group)
$aks_name=$(terraform output aks_name)
az aks get-credentials --resource-group $resource_group --name $aks_name
```

## References:

* [Control egress traffic for cluster nodes in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/limit-egress-traffic#restrict-egress-traffic-using-azure-firewall)
