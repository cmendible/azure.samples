#!/bin/bash
set -euo pipefail

# Azure Batch start task for AlmaLinux 9: install Docker CE
# This fixes "docker not found" issues on custom AlmaLinux images

echo ">>> Installing Docker CE on AlmaLinux 9..."

# Install required dependencies
dnf install -y dnf-utils device-mapper-persistent-data lvm2

# Add Docker's official repository
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

# Install Docker CE
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Verify the installation
docker info

echo ">>> Docker CE installed and running."
