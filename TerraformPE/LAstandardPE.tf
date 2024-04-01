terraform {
  required_version = ">= 0.11" 
backend "azurerm" {
  storage_account_name = "__terraformstorageaccount__"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
  access_key  ="__storagekey__"
  }
  }
  provider "azurerm" {
  features {}
}

#create the resource group
resource "azurerm_resource_group" "dev" {
  name     = "la-pe-tfdeploy-rg"
  location = "East US"
}

#create the vnet and subnet
resource "azurerm_virtual_network" "dev" {
  name                = "vnet-test-huidong"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  address_space       = ["10.0.0.0/16"]
}

# Create Logic App integration subnet
resource "azurerm_subnet" "la_integration_subnet" {
  name                 = "la_integration_subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
    }
  }
}


# Create Logic App private endpoint subnet
resource "azurerm_subnet" "la_endpoint_subnet" {
  name                 = "la_endpoint_subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.0.2.0/24"]
  enforce_private_link_endpoint_network_policies = true
}

# Create storage private endpoint subnet
resource "azurerm_subnet" "sa_subnet" {
  name                 = "sa_subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.0.3.0/24"]

  enforce_private_link_endpoint_network_policies = true
}

#create the storage account for Logic App
resource "azurerm_storage_account" "dev" {
  name                     = "logicapptestsa"
  resource_group_name      = azurerm_resource_group.dev.name
  location                 = azurerm_resource_group.dev.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#create the file share
resource "azurerm_storage_share" "dev" {
  name                 = "logicapp-pe-test-huidong"
  storage_account_name = azurerm_storage_account.dev.name
  quota                = 50
  depends_on           = [azurerm_storage_account.dev]
}

#create the private DNS zone
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.dev.name
}

#create blob private endpoint
resource "azurerm_private_endpoint" "blob" {
  depends_on = [azurerm_storage_account.dev]
  name                = "blob-endpoint"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  subnet_id           = azurerm_subnet.sa_subnet.id

  private_service_connection {
    name                           = "blob-connection"
    private_connection_resource_id = azurerm_storage_account.dev.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-endpoint"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

#create the private link
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob_link"
  resource_group_name   = azurerm_resource_group.dev.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.dev.id
}

#create the private DNS zone
resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.dev.name
}

#create file private endpoint
resource "azurerm_private_endpoint" "file" {
  name                = "file-endpoint"
  depends_on = [azurerm_storage_account.dev]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  subnet_id           = azurerm_subnet.sa_subnet.id

  private_service_connection {
    name                           = "file-connection"
    private_connection_resource_id = azurerm_storage_account.dev.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "file-endpoint"
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }
}

#create the private link
resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                  = "file_link"
  resource_group_name   = azurerm_resource_group.dev.name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = azurerm_virtual_network.dev.id
}

#create the private DNS zone
resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.dev.name
}

#create table private endpoint
resource "azurerm_private_endpoint" "table" {
  name                = "table-endpoint"
  depends_on = [azurerm_storage_account.dev]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  subnet_id           = azurerm_subnet.sa_subnet.id

  private_service_connection {
    name                           = "table-connection"
    private_connection_resource_id = azurerm_storage_account.dev.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "table-endpoint"
    private_dns_zone_ids = [azurerm_private_dns_zone.table.id]
  }
}
#create the private link
resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "table_link"
  resource_group_name   = azurerm_resource_group.dev.name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.dev.id
}


#create the private DNS zone
resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.dev.name
}

#create queue private endpoint
resource "azurerm_private_endpoint" "queue" {
  depends_on = [azurerm_storage_account.dev]
  name                = "queue-endpoint"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  subnet_id           = azurerm_subnet.sa_subnet.id

  private_service_connection {
    name                           = "queue-connection"
    private_connection_resource_id = azurerm_storage_account.dev.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "queue-endpoint"
    private_dns_zone_ids = [azurerm_private_dns_zone.queue.id]
  }
}

#create the private link
resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  name                  = "queue_link"
  resource_group_name   = azurerm_resource_group.dev.name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.dev.id
}

#create the app service plan
resource "azurerm_service_plan" "dev" {
  name                = "logicapp-test-service-plan"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  os_type             = "Windows"
  sku_name = "WS1"

}

#create the log analytics workspace for applicatin insights
resource "azurerm_log_analytics_workspace" "dev" {
    name                = "logic-app-test-log-workspace"
    location            = azurerm_resource_group.dev.location
    resource_group_name = azurerm_resource_group.dev.name
    sku                 = "PerGB2018"
    retention_in_days   = 30
}

#create the application insights
resource "azurerm_application_insights" "dev" {
  depends_on = [azurerm_log_analytics_workspace.dev]
  name                     = "logicapp-pe-test-huidong"
  location                 = azurerm_resource_group.dev.location
  resource_group_name      = azurerm_resource_group.dev.name
  application_type         = "web"
  workspace_id             = azurerm_log_analytics_workspace.dev.id
}



#create the standard Logic App with application insights and system managed identity enabled
resource "azurerm_logic_app_standard" "dev" {

  depends_on = [azurerm_private_endpoint.blob,azurerm_private_endpoint.file,azurerm_private_endpoint.table,azurerm_private_endpoint.queue,azurerm_service_plan.dev,azurerm_application_insights.dev]
  name                       = "logicapp-pe-test-huidong"
  location                   = azurerm_resource_group.dev.location
  resource_group_name        = azurerm_resource_group.dev.name
  app_service_plan_id        = azurerm_service_plan.dev.id
  storage_account_name       = azurerm_storage_account.dev.name
  storage_account_access_key = azurerm_storage_account.dev.primary_access_key
  storage_account_share_name = azurerm_storage_share.dev.name
  virtual_network_subnet_id  = azurerm_subnet.la_integration_subnet.id
  version                    = "~4"

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"        = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"    = "~18"
    "APPINSIGHTS_INSTRUMENTATIONKEY"  = azurerm_application_insights.dev.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.dev.connection_string
    "WEBSITE_DNS_SERVER"  = "168.63.129.16"
    "WEBSITE_CONTENTOVERVNET"    = "1"
    "WEBSITE_VNET_ROUTE_ALL"     = "1"
  }
  
  identity {
    type = "SystemAssigned"
  }
}

#create the private DNS zone
resource "azurerm_private_dns_zone" "site" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.dev.name
}

#create the private link
resource "azurerm_private_dns_zone_virtual_network_link" "site" {
  name                  = "site_link"
  resource_group_name   = azurerm_resource_group.dev.name
  private_dns_zone_name = azurerm_private_dns_zone.site.name
  virtual_network_id    = azurerm_virtual_network.dev.id
}

#create private endpoint
resource "azurerm_private_endpoint" "dev" {
  depends_on = [azurerm_logic_app_standard.dev]
  name                = "app-endpoint"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  subnet_id           = azurerm_subnet.la_endpoint_subnet.id

  private_service_connection {
    name                           = "app-connection"
    private_connection_resource_id = azurerm_logic_app_standard.dev.id
    subresource_names               = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "logic-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.site.id]
  }

}
