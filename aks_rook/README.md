## Deploy cluster with Rook Ceph using Terraform

Get the cluster credentials:

``` shell
az aks get-credentials --resource-group <resource group name> --name <aks name>
```

From the terraform folder run:

``` shell
terraform init
terraform apply -auto-approve
```

## Deploy Test Application

Deploy the test application using the following command:

``` shell
kubectl apply -f ceph-filesystem-pvc.yaml
kubectl apply -f busybox-deployment.yaml
```

Check the pvc status:

``` shell	
kubectl get pvc
```

The output should look like this (Note the status is "Bound"):

``` shell	
NAME                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
ceph-filesystem-pvc   Bound    pvc-344e2517-b421-4a81-98e2-5bc6a991d93d   1Gi        RWX            ceph-filesystem   21h   
```

Check `important.file` exists:

``` shell	
kubectl exec $(kubectl get po -l app=busy -o jsonpath='{.items[0].metadata.name}') -it -- cat /ceph-file-store/important.file
```

you should get the contents of `important.file`:

``` shell
yada yada yada
```

## Simulate VM crash

``` shell
kubectl get po -l app=rook-ceph-osd -n rook-ceph -o wide
```

Simulate a VM crash:

``` shell
$resourceGroup=$(az aks show --resource-group aks-rook --name aks-rook --query "nodeResourceGroup" --output tsv)
$cephScaleSet=$(az vmss list --resource-group $resourceGroup --query "[].{name:name}[? contains(name,'npceph')] | [0].name" --output tsv)
az vmss deallocate --resource-group $resourceGroup --name $cephScaleSet --instance-ids 0
```

Restart the server:

``` shell
az vmss start --resource-group $resourceGroup --name $cephScaleSet --instance-ids 0        
```

## Installing Rook Ceph existing AKS using helm

``` shell
helm repo add rook-release https://charts.rook.io/release
```

``` shell
helm install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph --version 1.7.3 -f ./deploy/rook-ceph-operator-values 
``` 

``` shell
helm install --create-namespace --namespace rook-ceph rook-ceph-cluster --version 1.7.3 rook-release/rook-ceph-cluster -f ./deploy/rook-ceph-cluster-values.yaml
``` 
