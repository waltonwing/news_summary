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

variable "identity_suffix" {
  type    = list(string)
  default = ["alpha", "beta", "gamma"]
}

variable "subnets" {
  type = map(string)
  default = {
    "subnet1" = "10.0.0.0/24"
    "subnet2" = "10.0.1.0/24"
    "subnet3" = "10.0.2.0/24"
  }
}

resource "azurerm_resource_group" "demo" {
  name     = "rg-demo"
  location = "eastus"
}

# resource "azurerm_user_assigned_identity" "demoOne" {
#   count               = 3                                              // can also count length(var.identity_suffix)
#   name                = "id-count-${var.identity_suffix[count.index]}" // count.index is the index of the current element in the list
#   resource_group_name = azurerm_resource_group.demo.name
#   location            = azurerm_resource_group.demo.location

#   tags = {
#     "identity_serial" = "${count.index + 1}"
#   }
# }

# resource "azurerm_user_assigned_identity" "demoTwo" {
#   for_each            = toset(var.identity_suffix) // toset() is used to convert the list to a set
#   name                = "id-foreach-${each.value}" // each.value is the value of the current element in the list
#   resource_group_name = azurerm_resource_group.demo.name
#   location            = azurerm_resource_group.demo.location

#   tags = {
#     "identity_serial" = "${each.key}" // each.key is same as each.value in a set
#   }
# }

resource "azurerm_virtual_network" "demo" {
  name                = "vnet-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  dynamic "subnet" {
    for_each = var.subnets
    content {
      name           = subnet.key
      address_prefix = subnet.value
    }
  }
}

# output "user_assigned_identity_name" {
#   value = azurerm_user_assigned_identity.demoOne.*.name
# }

# output "user_assigned_identity_id_beta" {
#   value = azurerm_user_assigned_identity.demoTwo["beta"].id
# }