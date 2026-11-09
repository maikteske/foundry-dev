output "apim_id" {
  value = azurerm_api_management.this.id
}

output "apim_name" {
  value = azurerm_api_management.this.name
}

output "apim_principal_id" {
  value = azurerm_api_management.this.identity[0].principal_id
}

output "apim_gateway_url" {
  value = azurerm_api_management.this.gateway_url
}
