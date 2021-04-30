## References:

* https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/aks/eslz-security-governance-and-compliance#cost-governance
* http://docs.kubecost.com/azure-config
* http://blog.kubecost.com/blog/aks-cost/
* https://twitter.com/brendandburns/status/1387933511433154564?s=20
* https://github.com/kubecost/cost-analyzer-helm-chart/blob/master/cost-analyzer/values.yaml

## Check & use kubecost

k get pods -n kubecost
k port-forward -n kubecost svc/kubecost-cost-analyzer 9090:9090
