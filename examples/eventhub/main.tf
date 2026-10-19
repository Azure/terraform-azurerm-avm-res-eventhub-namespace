terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "australiaeast"
  name     = module.naming.resource_group.name_unique
}

locals {
  event_hubs = {
    my_event_hub = {
      namespace_name      = module.event_hub.resource.id
      partition_count     = 1
      message_retention   = 7
      resource_group_name = module.event_hub.resource.name
    }
  }
}

module "event_hub" {
  source = "../../"
  providers = {
    azapi = azapi
  }

  location            = azurerm_resource_group.this.location
  name                = module.naming.eventhub_namespace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  auto_inflate_enabled     = true
  enable_telemetry         = var.enable_telemetry
  event_hubs               = local.event_hubs
  maximum_throughput_units = 20
}
