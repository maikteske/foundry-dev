variable "vnet_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_prefix" {
  description = "AddressSpace des VNets"
  type        = string
}

variable "appgw_subnet_prefix" {
  type = string
}

variable "apim_out_subnet_prefix" {
  type = string
}

variable "privatelink_subnet_prefix" {
  type = string
}
