## Install

``` shell
terraform init
terraform plan -out tf.plan
terraform apply ./tf.plan
```

## Check & use kubecost

``` shell
az aks get-credentials -g aks-kubecost -n aksmsftkubecost
kubectl get pods -n kubecost
kubectl port-forward -n kubecost svc/kubecost-cost-analyzer 9090:9090
```

Browse to [http://localhost:9090](http://localhost:9090)

## References:

* https://twitter.com/brendandburns/status/1387933511433154564?s=20
* http://blog.kubecost.com/blog/aks-cost/
* https://github.com/kubecost/cost-analyzer-helm-chart/blob/master/cost-analyzer/values.yaml
* https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/aks/eslz-security-governance-and-compliance#cost-governance
