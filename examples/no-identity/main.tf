terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "AustraliaEast"
  name     = module.naming.resource_group.name_unique
}

# This example demonstrates deploying an Event Hub namespace without any managed identity.
# This is a valid scenario where no identity configuration is needed.
# The module should correctly handle managed_identities = {} without creating an identity block.
module "event_hub" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.eventhub_namespace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = false
  # Explicitly passing empty object to test the "no identity" scenario
  # This should NOT create any identity block on the Event Hub namespace
  managed_identities = {}
}
