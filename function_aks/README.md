helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.service.type=LoadBalancer \
    --set controller.service.externalTrafficPolicy=Local \
    --set controller.metrics.enabled=true \
    --set controller.metrics.serviceMonitor.enabled=true \
    --set controller.metrics.serviceMonitor.additionalLabels.release="prometheus"

kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090

az acr login -n craksfunc

func init --worker-runtime dotnet-isolated
func new --template "HttpTrigger" --name HelloAKS
func init --docker-only
func kubernetes deploy --name function-helloworld --namespace ingress-nginx --service-type ClusterIP --registry craksfunc.azurecr.io

curl -k -i "http://158.158.88.152/api/helloaks?code=<you code>"