# AKS NAP — ZRS Disk PV Zone Fix Admission Webhook

A Kubernetes **mutating admission webhook** that fixes a scheduling failure
specific to AKS Node Auto Provisioning (NAP/Karpenter) when using Azure Disk
ZRS (Zone-Redundant Storage) Persistent Volumes.

## The Problem

When a ZRS Azure Disk PV is provisioned with `volumeBindingMode: Immediate`,
the Azure Disk CSI driver writes the PV `nodeAffinity` as **one
`NodeSelectorTerm` per availability zone** (OR semantics across terms):

```yaml
nodeAffinity:
  required:
    nodeSelectorTerms:
    - matchExpressions:
      - key: topology.disk.csi.azure.com/zone
        operator: In
        values: [eastus2-1]    # term 0 – only zone 1
    - matchExpressions:
      - key: topology.disk.csi.azure.com/zone
        operator: In
        values: [eastus2-2]    # term 1 – only zone 2
    - matchExpressions:
      - key: topology.disk.csi.azure.com/zone
        operator: In
        values: [eastus2-3]    # term 2 – only zone 3
```

Karpenter/NAP only evaluates the **first** `NodeSelectorTerm` when computing
where to provision a new node. If a pod's `nodeSelector` requires a different
zone (e.g. zone 2), Karpenter provisions a node in zone 1, the scheduler sees
an affinity mismatch, and the pod stays `Pending` indefinitely.

