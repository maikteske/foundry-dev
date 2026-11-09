variable "apim_id" {
  description = "Ressourcen-ID der APIM-Instanz"
  type        = string
}

variable "apim_name" {
  description = "Name der APIM-Instanz (für PE-Verbindungsname und A-Record)"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "Subnet für den Private Endpoint"
  type        = string
}

variable "vnet_id" {
  description = "VNet-ID für den DNS-Zonen-Link"
  type        = string
}
