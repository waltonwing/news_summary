resource "azurerm_firewall_policy_rule_collection_group" "example" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.example.id
  priority           = 200
  network_rule_collection {
    name     = "AllowAzureCloud"
    priority = 100
    action   = "Allow"
    rule {
      name                  = "AzureCloud"
      protocols             = ["Any"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["*"]
    }
  }
  network_rule_collection {
    name     = "AllowTrafficBetweenSpokes"
    priority = 200
    action   = "Allow"
    rule {
      name                  = "AllowT1toT0"
      protocols             = ["Any"]
      source_addresses      = ["10.0.8.0/21"] //T1 vnet
      destination_addresses = ["10.0.4.0/24"] //T0 vnet
      destination_ports     = ["*"]
    }
  }
  network_rule_collection {
    name     = "AllowTrafficBetweenSpokes"
    priority = 250
    action   = "Allow"
    rule {
      name                  = "AllowT0toT1"
      protocols             = ["Any"]
      source_addresses      = ["10.0.4.0/24"]
      destination_addresses = ["10.0.8.0/21"]
      destination_ports     = ["*"]
    }
  }
  network_rule_collection {
    name     = "AllowADOServerToInternet"
    priority = 300
    action   = "Allow"
    rule {
      name                  = "AllowT0toT1"
      protocols             = ["Any"]
      source_addresses      = ["10.0.8.0/26"]
      destination_addresses = ["Internet"] //service tag
      destination_ports     = ["*"]
    }
  }
}