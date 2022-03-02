## Prerequisites

A SSL certificate.

## Install

``` powershell
terraform apply

$resource_group=$(terraform output resource_group)
$aks_name=$(terraform output aks_name)

az aks command invoke --resource-group $resource_group --name $aks_name --command "kubectl get pods -n kube-system"

az aks get-credentials --resource-group $resource_group --name $aks_name

# Before running commands against the cluster, change kubeconfig's cluster server url with the gateway's FQDN or IP
# Cause I'm using a self-signed cetificate I used kubectl with the --insecure-skip-tls-verify flag
kubectl get po --insecure-skip-tls-verify
```