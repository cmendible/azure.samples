# AKS with Azure Container Storage

This Terraform configuration deploys an Azure Kubernetes Service (AKS) cluster with Azure Container Storage enabled.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.14.5
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- An active Azure subscription
- Required Azure resource providers registered (see below)

### Register Required Azure Resource Providers

Before deploying, register the required resource providers in your Azure subscription:

```bash
az provider register --namespace Microsoft.KubernetesConfiguration --wait
```

Verify registration status:

```bash
az provider show --namespace Microsoft.KubernetesConfiguration --query "registrationState"
```

Both should return `"Registered"` before proceeding.

## Deployment

1. Initialize Terraform:
   ```bash
   cd deploy
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

## Get Terraform Outputs

After deployment, retrieve the output values:

```bash
terraform output
```

Or get specific outputs:

```bash
terraform output cluster_name
terraform output resource_group_name
```

## Get AKS Cluster Credentials

Use Azure CLI to download the cluster credentials and configure kubectl:

```bash
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw cluster_name)
```

## Verify the Deployment

Once credentials are configured, verify the cluster:

```bash
kubectl get nodes
kubectl get storageclass
kubectl get pods
```

## Test Azure Container Storage

Deploy the test pod:

```bash
kubectl apply -f p.yaml
```

Or use the Terraform-managed pod:

```bash
terraform apply
```

Check the pod status:

```bash
kubectl get pod fiopod
kubectl describe pod fiopod
```

## Cleanup

Remove all resources:

```bash
terraform destroy
```
