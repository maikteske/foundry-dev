# Alle importierten Ressourcen mit den LIVE-verifizierten ARM-IDs
# (geprüft am 2026-11-09, Subscription 5cef6e78-e33e-4ceb-855e-5d85f4debdd4).
# Adressen folgen dem Modul-Design: appgw-Modul hat count (Index [0]),
# foundry_models hat for_each (Key = Deployment-Name).

import {
  to = azurerm_resource_group.platform
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform"
}

# ── vnet ─────────────────────────────────────────────────────────────────────
import {
  to = module.vnet.azurerm_network_security_group.apim_out
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/networkSecurityGroups/tbi-vnet-exam-ai-103-platform-snet-apim-out-nsg"
}
import {
  to = module.vnet.azurerm_virtual_network.this
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/virtualNetworks/tbi-vnet-exam-ai-103-platform"
}
import {
  to = module.vnet.azurerm_subnet.appgw
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/virtualNetworks/tbi-vnet-exam-ai-103-platform/subnets/snet-appgw"
}
import {
  to = module.vnet.azurerm_subnet.apim_out
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/virtualNetworks/tbi-vnet-exam-ai-103-platform/subnets/snet-apim-out"
}
import {
  to = module.vnet.azurerm_subnet.privatelink
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/virtualNetworks/tbi-vnet-exam-ai-103-platform/subnets/snet-privatelink"
}
import {
  # Assoziation NSG <-> snet-apim-out (Import-ID = Subnet-ID allein, KEIN "|"-Format)
  to = module.vnet.azurerm_subnet_network_security_group_association.apim_out
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/virtualNetworks/tbi-vnet-exam-ai-103-platform/subnets/snet-apim-out"
}

# ── apim ─────────────────────────────────────────────────────────────────────
import {
  to = module.apim.azurerm_api_management.this
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.ApiManagement/service/tbi-apim-exam-ai-103"
}

# ── apim_private_endpoint ────────────────────────────────────────────────────
import {
  to = module.apim_private_endpoint.azurerm_private_endpoint.this
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/privateEndpoints/pe-tbi-apim-exam-ai-103-gateway"
}
import {
  to = module.apim_private_endpoint.azurerm_private_dns_zone.this
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/privateDnsZones/privatelink.azure-api.net"
}
import {
  to = module.apim_private_endpoint.azurerm_private_dns_a_record.apim
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/privateDnsZones/privatelink.azure-api.net/A/tbi-apim-exam-ai-103"
}
import {
  to = module.apim_private_endpoint.azurerm_private_dns_zone_virtual_network_link.this
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/privateDnsZones/privatelink.azure-api.net/virtualNetworkLinks/tbi-apim-exam-ai-103-vnet-link"
}

# ── keyvault_appgw_cert ──────────────────────────────────────────────────────
import {
  to = module.keyvault_appgw_cert.azurerm_user_assigned_identity.appgw
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tbi-mi-agw-exam-ai-103"
}
import {
  to = module.keyvault_appgw_cert.azurerm_key_vault.this
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.KeyVault/vaults/tbi-kv-ai103plat"
}

# ── appgw (Modul count = deploy_appgw ? 1 : 0 → Index am Modul!) ─────────────
import {
  to = module.appgw[0].azurerm_public_ip.this
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/publicIPAddresses/tbi-pip-agw-exam-ai-103"
}
import {
  to = module.appgw[0].azurerm_web_application_firewall_policy.this
  # Provider-Parser verlangt klein geschriebenes "applicationGateway..." (ARM-IDs sind case-insensitive)
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/tbi-agw-exam-ai-103-wafpolicy"
}
import {
  to = module.appgw[0].azurerm_application_gateway.this
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-platform/providers/Microsoft.Network/applicationGateways/tbi-agw-exam-ai-103"
}

# ── foundry_rbac ─────────────────────────────────────────────────────────────
import {
  to = module.foundry_rbac.azurerm_role_assignment.apim_openai_user
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-mte/providers/Microsoft.CognitiveServices/accounts/tbit-training-ai-103-pr-resource/providers/Microsoft.Authorization/roleAssignments/b05b8d5a-9230-5159-ab6e-1c066aa9c611"
}

# ── foundry_models (Modul for_each → Adresse mit Key) ────────────────────────
import {
  to = module.foundry_models.azurerm_cognitive_deployment.this["gpt-5-mini"]
  id = "/subscriptions/5cef6e78-e33e-4ceb-855e-5d85f4debdd4/resourceGroups/tbi-rg-exam-ai-103-mte/providers/Microsoft.CognitiveServices/accounts/tbit-training-ai-103-pr-resource/deployments/gpt-5-mini"
}

# Bewusst NICHT importiert (siehe docs/terraform-migration.md):
#   - zweites Role-Assignment am Foundry-Account
#     fdc0bad1-81fc-4fa5-a14e-c77d9ca35941 (anderer Service Principal,
#     Rolle "Cognitive Services User") — gehört nicht zu dieser Platform;
#     im State würde TF es bei destroy/apply entfernen wollen.
#   - APIM-Unterressourcen (APIs, Products, Named Values, Backends,
#     Subscriptions) → apiops via mise run apim:export/apply.
