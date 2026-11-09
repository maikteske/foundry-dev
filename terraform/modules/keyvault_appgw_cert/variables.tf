variable "keyvault_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tenant_id" {
  description = "Entra-Tenant des Vaults (nicht vom Login ableiten)"
  type        = string
}

variable "kv_admin_object_id" {
  description = "Entra-Objekt-ID des Admin-Kontos, das Zertifikate importieren darf (leer = keine Admin-Policy; hier bewusst immer gesetzt, Bicep-Pfad mit leerem Wert entfällt)"
  type        = string
}

variable "appgw_identity_name" {
  description = "Name der User-Managed-Identity für das App Gateway"
  type        = string
}

variable "cert_name" {
  description = "Prefix für das App-Gateway-Zertifikat im KV (für den Secret-URI-Output)"
  type        = string
}
