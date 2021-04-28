#!/bin/bash

set -e

echo "Getting AKS credentials..."
az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

echo "Installing azure-file-csi driver"
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/v1.1.0/deploy/install-driver.sh | bash -s v1.1.0 --

echo "azure-file-csi driver has been installed."