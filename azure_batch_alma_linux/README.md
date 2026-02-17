# Azure Batch with AlmaLinux and Docker

This sample deploys an Azure Batch pool running **AlmaLinux 9** with **Docker CE** using Terraform.

## Architecture

The deployment creates:

- **Resource Group** - Container for all resources
- **Virtual Network & Subnet** - Network isolation for Batch nodes
- **Storage Account** - Hosts the start task script
- **Batch Account** - Manages the Batch pool and jobs
- **Batch Pool** - AlmaLinux 9 nodes with Docker CE installed via start task
- **Test Job** - Runs a `hello-world` Docker container to verify the setup

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) authenticated (`az login`)
- An Azure subscription

## Usage

1. **Initialize Terraform**

   ```bash
   cd deploy
   terraform init
   ```

2. **Review the plan**

   ```bash
   terraform plan
   ```

3. **Deploy**

   ```bash
   terraform apply
   ```

4. **Verify** - Check the test task output in the Azure Portal or via CLI:

   ```bash
   az batch task show \
     --job-id test-docker-job \
     --task-id test-docker-task \
     --account-name <batch_account_name> \
     --account-endpoint <batch_account_name>.<location>.batch.azure.com
   ```

## How It Works

1. The Batch pool uses AlmaLinux 9 (`almalinux:almalinux-x86_64:9-gen2`) with the `batch.node.el 9` node agent
2. A **start task** runs on each node to install Docker CE from the official Docker repository
3. The test job runs `docker run --rm hello-world` to verify Docker is working

## Why Native Container Tasks Don't Work (ContainerPoolNotSupported)

Azure Batch has two ways to run containers:

1. **Native container tasks** - Using `containerSettings` in the task JSON
2. **Command-line Docker** - Running `docker run` directly in the task command

**AlmaLinux does not support native container tasks.** If you try to use `containerSettings`, you'll get:

```
ContainerPoolNotSupported: The specified pool does not support container tasks.
```

This happens because Azure Batch's native container support only works with specific VM images that have Batch-integrated container runtimes (typically `microsoft-azure-batch` publisher images or certain Ubuntu images). The `batch.node.el 9` node agent does not include this integration.

### The Workaround

This sample uses **command-line Docker** instead. Tasks invoke `docker run` directly:

```json
{
  "id": "my-task",
  "commandLine": "/bin/bash -c \"docker run --rm my-image\"",
  "userIdentity": {
    "autoUser": {
      "elevationLevel": "admin",
      "scope": "pool"
    }
  }
}
```

This approach provides full Docker functionality on AlmaLinux - you just can't use Batch's `containerSettings` syntax.

## Clean Up

```bash
terraform destroy
```
