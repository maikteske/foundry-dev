variable "apim_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "publisher_email" {
  description = "Publisher-E-Mail (Pflichtfeld von APIM)"
  type        = string
}

variable "publisher_name" {
  description = "Publisher-Name (Pflichtfeld von APIM)"
  type        = string
}

variable "apim_out_subnet_id" {
  description = "Subnet für outbound VNet-Integration (delegiert an Microsoft.Web/serverFarms)"
  type        = string
}

variable "public_network_access" {
  description = "Enabled beim Bootstrap, Disabled nach PE-Anlage (Two-Phase-Lockdown)"
  type        = string

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "Nur Enabled oder Disabled."
  }
}
