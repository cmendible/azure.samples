## Disable Permissive Traffic Policy Mode

```	shell
kubectl patch meshconfig osm-mesh-config -n kube-system -p '{"spec":{"traffic":{"enablePermissiveTrafficPolicyMode":false}}}' --type=merge
```

## Check Permissive Traffic Policy Mode

```	shell
kubectl get meshconfig osm-mesh-config -n kube-system -o yaml | grep -i enablePermissiveTrafficPolicyMode
```

## Deploy the sample microservices

```	shell
kubectl apply -f nginx.yaml
kubectl apply -f busybox.yaml
```

## Test Connectivity

Run:

```	shell
kubectl exec -it busybox -c busybox -- sh
```

once inside the container, run the following command to test connectivity:

```	shell
wget -O- http://nginx
```

The result should be similar to the following:

```	shell
Connecting to nginx (10.0.149.72:80)
wget: error getting response: Resource temporarily unavailable
```

## Add traffic access control to the sample microservices

```	shell
kubectl apply -f nginx_traffic_target.yaml
```

## Recheck Connectivity

Run:

```	shell
kubectl exec -it busybox -c busybox -- sh
```

and once inside the container, run the following command to test connectivity:

```	shell
wget -O- http://nginx
```
