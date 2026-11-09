variable "vm_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "Subnet-ID (privatelink)"
  type        = string
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  description = "Öffentlicher SSH-Key der VM (Pflicht beim Aktivieren; nie einen privaten Key committen)"
  type        = string
}

variable "ssh_source_prefix" {
  description = "CIDR, das SSH auf die VM darf (default: nur der eigene Absender beim ersten Deploy — vorher absichern!)"
  type        = string
}
