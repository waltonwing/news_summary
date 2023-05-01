variable "resource_group_location" {
  type        = string
  default     = "usgovtexas"
  description = "Location of the resource group."
}

variable "adds_rg" {
  type        = string
  default     = "USDC-Migration"
  description = "Resource group name of AD Domain Service."
}

variable "adds_vnet" {
  type        = string
  default     = "USDC-Migration-VNet"
  description = "Virtual network name of AD Domain Service."
}

variable "adds_ip" {
  type        = list(string)
  default     = ["10.4.0.6"]
  description = "IP addresses of AD Domain Service, or DNS IP if not in the same server."
}

variable "sql_admin" {
  type        = string
  default     = "ad9d33c7-565b-4ed4-a2ce-62faa32716ae"
  description = "Object ID for an Azure AD account to be assigned as SQL server admin"
}