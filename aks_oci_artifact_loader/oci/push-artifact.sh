#!/usr/bin/env bash
# push-artifact.sh — packages project-content/ as a valid OCI image and pushes
# it to ACR so Kubernetes 1.36 image volumes can mount it directly.
#
# The critical requirement: containerd validates that rootfs.diff_ids in the
# image config match the SHA256 of each layer's UNCOMPRESSED content.
# A bare `oras push` with a tar.gz produces an OCI artifact manifest (no config
# with diff_ids), which causes:
#   "failed to unpack image volume: mismatched image rootfs and manifest layers"
#
# This script:
#   1. Creates an uncompressed tar of the content directory
#   2. Computes diff_id = SHA256 of the UNCOMPRESSED tar
#   3. Compresses the tar (gzip) for the actual layer blob
#   4. Writes a valid OCI image config JSON with rootfs.diff_ids
#   5. Pushes with: oras push --config config.json:application/vnd.oci.image.config.v1+json
#
# Does NOT require Docker.
#
# Prerequisites:
#   - oras CLI >= 1.2: https://oras.land/docs/installation (auto-installed by Makefile)
#   - az CLI logged in (az login)
#
# Usage:
#   export ACR_NAME=myacr
#   export PROJECT_TAG=project-content:v1.0.0   # optional
#   ./oci/push-artifact.sh

set -euo pipefail

: "${ACR_NAME:?ACR_NAME environment variable is required}"
: "${PROJECT_TAG:=project-content:v1.0.0}"

REGISTRY="${ACR_NAME}.azurecr.io"
CONTENT_DIR="$(cd "$(dirname "$0")/../project-content" && pwd)"

TMP="$(mktemp -d)"
LAYER_TAR_UNCOMPRESSED="${TMP}/layer.tar"
LAYER_TAR_GZ="${TMP}/layer.tar.gz"
CONFIG_JSON="${TMP}/config.json"

cleanup() { rm -rf "${TMP}"; }
trap cleanup EXIT

echo "Authenticating to ${REGISTRY} (no Docker required)..."
TOKEN=$(az acr login --name "${ACR_NAME}" --expose-token \
  --output tsv --query accessToken)
oras login "${REGISTRY}" \
  --username "00000000-0000-0000-0000-000000000000" \
  --password "${TOKEN}"

echo "Creating layer tar from ${CONTENT_DIR}..."
# Step 1: uncompressed tar — needed to compute the diff_id
tar -cf "${LAYER_TAR_UNCOMPRESSED}" -C "${CONTENT_DIR}" .

# Step 2: diff_id = SHA256 of the UNCOMPRESSED layer content
# containerd verifies this against the uncompressed layer when mounting
DIFF_ID="sha256:$(sha256sum "${LAYER_TAR_UNCOMPRESSED}" | cut -d' ' -f1)"
echo "  diff_id: ${DIFF_ID}"

# Step 3: compress for storage/transfer efficiency
gzip -9 -c "${LAYER_TAR_UNCOMPRESSED}" > "${LAYER_TAR_GZ}"

# Step 4: write a valid OCI image config with rootfs.diff_ids
cat > "${CONFIG_JSON}" <<EOF
{
  "architecture": "amd64",
  "os": "linux",
  "rootfs": {
    "type": "layers",
    "diff_ids": ["${DIFF_ID}"]
  }
}
EOF

echo "Pushing OCI image to ${REGISTRY}/${PROJECT_TAG}..."
oras push "${REGISTRY}/${PROJECT_TAG}" \
  --disable-path-validation \
  --config "${CONFIG_JSON}:application/vnd.oci.image.config.v1+json" \
  "${LAYER_TAR_GZ}:application/vnd.oci.image.layer.v1.tar+gzip"

echo ""
echo "Image pushed. Digest:"
oras resolve "${REGISTRY}/${PROJECT_TAG}"
echo ""
echo "Pin by digest for production:"
echo "  ${REGISTRY}/project-content@\$(oras resolve ${REGISTRY}/${PROJECT_TAG})"
