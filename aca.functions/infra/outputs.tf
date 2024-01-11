output "resource_group_name" {
    value = "${azurerm_resource_group.rg.name}"
    description = "The name of the resource group"
}

output "subscription_id" {
    value = "${data.azurerm_subscription.current.subscription_id}"
    description = "The subscription ID used"
}

output "tenant_id" {
    value = "${data.azurerm_subscription.current.tenant_id}"
    description = "The tenant ID used"
}

output "storage_account_name" {
    value = "${module.st.storage_account_name}"
    description = "The name of the storage account"
}

output "storage_container_name" {
    value = "${module.st.storage_container_name}"
    description = "The name of the storage account"
}
