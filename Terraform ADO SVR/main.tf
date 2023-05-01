terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_virtual_network" "adds" {
  resource_group_name = var.adds_rg
  name                = var.adds_vnet
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-adosvr"
  location = var.resource_group_location

  tags = {
    Alias = "Walton Chiang"
  }
}
#------------------------------------------------------------------------------
resource "azurerm_network_security_group" "adosvr" {
  name                = "nsg-adosvr"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule { //Here opened remote desktop port
    name                       = "RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Alias = "Walton Chiang"
  }
}

resource "azurerm_virtual_network" "adosvr" {
  name                = "vnet-adosvr"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
  dns_servers         = var.adds_ip

  tags = {
    Alias = "Walton Chiang"
  }
}

resource "azurerm_subnet" "adosvr" {
  name                 = "subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.adosvr.name
  address_prefixes     = ["10.1.1.0/24"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_subnet" "adobastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.adosvr.name
  address_prefixes     = ["10.1.2.0/24"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_virtual_network_peering" "peer-1" {
  name                      = "svr-to-adds"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.adosvr.name
  remote_virtual_network_id = data.azurerm_virtual_network.adds.id
}

resource "azurerm_virtual_network_peering" "peer-2" {
  name                      = "adds-to-svr"
  resource_group_name       = data.azurerm_virtual_network.adds.resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.adds.name
  remote_virtual_network_id = azurerm_virtual_network.adosvr.id
}
#------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "adosvr" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "id-adosvr"

  tags = {
    Alias = "Walton Chiang"
  }
}
#------------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "adosvr" {
  name                        = "kv-adosvr"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.adosvr.principal_id

    secret_permissions = [
      "Get",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "set",
      "get",
      "list",
      "delete",
      "purge",
      "recover"
    ]
  }

  tags = {
    Alias = "Walton Chiang"
  }
}

resource "random_password" "password" {
  length           = 16
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = true
  override_special = "()[]{}<>"
}

resource "azurerm_key_vault_secret" "adosvr" {
  name         = "AzDevOpsSqlPass"
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.adosvr.id

  tags = {
    Alias = "Walton Chiang"
  }
}
#---------------------------------------------------------------------------
resource "azurerm_sql_server" "adosvr" {
  name                         = "sql-adosvr"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "adosqladmin"
  administrator_login_password = azurerm_key_vault_secret.adosvr.value

  tags = {
    Alias = "Walton Chiang"
  }
}

resource "azurerm_sql_firewall_rule" "adosvr" {
  name                = "FirewallRule1"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.adosvr.name
  start_ip_address    = "0.0.0.0" //0.0.0.0 means allow Azure services
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_virtual_network_rule" "adosvr" {
  name                                 = "sql-vnet-rule"
  resource_group_name                  = azurerm_resource_group.rg.name
  server_name                          = azurerm_sql_server.adosvr.name
  subnet_id                            = azurerm_subnet.adosvr.id
  ignore_missing_vnet_service_endpoint = true
}

resource "azurerm_sql_active_directory_administrator" "adosvr" {
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.adosvr.name
  login               = "admin"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = var.sql_admin
}

resource "azurerm_storage_account" "adosvr" {
  name                     = "saadosvr9483"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Alias = "Walton Chiang"
  }
}
resource "azurerm_sql_database" "adosvr01" {
  name                = "AzureDevOps_Configuration"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.adosvr.name

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.adosvr.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.adosvr.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }

  tags = {
    Alias = "Walton Chiang"
  }
}

resource "azurerm_sql_database" "adosvr02" {
  name                = "AzureDevOps_DefaultCollection"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.adosvr.name

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.adosvr.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.adosvr.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }

  tags = {
    Alias = "Walton Chiang"
  }
}
#-------------------------------------------------------------------
resource "azurerm_public_ip" "adobastion" {
  name                    = "pip-bastion"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"
  availability_zone       = "No-Zone"

  tags = {
    Alias = "Walton Chiang"
  }
}

resource "azurerm_bastion_host" "adosvr" {
  name                = "bastion-adosvr"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "IpConf"
    subnet_id            = azurerm_subnet.adobastion.id
    public_ip_address_id = azurerm_public_ip.adobastion.id
  }

  tags = {
    Alias = "Walton Chiang"
  }
}
#-------------------------------------------------------------------
resource "azurerm_public_ip" "vm-image" {
  name                    = "pip-vm-image"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    Alias = "Walton Chiang"
  }
}

resource "azurerm_network_interface" "vm-image" {
  name                = "vm-image-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.adosvr.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm-image.id
  }

  tags = {
    Alias = "Walton Chiang"
  }
}

resource "azurerm_windows_virtual_machine" "imagevm" {
  name                = "vm-image"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D4s_v3"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.vm-image.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "microsoftsqlserver"
    offer     = "sql2019-ws2019"
    sku       = "sqldev"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Alias = "Walton Chiang"
  }
}

resource "azurerm_role_assignment" "adosvr" {
  scope                = azurerm_sql_server.adosvr.id
  role_definition_name = "Owner"
  principal_id         = azurerm_windows_virtual_machine.imagevm.identity.0.principal_id
}

resource "azurerm_virtual_machine_extension" "install_IIS" {
  name                 = "hostname"
  virtual_machine_id   = azurerm_windows_virtual_machine.imagevm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"./install.ps1; exit 0;\""
    }
SETTINGS
}
