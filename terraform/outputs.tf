# Outputs: Parität zu platform.bicep-Outputs (siehe dort) + vnet/Subnet/DNS-IDs.

output "apim_gateway_url" {
  description = "Gateway-URL der APIM-Instanz"
  value       = module.apim.apim_gateway_url
}

output "apim_principal_id" {
  description = "APIM-System-MI Principal-ID (z. B. für Fabric-Workspace-Membership)"
  value       = module.apim.apim_principal_id
}

output "pe_ip" {
  description = "IP des Private Endpoints"
  value       = module.apim_private_endpoint.pe_ip
}

output "pe_registered_fqdn" {
  description = "Registrierter privatelink-FQDN"
  value       = module.apim_private_endpoint.registered_fqdn
}

output "keyvault_name" {
  description = "Name des Key Vaults"
  value       = module.keyvault_appgw_cert.keyvault_name
}

output "appgw_fqdn" {
  description = "FQDN der App-GW-Public-IP (Cloudflare-CNAME-Ziel)"
  value       = var.deploy_appgw ? module.appgw[0].public_ip_fqdn : ""
}

output "appgw_public_ip" {
  value = var.deploy_appgw ? module.appgw[0].public_ip : ""
}

# ── Neu gegenüber Bicep (Spec-Anforderung) ──────────────────────────────────

output "vnet_id" {
  value = module.vnet.vnet_id
}

output "appgw_subnet_id" {
  value = module.vnet.appgw_subnet_id
}

output "apim_out_subnet_id" {
  value = module.vnet.apim_out_subnet_id
}

output "privatelink_subnet_id" {
  value = module.vnet.privatelink_subnet_id
}

output "private_dns_zone_id" {
  value = module.apim_private_endpoint.dns_zone_id
}

output "foundry_account_endpoint" {
  description = "Endpoint des Foundry-Accounts (Data-Source, entspricht main.bicep-Output)"
  value       = data.azurerm_cognitive_account.foundry.endpoint
}
