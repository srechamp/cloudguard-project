output "jumpbox_public_ip" {
  value = azurerm_public_ip.jumpbox.ip_address
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.jumpbox.ip_address}"
}
