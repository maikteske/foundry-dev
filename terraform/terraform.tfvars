# Ersetzt infra/platform.bicepparam. Enthaelt nur nicht-sensible Identifikatoren
# (keine Secrets!). Live-Stand des Gateways (Stand 2026-11-09).

subscription_id     = "5cef6e78-e33e-4ceb-855e-5d85f4debdd4"
tenant_id           = "6e069cd6-8fb1-4eb7-a7c6-8d6a50b603f3"
location            = "swedencentral"
resource_group_name = "tbi-rg-exam-ai-103-platform"

vnet_name            = "tbi-vnet-exam-ai-103-platform"
apim_name            = "tbi-apim-exam-ai-103"
keyvault_name        = "tbi-kv-ai103plat"
appgw_name           = "tbi-agw-exam-ai-103"
appgw_public_ip_name = "tbi-pip-agw-exam-ai-103"
appgw_dns_label      = "tbi-agw-exam-ai-103"
appgw_hostname       = "api.maikteske.dev"

apim_publisher_email = "maik.teske@googlemail.com"
apim_publisher_name  = "Maik Teske"

# Objekt-ID des Admin-Logins (~/.azure-adm) fuer KV-Zertifikat-Importe:
# adm-mteske@teambusinessit.de (via Activity-Log-Claims verifiziert)
kv_admin_object_id = "723948da-3488-497b-a477-a5c5a5ae18c0"

# Phasen-Schalter — Live-Stand (platform:lockdown bereits gefahren):
deploy_appgw               = true
apim_public_network_access = "Disabled"
deploy_test_vm             = false

foundry_resource_group_name = "tbi-rg-exam-ai-103-mte"
foundry_account_name        = "tbit-training-ai-103-pr-resource"
