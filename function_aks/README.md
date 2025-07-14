## WARNING

> Running your containerized function apps on Kubernetes, either by using KEDA or by direct deployment, is an open-source effort that you can use free of cost. Best-effort support is provided by contributors and from the community by using GitHub issues in the Azure Functions repository. Please use these issues to report bugs and raise feature requests.

## HTTP Trigger support

You can use Azure Functions that expose HTTP triggers, but KEDA doesn't directly manage them. You can use the KEDA prometheus trigger to scale HTTP Azure Functions from one to n instances.

### Steps to deploy an HTTP Trigger Azure Function on AKS with KEDA

Install ingress-nginx and prometheus using Helm:

```bash
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
```

Check the status of nginx ingress controller metrics:

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
```

Login to the Azure Container Registry and deploy the Azure Function:

```bash
az acr login -n craksfunc

func init --worker-runtime dotnet-isolated
func new --template "HttpTrigger" --name HelloAKS
func init --docker-only
func kubernetes deploy --name function-helloworld --namespace ingress-nginx --service-type ClusterIP --registry craksfunc.azurecr.io
```

Check the status of the Azure Function deployment:

```bash
curl -k -i "http://<ingres external ip>/api/helloaks?code=<your function code>"
```

Create the Ingress and ScaleObject for the Azure Function:

```bash
kubeclt apply -f ./k8s
```

## Other Supported triggers in KEDA

KEDA has support for the following Azure Function triggers:

* Azure Storage Queues
* Azure Service Bus
* Azure Event / IoT Hubs
* Apache Kafka
* RabbitMQ Queue

## References

* [Azure Functions on Kubernetes with KEDA](https://learn.microsoft.com/en-us/azure/azure-functions/functions-kubernetes-keda)
