## Deploy Solution 

``` shell
terraform init
terraform apply --auto-approve
```

## Install Velero 

``` shell
choco install velero
```

## Use Velero

``` shell
kubectl apply -f ./app/app_with_pv.yaml
velero backup create nginx-backup --include-namespaces nginx-example --storage-location azure
kubectl delete namespaces nginx-example
velero restore create --from-backup nginx-backup
```

## References:

[Velero Examples](https://velero.io/docs/v1.8/examples/)
[Velero Helm Chart Values](https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/values.yaml)
[Velero plugins for Microsoft Azure](https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure#setup)