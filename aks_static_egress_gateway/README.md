``` bash
az feature register --namespace "Microsoft.ContainerService" --name "StaticEgressGatewayPreview"
az feature show --namespace "Microsoft.ContainerService" --name "StaticEgressGatewayPreview"

terraform init
terraform apply -auto-approve

az aks get-credentials --resource-group aks-static-egress-gateway --name aks-static-egress-gateway

```