This is the root cause tracked in
[kubernetes-sigs/karpenter#2743](https://github.com/kubernetes-sigs/karpenter/pull/2743)
and reproduced by the
[karpenter-provider-azure storage e2e test suite](https://github.com/Azure/karpenter-provider-azure/blob/6b393df8311e497993b55afde9d08570cd0e2798/test/suites/storage/suite_test.go).

## The Fix

The webhook intercepts PV `CREATE` and `UPDATE` events, detects ZRS disks
(via `skuName` containing `ZRS` in the CSI volume attributes), and **merges**
all zone values from separate `NodeSelectorTerms` into a single term:

```yaml
nodeAffinity:
  required:
    nodeSelectorTerms:
    - matchExpressions:
      - key: topology.disk.csi.azure.com/zone
        operator: In
        values: [eastus2-1, eastus2-2, eastus2-3]   # merged – any zone OK
```

Karpenter now sees a single term with all zones and correctly honours the
pod's zone preference when provisioning a node.

## Repository Structure

```
.
├── cmd/webhook/main.go          # Entry point — TLS server on :8443
├── internal/handler/handler.go  # Mutation logic
├── deploy/
│   ├── webhook.yaml             # All-in-one deploy (namespace → MutatingWebhookConfiguration)
│   └── test-storage-suite.yaml  # Full test suite mirroring karpenter-provider-azure e2e tests
├── terraform/                   # AKS NAP cluster + ACR + cert-manager
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf
├── Dockerfile                   # Multi-stage build → distroless/static:nonroot
└── Makefile
```

## Prerequisites

| Tool | Purpose |
|------|---------|
| Go 1.23+ | Build the webhook binary |
| Azure CLI (`az`) | ACR build, AKS credentials |
| Terraform ≥ 1.5 | Provision AKS + ACR |
| kubectl | Deploy and inspect resources |
| cert-manager v1.15+ | TLS certificate management (deployed by Terraform) |

## Quick Start

### 1 — Provision the cluster (optional — skip if you have an AKS NAP cluster)

```bash
cd terraform
terraform init
terraform apply          # ~10 min; provisions AKS NAP + ACR + cert-manager
```

Default values in `variables.tf`:

| Variable | Default |
|----------|---------|
| `resource_group_name` | `rg-aks-nap-webhook` |
| `location` | `eastus2` |
| `cluster_name` | `aks-nap-webhook` |
| `kubernetes_version` | `1.33` |
| `acr_name` | `acrnapwebhook` |

After apply, get credentials:
```bash
$(terraform output -raw get_credentials_command)
```

### 2 — Build and push the webhook image

```bash
# Build inside ACR (no local Docker daemon needed)
make acr-build ACR_NAME=<your-acr-name>
```

### 3 — Deploy the webhook

Update the image reference in `deploy/webhook.yaml` (search for `acrnapwebhook.azurecr.io`), then:

```bash
kubectl apply -f deploy/webhook.yaml
```

This creates in namespace `pv-zone-fix-webhook`:
- `Namespace` / `ServiceAccount` / `ClusterRole` / `ClusterRoleBinding`
- `Deployment` (2 replicas, distroless, read-only root FS)
- `Service` (port 443 → 8443)
- cert-manager `ClusterIssuer` → CA `Certificate` → `Issuer` → TLS `Certificate`
- `MutatingWebhookConfiguration` (CA bundle injected automatically by cert-manager)

Verify the pods are ready:
```bash
kubectl get pods -n pv-zone-fix-webhook
```

### 4 — Watch webhook logs

```bash
kubectl logs -n pv-zone-fix-webhook \
  -l app.kubernetes.io/name=pv-zone-fix-webhook -f
```

Expected output when the webhook merges a PV:
```
[request] Incoming admission review
[pv] Name=pvc-xxxxxxxx-...
[pv] CSI driver=disk.csi.azure.com skuName=Premium_ZRS
[zrs] ZRS disk detected → evaluating node affinity topology
[zone] Found zone=eastus2-1
[zone] Found zone=eastus2-2
[zone] Found zone=eastus2-3
[patch] Merged 3 zones into single NodeSelectorTerm
[response] Completed in 450µs
```

## Testing

Mirrors the [karpenter-provider-azure e2e storage tests](https://github.com/Azure/karpenter-provider-azure/blob/6b393df8311e497993b55afde9d08570cd0e2798/test/suites/storage/suite_test.go).

Apply and monitor:

```bash
kubectl apply -f deploy/test-storage-suite.yaml

# Watch all test pods
kubectl get pods -A -l suite=storage-test -w
```

#### Scenarios

| Namespace | Scenario | What it validates |
|-----------|----------|-------------------|
| `st-dynamic-lrs` | Dynamic LRS, `WaitForFirstConsumer` | Basic NAP node + Azure Disk provisioning |
| `st-allowed-topo` | Dynamic LRS + `allowedTopologies` | NAP respects zone constraint from StorageClass |
| `st-zrs-zone-pin` | **ZRS Immediate + pod pinned to ZONE-2** | **Webhook fix** — without it the pod stays Pending |
| `st-statefulset` | StatefulSet, `WaitForFirstConsumer` | Fast volume reattach after disruption (< 2 min) |
| `st-emptydir` | emptyDir + memory-backed emptyDir | NAP provisions nodes for ephemeral storage requests |

#### Scenario 3 — The Webhook Test (key scenario)

```bash
# After applying, wait for PVC to bind (Immediate binding)
kubectl get pvc -n st-zrs-zone-pin st-pvc-zrs -w

# Inspect the PV nodeAffinity — should be ONE term with all zones merged:
kubectl get pv \
  $(kubectl get pvc -n st-zrs-zone-pin st-pvc-zrs -o jsonpath='{.spec.volumeName}') \
  -o jsonpath='{.spec.nodeAffinity}' | jq .

# Pod is pinned to ZONE-2; verify it lands there:
kubectl get pod -n st-zrs-zone-pin st-pod-zrs-pin -o wide
```

Without the webhook: pod stays `Pending` with
`incompatible volume requirements ... topology.disk.csi.azure.com/zone In [eastus2-1] not in ... In [eastus2-2]`.

With the webhook: pod reaches `Running` in ZONE-2.

#### Scenario 4 — Fast reattach (StatefulSet)

```bash
# Simulate node disruption by deleting the pod
kubectl delete pod -n st-statefulset st-0

# Measure time to Running — should be < 2 minutes
kubectl get pod -n st-statefulset st-0 -w
```

### Clean up all test resources

```bash
kubectl delete -f deploy/test-storage-suite.yaml
kubectl delete -f deploy/test-zrs-pv.yaml 2>/dev/null || true
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DRY_RUN` | `false` | Set to `true` to log mutations without applying patches |

## How It Works

```
PV CREATE/UPDATE
      │
      ▼
MutatingWebhookConfiguration
      │  (rules: persistentvolumes, scope: Cluster)
      ▼
webhook /mutate
      │
      ├─ CSI driver = disk.csi.azure.com?  No  → allow (no-op)
      ├─ skuName contains "ZRS"?           No  → allow (no-op)
      ├─ nodeAffinity has > 1 term         No  → allow (no-op)
      │  with key topology.disk.csi.azure.com/zone?
      │
      └─ Yes → collect all zone values from all terms
               filter empty values
               emit JSON patch:
                 /spec/nodeAffinity/required/nodeSelectorTerms →
                   [ { matchExpressions: [ { key, operator: In,
                       values: [zone1, zone2, zone3] } ] } ]
```

## Makefile Targets

```bash
make build          # compile binary → bin/webhook
make vet            # go vet ./...
make acr-build      # build image in ACR (no local Docker needed)
make clean          # remove bin/
```
