output "pe_id" {
  value = azurerm_private_endpoint.this.id
}

output "pe_ip" {
  value = azurerm_private_endpoint.this.custom_dns_configs[0].ip_addresses[0]
}

output "registered_fqdn" {
  value = "${var.apim_name}.${azurerm_private_dns_zone.this.name}"
}

output "dns_zone_id" {
  value = azurerm_private_dns_zone.this.id
}
