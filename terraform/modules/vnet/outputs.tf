output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "apim_out_subnet_id" {
  value = azurerm_subnet.apim_out.id
}

output "privatelink_subnet_id" {
  value = azurerm_subnet.privatelink.id
}
