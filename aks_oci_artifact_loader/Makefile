# AKS OCI Artifact Loader — Makefile
#
# No local Docker required — engine is built in ACR Tasks (az acr build),
# content is pushed with ORAS.
#
# Usage:
#   export ACR_NAME=<your-acr-name>
#   make push-engine      # build + push via ACR Tasks (no Docker)
#   make push-content     # package + push OCI artifact via ORAS (no Docker)
#   make tf-apply
#   make deploy
#   make smoke-test

ACR_NAME        ?= $(error ACR_NAME is required — export ACR_NAME=<your-acr-name>)
IMAGE_REGISTRY  := $(ACR_NAME).azurecr.io
ENGINE_IMAGE    := engine:latest
K8S_MANIFEST    := k8s/deployment.yaml

ORAS_VERSION    := 1.3.2
ORAS_INSTALL    := /usr/local/bin/oras

.PHONY: all push-engine push-content push-all \
        tf-init tf-apply tf-destroy deploy smoke-test install-oras

all: push-engine push-content deploy smoke-test

## ── Tools ─────────────────────────────────────────────────────────────────────

install-oras:
	@if command -v oras > /dev/null 2>&1; then \
		echo "oras $(shell oras version 2>/dev/null | head -1) already installed"; \
	else \
		echo "Installing oras v$(ORAS_VERSION)..."; \
		OS=$$(uname -s | tr A-Z a-z); \
		ARCH=$$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/'); \
		TMP=$$(mktemp -d); \
		curl -sSL "https://github.com/oras-project/oras/releases/download/v$(ORAS_VERSION)/oras_$(ORAS_VERSION)_$${OS}_$${ARCH}.tar.gz" \
			| tar -xz -C "$$TMP"; \
		sudo mv "$$TMP/oras" $(ORAS_INSTALL); \
		rm -rf "$$TMP"; \
		echo "oras installed at $(ORAS_INSTALL)"; \
	fi

## ── Build / Push ──────────────────────────────────────────────────────────────

# Build and push the engine image using ACR Tasks — no local Docker needed.
push-engine:
	az acr build --registry $(ACR_NAME) --image $(ENGINE_IMAGE) ./engine

# Package project-content/ as an OCI artifact and push to ACR using ORAS.
# The layer media type application/vnd.oci.image.layer.v1.tar+gzip lets
# containerd unpack and mount it via volumes[].image (k8s 1.36).
push-content: install-oras
	ACR_NAME=$(ACR_NAME) ./oci/push-artifact.sh

push-all: push-engine push-content

# Show the OCI manifest (should have config with diff_ids) and list files.
inspect-content: install-oras
	@REGISTRY=$(IMAGE_REGISTRY); TAG=project-content:v1.0.0; \
	TOKEN=$$(az acr login --name $(ACR_NAME) --expose-token \
		--output tsv --query accessToken); \
	oras login "$$REGISTRY" \
		--username "00000000-0000-0000-0000-000000000000" \
		--password "$$TOKEN"; \
	echo "\n=== OCI Manifest (should have mediaType: application/vnd.oci.image.config.v1+json) ==="; \
	oras manifest fetch "$$REGISTRY/$$TAG" | jq .; \
	echo "\n=== Image Config (should have rootfs.diff_ids) ==="; \
	oras manifest fetch "$$REGISTRY/$$TAG" --descriptor | jq .

## ── Terraform ─────────────────────────────────────────────────────────────────

tf-init:
	cd terraform && terraform init

tf-apply: tf-init
	cd terraform && terraform apply -var "acr_name=$(ACR_NAME)"

tf-destroy:
	cd terraform && terraform destroy -var "acr_name=$(ACR_NAME)"

## ── Kubernetes ────────────────────────────────────────────────────────────────

# Substitute the ACR login server into the manifest and apply it.
deploy:
	sed 's|<ACR_LOGIN_SERVER>|$(IMAGE_REGISTRY)|g' $(K8S_MANIFEST) | kubectl apply -f -
	kubectl rollout status deployment/demo-engine

# Quick smoke test: port-forward and call /tree, then /health.
smoke-test:
	@echo "Port-forwarding to demo-engine..."
	kubectl port-forward svc/demo-engine 8080:80 &
	@sleep 2
	@echo "\n=== GET /health ==="
	curl -sf http://localhost:8080/health | jq .
	@echo "\n=== GET /tree ==="
	curl -sf http://localhost:8080/tree | jq .
	@pkill -f "port-forward svc/demo-engine" || true
