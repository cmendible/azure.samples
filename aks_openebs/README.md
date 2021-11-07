https://help.mayadata.io/hc/en-us/articles/360033404771-Achieving-cross-zone-HA-on-AKS-with-OpenEBS

kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml

kubectl exec $(kubectl get po -l app=busy -o jsonpath='{.items[0].metadata.name}') -it -- echo "yada yada yada" >> /openebs-store/important.file