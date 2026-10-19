mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {}

mock_provider "random" {}

variables {
  enable_telemetry    = false
  location            = "eastus"
  name                = "test-namespace"
  resource_group_name = "rg-test"
}

run "null_allowed" {
  command = apply

  assert {
    condition     = !azurerm_eventhub_namespace.this[0].auto_inflate_enabled && var.maximum_throughput_units == null
    error_message = "The default namespace must retain disabled auto-inflate and a null maximum."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}

run "zero_rejected" {
  command = plan
  variables {
    auto_inflate_enabled     = true
    maximum_throughput_units = 0
  }
  expect_failures = [
    var.maximum_throughput_units
  ]
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}

run "one_allowed" {
  command = apply
  variables {
    auto_inflate_enabled     = true
    maximum_throughput_units = 1
  }

  assert {
    condition     = azurerm_eventhub_namespace.this[0].auto_inflate_enabled && azurerm_eventhub_namespace.this[0].maximum_throughput_units == 1
    error_message = "Namespace creation must support auto-inflate with a maximum of 1."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}

run "twenty_allowed" {
  command = apply
  variables {
    auto_inflate_enabled     = true
    maximum_throughput_units = 20
  }

  assert {
    condition     = azurerm_eventhub_namespace.this[0].auto_inflate_enabled && azurerm_eventhub_namespace.this[0].maximum_throughput_units == 20
    error_message = "Namespace creation must support auto-inflate with a maximum of 20."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}

run "twentyone_rejected" {
  command = plan
  variables {
    auto_inflate_enabled     = true
    maximum_throughput_units = 21
  }

  expect_failures = [
    var.maximum_throughput_units
  ]
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}

run "maximum_without_auto_inflate_rejected" {
  command = plan

  variables {
    auto_inflate_enabled     = false
    maximum_throughput_units = 1
  }

  expect_failures = [azurerm_eventhub_namespace.this]
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}

run "auto_inflate_without_maximum_rejected" {
  command = plan

  variables {
    auto_inflate_enabled     = true
    maximum_throughput_units = null
  }

  expect_failures = [azurerm_eventhub_namespace.this]
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
  }
}
