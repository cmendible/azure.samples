## azurerm_function_app is affected by terrafrom provider issues: 

* https://github.com/hashicorp/terraform-provider-azurerm/issues/10990
* https://github.com/hashicorp/terraform-provider-azurerm/issues/14167


## Using Beta resources to enable azurerm_windows_function_app:

```	shell
$env:ARM_THREEPOINTZERO_BETA_RESOURCES = "true"
terraform apply -auto-approve
```

> Must run twice so WEBSITE_CONTENTSHARE is properly updated.