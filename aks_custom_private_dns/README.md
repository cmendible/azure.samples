## Install

``` powershell
terraform apply

$resource_group=$(terraform output resource_group)
$aks_name=$(terraform output aks_name)

az aks command invoke --resource-group $resource_group --name $aks_name --command "kubectl get pods -n kube-system"
```