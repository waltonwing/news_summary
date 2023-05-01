terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0"
    }
  }
}

provider "azurerm" {
  features {
  }
}

variable "deploy_identity" {
  type    = bool
  default = false
}

variable "subnets" {
  type = map(string)
  default = {
    "subnet1" = "10.10.0.0/24"
    "subnet2" = "10.10.1.0/24"
  }
}

data "azurerm_resource_group" "demo" {
  name = "rg-demo"
}

resource "azurerm_user_assigned_identity" "conditional" {
  count               = var.deploy_identity ? 1 : 0 // condition ? true_val : false_val
  name                = "id-conditional"
  resource_group_name = data.azurerm_resource_group.demo.name
  location            = data.azurerm_resource_group.demo.location
}

resource "azurerm_role_assignment" "conditional" {
  count                = var.deploy_identity ? 1 : 0 // use the same condition to deploy resources within same lifecycle
  scope                = data.azurerm_resource_group.demo.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.conditional[0].principal_id
}

resource "azurerm_virtual_network" "conditional" {
  name                = "vnet-conditional"
  address_space       = ["10.10.0.0/16"]
  location            = data.azurerm_resource_group.demo.location
  resource_group_name = data.azurerm_resource_group.demo.name
}

resource "azurerm_subnet" "conditional" {
  for_each             = var.subnets // conditioal: nothing is deployed if the map is empty
  name                 = each.key
  address_prefixes     = [each.value]
  resource_group_name  = data.azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.conditional.name
}

output "role_assignment_id" {
  value = try(azurerm_role_assignment.conditional[0].id, "No role assignment found!") // try each element in the list
}

output "subnet_ids" {
  value = [for subnet in azurerm_subnet.conditional : subnet.id] // syntax: [for <var> in <list> : <expression>]
}