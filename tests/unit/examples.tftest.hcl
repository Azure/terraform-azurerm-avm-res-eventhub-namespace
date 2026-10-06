mock_provider "azapi" {}
mock_provider "modtm" {}

mock_provider "random" {
  mock_resource "random_string" {
    defaults = {
      result = "avmtest"
    }
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      object_id       = "00000000-0000-0000-0000-000000000001"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_resource "azurerm_eventhub_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventHub/namespaces/test-namespace"
    }
  }

  mock_data "azurerm_eventhub_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventHub/namespaces/existing-namespace"
    }
  }

  mock_resource "azurerm_eventhub" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventHub/namespaces/test-namespace/eventhubs/test"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest"
    }
  }

  mock_resource "azurerm_storage_container" {
    defaults = {
      resource_manager_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest/blobServices/default/containers/capture"
    }
  }
}

variables {
  enable_telemetry = false
}

run "default_example" {
  command = apply

  module {
    source = "./examples/default"
  }

  assert {
    condition     = module.event_hub.resource.auto_inflate_enabled && module.event_hub.resource.maximum_throughput_units == 20
    error_message = "The default example must enable auto-inflate with a maximum of 20."
  }
}

run "eventhub_example" {
  command = apply

  module {
    source = "./examples/eventhub"
  }

  assert {
    condition     = module.event_hub.resource.auto_inflate_enabled && module.event_hub.resource.maximum_throughput_units == 20
    error_message = "The event hub example must enable auto-inflate with a maximum of 20."
  }
}

run "capture_example" {
  command = apply

  module {
    source = "./examples/eventhub-capture"
  }

  assert {
    condition     = module.event_hub.resource.auto_inflate_enabled && module.event_hub.resource.maximum_throughput_units == 20
    error_message = "The capture example must enable auto-inflate with a maximum of 20."
  }

  assert {
    condition = (
      azurerm_role_assignment.this.scope == azurerm_storage_account.this.id &&
      azurerm_role_assignment.this.principal_id == data.azurerm_client_config.this.object_id &&
      azurerm_role_assignment.this.role_definition_name == "Storage Blob Data Contributor" &&
      one(module.event_hub.resource_eventhubs["eh_capture_example"].capture_description).enabled
    )
    error_message = "Capture must retain its enabled configuration and grant its caller storage-account-scoped blob access."
  }
}

run "existing_namespace_example" {
  command = apply

  module {
    source = "./examples/eventhub-with-existing-namespace"
  }

  assert {
    condition = (
      azurerm_eventhub_namespace.this.auto_inflate_enabled &&
      azurerm_eventhub_namespace.this.maximum_throughput_units == 20 &&
      azurerm_eventhub_namespace.this.minimum_tls_version == "1.2"
    )
    error_message = "The existing-namespace example must configure auto-inflate and TLS 1.2 on its directly created namespace."
  }
}

run "multiple_eventhubs_example" {
  command = apply

  module {
    source = "./examples/multiple-eventhubs"
  }

  assert {
    condition     = module.event_hub.resource.auto_inflate_enabled && module.event_hub.resource.maximum_throughput_units == 20
    error_message = "The multiple-event-hubs example must enable auto-inflate with a maximum of 20."
  }

  assert {
    condition = (
      azurerm_role_assignment.this.scope == azurerm_storage_account.this.id &&
      azurerm_role_assignment.this.principal_id == data.azurerm_client_config.this.object_id &&
      azurerm_role_assignment.this.role_definition_name == "Storage Blob Data Contributor" &&
      length(module.event_hub.resource_eventhubs) == 2 &&
      one(module.event_hub.resource_eventhubs["eh_capture_example"].capture_description).enabled
    )
    error_message = "The multiple-event-hubs example must retain both hubs and grant the Capture caller account-scoped blob access."
  }
}
