``` bash
az extension add --name aks-preview
az extension update --name aks-preview

az feature register --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"

az feature show --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"

export CLUSTER_NAME=aks-nap
export RESOURCE_GROUP_NAME=aks-nap-rg

az group create --name $RESOURCE_GROUP_NAME --location spaincentral

az aks create --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --node-provisioning-mode Auto --network-plugin azure --network-plugin-mode overlay --network-dataplane cilium --generate-ssh-keys

az aks get-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME

kubectl taint no --all CriticalAddonsOnly=true:NoSchedule

kubectl apply -f nodepool.yaml
```