``` bash
az feature register --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"
az feature show --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"

terraform init
terraform apply -auto-approve

az aks get-credentials --resource-group aks-nap --name aks-nap

kubectl apply -f nodepool.yaml
```