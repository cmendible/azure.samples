output "jumpbox_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "sa_name" {
  value = var.sa_name
}
