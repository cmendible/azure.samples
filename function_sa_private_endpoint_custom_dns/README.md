# Scenario: linux Azure Function Premium with Custom DNS

We deploy the solution in 2 steps cause of an issue with the Terraform Provider.

> Check [function_app_resource can't deploy a function app with a backing storage account protected via private endpoint](https://github.com/hashicorp/terraform-provider-azurerm/issues/10990)

## Deploy the solution without the firewall enabled

``` shell
cd ./deploy
terraform init
terraform apply --auto-approve --var="enable_firewall=false"
```

## Enable the firewall

``` shell
terraform init
terraform apply --auto-approve
``` 

## Test the Azure Function

Use the Azure Portal to access the `privatesta****` storage account in the `func-custom-dns-****` resource group and copy any file in the `input` container.

Check the `output` container where you should find a copy of the file.