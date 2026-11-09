# Private Endpoint (sub-resource 'Gateway') auf die APIM-Instanz
# + Private DNS Zone privatelink.azure-api.net mit A-Record und VNet-Link
# (vgl. infra/modules/apim-privateendpoint.bicep).
# Der Public-Hostname <apim>.azure-api.net wird per CNAME auf
# <apim>.privatelink.azure-api.net geführt → Clients im VNet (Zone gelinkt)
# resolven die PE-IP, alle anderen den öffentlichen Endpunkt (bzw. nach
# Lockdown: niemand).
#
# Import-Matching (live verifiziert 2026-11-09):
#   - live KEIN customNetworkInterfaceName und KEINE statischen
#     ipConfigurations (dynamische IP 10.70.0.132) → beide Blöcke weglassen,
#     sonst ForceNew/Replace-Gefahr beim azurerm_private_endpoint.

locals {
  pe_name        = "pe-${var.apim_name}-gateway"
  dns_zone_name  = "privatelink.azure-api.net"
  a_record_name  = var.apim_name # registrierter FQDN ist deterministisch: <apim>.privatelink.azure-api.net
  vnet_link_name = "${var.apim_name}-vnet-link"
}

resource "azurerm_private_endpoint" "this" {
  name                = local.pe_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.apim_name}-gateway-connection"
    is_manual_connection           = false
    private_connection_resource_id = var.apim_id
    subresource_names              = ["Gateway"]
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = local.dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_a_record" "apim" {
  name                = local.a_record_name
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = azurerm_private_endpoint.this.custom_dns_configs[*].ip_addresses[0]
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = local.vnet_link_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}
