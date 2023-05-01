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

resource "azurerm_resource_group" "demo" {
  name     = "rg-demo"
  location = "eastus"
}

resource "azurerm_user_assigned_identity" "demo" {
  name                = "id-demo-1"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location

  tags = {
    environment = "demo"
  }

  # lifecycle {
  #   ignore_changes = [
  #     tags
  #   ]
  # }
}