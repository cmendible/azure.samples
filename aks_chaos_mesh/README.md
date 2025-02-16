az aks get-credentials --resource-group rg-chaos-mesh-demo --name aks-chaos-mesh --overwrite-existing

kubectl apply -f ./kubernetes/ingress.yaml
kubectl apply -f ./kubernetes/rbac.yaml
kubectl create token account-cluster-manager

IP_ADDRESS=$(kubectl get service -n app-routing-system nginx -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo "http://$IP_ADDRESS/chaos-mesh"
