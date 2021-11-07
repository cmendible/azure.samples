## Install

``` shell
terraform init
terraform plan -out tf.plan
terraform apply ./tf.plan
```

If the deployment fails with the following message:

"OpenServiceMesh addon is not allowed since feature 'Microsoft.ContainerService/AKS-OpenServiceMesh' is not enabled. Please see https://aka.ms/aks/previews for how to enable features."

Make sure you register the `AKS-OpenServiceMesh` feature for your subscription.

``` shell
az feature register --namespace "Microsoft.ContainerService" --name "AKS-OpenServiceMesh"
```

Check if the feature is registered:

``` shell
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-OpenServiceMesh')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
```

Once registered refresh the  `Microsoft.ContainerService`

``` shell
az provider register --namespace Microsoft.ContainerService
```

And once again check the status:

``` shell
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService')].{Name:name,State:properties.state}"
```

## Check OSM status and version:

Get the cluster credentials:

``` shell
az aks get-credentials -g aks-osm -n aks-osm
```

Check the status of all OSM components:

``` shell
kubectl get deploy,po,svc -n kube-system --selector app=osm-controller
```

Check the OSM version:

``` shell
kubectl get deployment -n kube-system osm-controller -o yaml | grep -i image:
```

## Check OSM configuration:

``` shell
kubectl get meshconfig osm-mesh-config -n kube-system -o yaml
```

Note the setting: `enablePermissiveTrafficPolicyMode: true`

## Configure OSM to monitor a namespace

``` shell
kubectl label ns default openservicemesh.io/monitored-by=osm
```

This makes OSM check for any changes in the default namespaces but does not enables sidecar injection.

If you also want to enable automatic side-car injection run:

``` shell
kubectl annotate namespace default openservicemesh.io/sidecar-injection=enabled
```

## Configure OSM to enable metrics for a namespace

``` shell
kubectl annotate ns default "openservicemesh.io/metrics=enabled"
```

also in order for Azure Monitor to read the metrics run: 

``` shell
kubectl apply -f ./metrics.configmap.yaml
```

## Test OSM

Run an `nginx` server with the `openservicemesh.io/sidecar-injection=enabled` so OSM injects the `envoy` sidecar

``` shell
k run nginx --image nginx --annotations="openservicemesh.io/sidecar-injection=enabled"
k expose po nginx --port 80 --target-port 80
```

Now also run a `buybox` pod with the `openservicemesh.io/sidecar-injection=enabled`

``` shell
kubectl run -it --rm busybox --image busybox --annotations="openservicemesh.io/sidecar-injection=enabled" -- sh
```

In the prompt run:

``` shell
wget -O- http://nginx
```

> The call was secured via mTLS

## Azure Monitor metrics

``` shell
InsightsMetrics
| where Name contains "envoy"
| extend t=parse_json(Tags)
```

## References:

* [Open Service Mesh AKS add-on](https://docs.microsoft.com/en-us/azure/aks/open-service-mesh-about)
* [Open Service Mesh](https://openservicemesh.io/)
