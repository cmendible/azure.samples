## Install

``` powershell
terraform init
terraform apply --auto-approve
```

## Schedule Task

``` powershell
./scheduleTask.ps1
```

## References:

* [When do I use the Batch service API to persist task output?](https://docs.microsoft.com/en-us/azure/batch/batch-task-output-files#when-do-i-use-the-batch-service-api-to-persist-task-output?


``` powershell
az batch pool supported-images list --account-endpoint $(terraform output -raw batch_url) --account-name $(terraform output -raw batch_accountName)  --query "[?imageReference.publisher == 'oracle']"
```