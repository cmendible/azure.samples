# Set ACR_NAME to your registry name (without .azurecr.io), e.g.:
#   make acr-build ACR_NAME=acrnapwebhook
ACR_NAME   ?= acrnapwebhook
IMAGE_REPO ?= $(ACR_NAME).azurecr.io/pv-zone-fix-webhook
IMAGE_TAG  ?= latest

BINARY     := bin/webhook
CHART_DIR  := charts/pv-zone-fix-webhook
TF_DIR     := terraform

.PHONY: all build tidy vet docker-build docker-push acr-build \
        helm-lint helm-template helm-install \
        tf-init tf-plan tf-apply clean

all: tidy vet build

## ── Go ──────────────────────────────────────────────────────────────────────

tidy:
	go mod tidy

vet: tidy
	go vet ./...

build: tidy
	@mkdir -p bin
	CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o $(BINARY) ./cmd/webhook

## ── Docker ──────────────────────────────────────────────────────────────────

docker-build:
	docker build -t $(IMAGE_REPO):$(IMAGE_TAG) .

docker-push: docker-build
	docker push $(IMAGE_REPO):$(IMAGE_TAG)

# Build and push the image directly in ACR (no local Docker daemon required).
# Requires: az login and the caller to have AcrPush on the registry.
acr-build:
	az acr build \
		--registry $(ACR_NAME) \
		--image pv-zone-fix-webhook:$(IMAGE_TAG) \
		--file Dockerfile \
		.

clean:
	rm -rf bin/
