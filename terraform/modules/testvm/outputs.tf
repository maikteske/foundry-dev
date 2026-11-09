output "test_vm_public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "test_vm_private_ip" {
  value = azurerm_network_interface.this.private_ip_address
}
