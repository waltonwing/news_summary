resource "azurerm_firewall_policy_rule_collection_group" "example" {
  name               = "DefaultApplicationRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.example.id
  priority           = 300
  application_rule_collection {
    name     = "AzureAuth"
    priority = 110
    action   = "Allow"
    rule {
      name = "msftauth"
      protocols {
        type = "Https"
        port = 443
      }
      terminate_tls     = false
      source_addresses  = ["*"]
      destination_fqdns = ["aadcdn.msftauth.net", "aadcdn.msauth.net"]
    }
  }
}