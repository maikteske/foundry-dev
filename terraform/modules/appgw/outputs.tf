output "public_ip_fqdn" {
  value = azurerm_public_ip.this.fqdn
}

output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "appgw_id" {
  value = azurerm_application_gateway.this.id
}
