variable "appgw_name" {
  type = string
}

variable "public_ip_name" {
  description = "Name der öffentlichen IP"
  type        = string
}

variable "public_ip_dns_label" {
  description = "DNS-Label der öffentlichen IP (CNAME-Ziel: <label>.<region>.cloudapp.azure.com)"
  type        = string
}

variable "hostname" {
  description = "Hostname des HTTPS-Listeners (z. B. api.maikteske.dev)"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "Subnet-ID für das App Gateway (nur AppGW, min /26)"
  type        = string
}

variable "identity_id" {
  description = "Ressourcen-ID der User-Managed-Identity (liest KV-Zertifikat)"
  type        = string
}

variable "cert_secret_uri" {
  description = "Versionless Secret-URI des KV-Zertifikats (https://<kv>.vault.azure.net/secrets/<name>)"
  type        = string
}

variable "backend_fqdn" {
  description = "FQDN des APIM-Gateways als Backend (z. B. <apim>.azure-api.net)"
  type        = string
}

variable "cert_name" {
  description = "Name des KV-Zertifikats (für ssl_certificate)"
  type        = string
  default     = "appgw-tls"
}

variable "probe_path" {
  description = "Health-Probe-Pfad der APIM-Instanz"
  type        = string
  default     = "/status-0123456789abcdef"
}
