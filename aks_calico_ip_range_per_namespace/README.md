## Calico

```bash
cd infra
terraform init
terraform apply 

$resourceGroup = $(terraform output -raw resource_group_name)
$aksClusterName = $(terraform output -raw aks_cluster_name)

az aks get-credentials --resource-group $resourceGroup --name $aksClusterName

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/tigera-operator.yaml
kubectl create -f installation.yaml
kubectl apply -f ip_pools.yaml
kubectl apply -f ../workloads.yaml
```

## Egress Gateway is part of Calico Enterprise

[Egress Gateway](https://docs.tigera.io/calico-enterprise/latest/networking/egress/egress-gateway-azure#azure-route-server)