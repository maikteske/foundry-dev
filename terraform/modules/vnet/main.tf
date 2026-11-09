# VNet für das API-Gateway-Plattform-Skelett (vgl. infra/modules/vnet.bicep).
# Subnets: snet-appgw (App Gateway v2, min /26),
#          snet-apim-out (APIM Standard v2 outbound Integration, min /27,
#                         Delegation Microsoft.Web/serverFarms — NICHT ApiManagement!),
#          snet-privatelink (Private Endpoint + optionaler Test-VM).
#
# Import-Relevanz:
#   - alle 3 Subnets live privateEndpointNetworkPolicies = "Disabled"
#     (azurerm-Default wäre "Enabled" → ohne Attribut gäbe es einen Update-Diff!)
#   - Delegation live mit action "Microsoft.Network/virtualNetworks/subnets/action",
#     die APIM-Integration hat sie nach dem Bicep-Deploy ergänzt → im Config setzen.

resource "azurerm_network_security_group" "apim_out" {
  name                = "${var.vnet_name}-snet-apim-out-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Pflicht laut MS-Doku für VNet-Integration; explizite Outbound-Erlaubnis
  # für Azure Key Vault (APIM-Abhängigkeit).
  security_rule {
    name                       = "Allow-AzureKeyVault-Out"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureKeyVault"
  }
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_prefix]

  # Subnets bewusst NICHT inline (separate azurerm_subnet-Ressourcen → sauber importierbar)
}

resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.appgw_subnet_prefix]

  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "apim_out" {
  name                 = "snet-apim-out"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.apim_out_subnet_prefix]

  private_endpoint_network_policies = "Disabled"

  delegation {
    name = "Microsoft.Web/serverFarms"

    service_delegation {
      # Live-Stand: APIM-Integration ergänzt diese Action nach dem Deploy.
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]

      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet" "privatelink" {
  name                 = "snet-privatelink"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.privatelink_subnet_prefix]

  private_endpoint_network_policies = "Disabled"
}

# NSG-Anbindung an snet-apim-out (azurerm modelliert das als eigene Ressource,
# nicht als subnet-Attribut — identisch zum Live-Stand).
resource "azurerm_subnet_network_security_group_association" "apim_out" {
  subnet_id                 = azurerm_subnet.apim_out.id
  network_security_group_id = azurerm_network_security_group.apim_out.id
}
