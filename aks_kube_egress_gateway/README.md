## kube-egress-gateway

Using [kube-egress-gateway](https://github.com/Azure/kube-egress-gateway/tree/main)

Changes to the original Helm chart:

- Added the label `azure.workload.identity/use: "true"` to the pod template in `gateway-controller-manager.yaml`
- Added the annotation `azure.workload.identity/inject-proxy-sidecar: "true"` to the pod template in `gateway-controller-manager.yaml`

> Note: The Helm chart was copied from the original repository (commit https://github.com/Azure/kube-egress-gateway/commit/2b21bb4b62996809df5730919486fd82d3125b5d) and modified to include the changes above.

### Deploy

```bash
cd infra
terraform init
terraform apply
```
