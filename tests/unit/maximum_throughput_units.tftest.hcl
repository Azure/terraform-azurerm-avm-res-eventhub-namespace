mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  existing_parent_resource = {
    name = "test-namespace"
  }
  location            = "eastus"
  name                = "test-namespace"
  resource_group_name = "rg-test"
}

run "null_allowed" {
  command = apply

  variables {
    existing_parent_resource = null
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
}

run "one_allowed" {
  command = apply
  variables {
    auto_inflate_enabled     = true
    maximum_throughput_units = 1
  }
}

run "twenty_allowed" {
  command = apply
  variables {
    auto_inflate_enabled     = true
    maximum_throughput_units = 20
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
}
