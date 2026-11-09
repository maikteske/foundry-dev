# Defaults 1:1 aus infra/platform.bicep + platform.bicepparam übernommen.
# Phasen-Schalter (vgl. Bicep-Parameter deployAppGw / apimPublicNetworkAccess /
# deployTestVm): Live-Stand ist in terraform.tfvars gesetzt.

variable "subscription_id" {
  description = "Azure-Subscription des Platform-Gateways (TBIT Training)"
  type        = string
  default     = "5cef6e78-e33e-4ceb-855e-5d85f4debdd4"
}

variable "tenant_id" {
  description = "Entra-Tenant (für Key Vault tenant_id, bewusst nicht vom Login ableitbar)"
  type        = string
  default     = "6e069cd6-8fb1-4eb7-a7c6-8d6a50b603f3"
}

variable "location" {
  description = "Azure-Region"
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "Platform-ResourceGroup (wird importiert)"
  type        = string
  default     = "tbi-rg-exam-ai-103-platform"
}

variable "vnet_name" {
  type    = string
  default = "tbi-vnet-exam-ai-103-platform"
}

variable "vnet_address_prefix" {
  type    = string
  default = "10.70.0.0/16"
}

variable "appgw_subnet_prefix" {
  type    = string
  default = "10.70.0.0/26"
}

variable "apim_out_subnet_prefix" {
  type    = string
  default = "10.70.0.64/27"
}

variable "privatelink_subnet_prefix" {
  type    = string
  default = "10.70.0.128/26"
}

variable "apim_name" {
  type    = string
  default = "tbi-apim-exam-ai-103"
}

variable "apim_publisher_email" {
  type    = string
  default = "maik.teske@googlemail.com"
}

variable "apim_publisher_name" {
  type    = string
  default = "Maik Teske"
}

variable "apim_public_network_access" {
  description = "Enabled = Two-Phase-Lockdown Phase 1, Disabled = PE exklusiver Inbound (Phase 2)"
  type        = string
  default     = "Enabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.apim_public_network_access)
    error_message = "Nur Enabled oder Disabled."
  }
}

variable "keyvault_name" {
  type    = string
  default = "tbi-kv-ai103plat"
}

variable "kv_admin_object_id" {
  description = "Entra-Objekt-ID des Admin-Kontos für KV-Zertifikat-Importe (leer = keine Admin-Policy)"
  type        = string
  default     = "723948da-3488-497b-a477-a5c5a5ae18c0"
}

variable "appgw_identity_name" {
  description = "User-Assigned Identity, die das App-GW-Zertifikat aus dem KV liest"
  type        = string
  default     = "tbi-mi-agw-exam-ai-103"
}

variable "cert_name" {
  description = "Name des App-GW-Zertifikats im Key Vault (extern via cert:issue/cert:import)"
  type        = string
  default     = "appgw-tls"
}

variable "appgw_name" {
  type    = string
  default = "tbi-agw-exam-ai-103"
}

variable "appgw_public_ip_name" {
  type    = string
  default = "tbi-pip-agw-exam-ai-103"
}

variable "appgw_dns_label" {
  description = "DNS-Label der App-GW-Public-IP (CNAME-Ziel <label>.<region>.cloudapp.azure.com)"
  type        = string
  default     = "tbi-agw-exam-ai-103"
}

variable "appgw_hostname" {
  description = "Public-Hostname des Gateways (Cloudflare-CNAME-Ziel)"
  type        = string
  default     = "api.maikteske.dev"
}

variable "deploy_appgw" {
  description = "App-GW-Modul deployen? false beim Bootstrap (KV-Zertifikat fehlt dann noch)"
  type        = bool
  default     = true
}

variable "deploy_test_vm" {
  description = "Optionale Test-VM in snet-privatelink (existiert aktuell nicht im Azure — Bootstrap aus)"
  type        = bool
  default     = false
}

variable "test_vm_name" {
  type    = string
  default = "tbi-vm-ai103plat-test"
}

variable "test_vm_admin_username" {
  type    = string
  default = "azureuser"
}

variable "test_vm_ssh_public_key" {
  # TODO: Pflicht beim Aktivieren von deploy_test_vm; kein Key im Repo committen.
  type    = string
  default = ""
}

variable "test_vm_ssh_source_prefix" {
  description = "CIDR, das SSH auf die Test-VM darf (default: weiter absichern!)"
  type        = string
  default     = "*"
}

variable "foundry_resource_group_name" {
  description = "RG des bestehenden Foundry-Accounts (nur Data-Source, keine Verwaltung)"
  type        = string
  default     = "tbi-rg-exam-ai-103-mte"
}

variable "foundry_account_name" {
  description = "Name des bestehenden Foundry-Accounts (Portal-verwaltet)"
  type        = string
  default     = "tbit-training-ai-103-pr-resource"
}

variable "foundry_deployments" {
  description = "Model-Deployments am Foundry-Account (vgl. infra/main.bicep)"
  type = map(object({
    model_name    = string
    model_version = string
    sku_name      = string
    capacity      = number
  }))
  default = {
    "gpt-5-mini" = {
      model_name    = "gpt-5-mini"
      model_version = "2025-08-07"
      sku_name      = "GlobalStandard"
      capacity      = 50
    }
  }
}
