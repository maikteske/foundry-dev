# Wiring 1:1 zu infra/platform.bicep.
# apiops-Artefakte (apim-artifacts/) bleiben Source of Truth für APIM-APIs,
# Products, Named Values, Backends und Subscriptions — hier bewusst NICHT
# verwaltet (siehe docs/terraform-migration.md, Regel 1).

locals {
  backend_fqdn    = "${var.apim_name}.azure-api.net"
  cert_secret_uri = "https://${var.keyvault_name}.vault.azure.net/secrets/${var.cert_name}"

  # Cognitive Services OpenAI User — fixe GUID, damit das Assignment-Name-GUID
  # von Bicep (guid(account.id, 'apim-openai-user')) importierbar bleibt.
  openai_user_role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"
}

resource "azurerm_resource_group" "platform" {
  name     = var.resource_group_name
  location = var.location
}

# Bestehender Foundry-Account: nur Referenz (Portal-verwaltet, kein import).
data "azurerm_cognitive_account" "foundry" {
  name                = var.foundry_account_name
  resource_group_name = var.foundry_resource_group_name
}

module "vnet" {
  source = "./modules/vnet"

  vnet_name                 = var.vnet_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  address_prefix            = var.vnet_address_prefix
  appgw_subnet_prefix       = var.appgw_subnet_prefix
  apim_out_subnet_prefix    = var.apim_out_subnet_prefix
  privatelink_subnet_prefix = var.privatelink_subnet_prefix
}

module "apim" {
  source = "./modules/apim"

  apim_name             = var.apim_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  publisher_email       = var.apim_publisher_email
  publisher_name        = var.apim_publisher_name
  apim_out_subnet_id    = module.vnet.apim_out_subnet_id
  public_network_access = var.apim_public_network_access
}

module "apim_private_endpoint" {
  source = "./modules/apim_private_endpoint"

  apim_id             = module.apim.apim_id
  apim_name           = var.apim_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.vnet.privatelink_subnet_id
  vnet_id             = module.vnet.vnet_id
}

# RBAC: APIM-MI darf am Foundry-Account inferieren (cross-RG scope).
module "foundry_rbac" {
  source = "./modules/foundry_rbac"

  principal_id = module.apim.apim_principal_id
  # Azure-RBAC-API liefert den Assignment-Scope mit kleingeschriebenem
  # "resourcegroups" zurück (unabhängig vom tatsächlich verwendeten Casing).
  # Ohne Angleichung will TF das Assignment nach dem Import REPLACEN
  # (scope ist ForceNew) — daher exakt die API-Casing übernehmen.
  # Achtung: replace() mit "/.../" wäre Regex! Hier bewusst Substring-Form.
  account_id           = replace(data.azurerm_cognitive_account.foundry.id, "resourceGroups", "resourcegroups")
  role_assignment_name = "b05b8d5a-9230-5159-ab6e-1c066aa9c611" # Bicep: guid(account.id, 'apim-openai-user')
  role_definition_id   = local.openai_user_role_definition_id
}

# Vault + User-MI + Access-Policies; das Zertifikat selbst bleibt extern
# (mise run cert:issue + cert:import), dafür gibt es KEINE TF-Ressource.
module "keyvault_appgw_cert" {
  source = "./modules/keyvault_appgw_cert"

  keyvault_name       = var.keyvault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  kv_admin_object_id  = var.kv_admin_object_id
  appgw_identity_name = var.appgw_identity_name
  cert_name           = var.cert_name
}

module "appgw" {
  source = "./modules/appgw"
  count  = var.deploy_appgw ? 1 : 0

  appgw_name          = var.appgw_name
  public_ip_name      = var.appgw_public_ip_name
  public_ip_dns_label = var.appgw_dns_label
  hostname            = var.appgw_hostname
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.vnet.appgw_subnet_id
  identity_id         = module.keyvault_appgw_cert.appgw_identity_id
  cert_secret_uri     = local.cert_secret_uri
  backend_fqdn        = local.backend_fqdn
}

module "testvm" {
  source = "./modules/testvm"
  count  = var.deploy_test_vm ? 1 : 0

  vm_name             = var.test_vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.vnet.privatelink_subnet_id
  admin_username      = var.test_vm_admin_username
  ssh_public_key      = var.test_vm_ssh_public_key
  ssh_source_prefix   = var.test_vm_ssh_source_prefix
}

module "foundry_models" {
  source = "./modules/foundry_models"

  account_id  = data.azurerm_cognitive_account.foundry.id
  deployments = var.foundry_deployments
}
