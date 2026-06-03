# AKS OCI Artifact Loader

A sample project demonstrating the **OCI image-volume pattern** on AKS 1.36: package versioned project content as a scratch-based OCI image and mount it directly into pods as a read-only volume — no init containers, no `emptyDir` copies.

## Architecture

```
┌─────────────────────────────────────────────┐
│  Pod                                         │
│                                              │
│  ┌──────────────┐    /content (read-only)    │
│  │   engine     │◄──────────────────────     │
│  │  (Go HTTP)   │                    ▲       │
│  └──────────────┘                    │       │
│                         image volume │       │
└─────────────────────────────────────┼───────┘
                                       │
                         ┌─────────────┴──────────┐
                         │  ACR                    │
                         │  project-content:v1.0.0 │
                         │  (scratch-based image)  │
                         └────────────────────────┘
```

The **engine** is a long-lived Go HTTP server. The **project-content** image is a `FROM scratch` OCI image that carries only versioned files. Kubernetes 1.36 mounts that image's filesystem into the pod at `/content` before any containers start.

## Project Structure

```
.
├── engine/               # Go HTTP API server
│   ├── main.go
│   ├── go.mod
│   └── Dockerfile        # multi-stage, distroless final image
├── project-content/      # versioned content bundle (no Dockerfile needed)
│   ├── config/
│   ├── data/
│   └── rules/
├── oci/
│   ├── package-content.sh  # packages content/ as OCI image via crane (no Docker)
│   └── push-artifact.sh    # optional: push as a plain ORAS OCI artifact
├── terraform/            # AKS 1.36 + ACR
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── k8s/
│   └── deployment.yaml   # uses volumes[].image (image volumes, k8s 1.36)
└── Makefile
```

## Prerequisites

| Tool | Version |
|------|---------|
| Azure CLI (`az`) | latest |
| oras | >= 1.2 — auto-installed by `make push-content` |
| Go | >= 1.23 (local dev only) |
| Terraform | >= 1.7 |
| kubectl | >= 1.31 |
| jq | any |

> **No local Docker required.** The engine image is built in ACR Tasks (`az acr build`). The content artifact is pushed with ORAS.
| oras (optional) | >= 1.2 |

## Quick Start

### 1. Verify AKS 1.36 availability in your region

```bash
az aks get-versions --location swedencentral --query "values[].version" -o table
```

### 2. Deploy infrastructure

```bash
export ACR_NAME=myuniqueacr   # must be globally unique, 3-50 alphanumeric chars
make tf-apply
```

After apply, configure kubectl:

```bash
az aks get-credentials --resource-group rg-oci-artifact-demo --name aks-oci-demo
```

### 3. Build and push images

```bash
make push-engine      # builds engine in ACR Tasks and pushes — no local Docker needed
make push-content     # tars project-content/ and pushes as OCI artifact via ORAS
```

> Both commands require only the `az` CLI. ORAS is installed automatically if not present.

After `push-content`, the digest is printed. For production, pin the
`project-content` artifact by digest in `k8s/deployment.yaml`:

```yaml
reference: <acr>.azurecr.io/project-content@sha256:<digest>
```

### 4. Deploy to AKS

```bash
make deploy
```

### 5. Smoke test

```bash
make smoke-test
```

Expected `/tree` response:

```json
{
  "name": "content",
  "path": "/",
  "is_dir": true,
  "children": [
    { "name": "config", "path": "/config", "is_dir": true, "children": [...] },
    { "name": "data",   "path": "/data",   "is_dir": true, "children": [...] },
    { "name": "rules",  "path": "/rules",  "is_dir": true, "children": [...] }
  ]
}
```

## Engine API

| Endpoint | Description |
|----------|-------------|
| `GET /tree` | Returns a JSON tree of the mounted content directory |
| `GET /health` | Health check, returns `{"status":"ok"}` |

The content path defaults to `/content` and can be overridden with the `CONTENT_PATH` environment variable.

## How Image Volumes Work (k8s 1.36)

Kubernetes 1.36 stable image volumes (`volumes[].image`) let the kubelet pull any OCI artifact from a registry and mount its content as a read-only filesystem volume — no init container, no `emptyDir` copy.

```yaml
volumes:
  - name: project-content
    image:
      reference: <acr>.azurecr.io/project-content:v1.0.0
      pullPolicy: IfNotPresent
```

The content artifact is pushed with **ORAS**: `project-content/` is tarred into a single layer with media type `application/vnd.oci.image.layer.v1.tar+gzip`. containerd unpacks it at the `mountPath` when the pod starts.

See: <https://kubernetes.io/docs/tasks/configure-pod-container/image-volumes/>

## Teardown

```bash
make tf-destroy
```
