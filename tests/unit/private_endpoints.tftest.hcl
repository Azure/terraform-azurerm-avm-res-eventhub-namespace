mock_provider "azapi" {
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          id        = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          role_name = "Reader"
        }]
      }
    }
  }
}

mock_provider "azurerm" {
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

  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateEndpoints/test-endpoint"
    }
  }
}

mock_provider "modtm" {}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "00000000-0000-0000-0000-000000000004"
    }
  }
}

variables {
  enable_telemetry    = false
  location            = "eastus"
  name                = "test-namespace"
  resource_group_name = "rg-test"
  private_endpoints = {
    test = {
      name                            = "custom-endpoint"
      subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
      subresource_name                = "custom-subresource"
      private_dns_zone_group_name     = "custom-dns"
      private_dns_zone_resource_ids   = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"]
      private_service_connection_name = "custom-connection"
      network_interface_name          = "custom-nic"
      location                        = "westus2"
      resource_group_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-private"
      tags                            = { environment = "test" }
      application_security_group_associations = {
        test = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/applicationSecurityGroups/test"
      }
      ip_configurations = {
        test = {
          name               = "custom-ip"
          private_ip_address = "10.0.0.4"
          member_name        = "custom-member"
        }
      }
      lock = {
        kind  = "ReadOnly"
        name  = "custom-lock"
        notes = "Protect the private endpoint."
      }
      role_assignments = {
        reader = {
          name                                   = "00000000-0000-0000-0000-000000000001"
          role_definition_id_or_name             = "Reader"
          principal_id                           = "00000000-0000-0000-0000-000000000002"
          principal_type                         = "ServicePrincipal"
          description                            = "Read the private endpoint."
          condition                              = "!(ActionMatches{'Microsoft.Network/privateEndpoints/delete'})"
          condition_version                      = "2.0"
          delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test"
        }
      }
    }
  }
}

run "no_private_endpoints" {
  command = apply

  variables {
    private_endpoints = {}
  }

  assert {
    condition = (
      length(output.private_endpoints) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0
    )
    error_message = "An empty endpoint map must not create endpoints, locks, or role assignments."
  }
}

run "managed_dns_defaults" {
  command = apply

  variables {
    private_endpoints = {
      test = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        ip_configurations = {
          test = {
            name               = "test-ip"
            private_ip_address = "10.0.0.4"
          }
        }
      }
    }
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this) == 1 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0 &&
      one(output.private_endpoints["test"].private_service_connection).subresource_names == tolist(["namespace"]) &&
      one(output.private_endpoints["test"].ip_configuration).member_name == "namespace" &&
      one(output.private_endpoints["test"].ip_configuration).subresource_name == "namespace" &&
      output.private_endpoints["test"].resource_group_name == "rg-test" &&
      length(output.private_endpoints["test"].private_dns_zone_group) == 0
    )
    error_message = "Omitted endpoint options must preserve namespace, resource-group, and managed-DNS defaults."
  }
}

run "unmanaged_dns_defaults" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      test = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        ip_configurations = {
          test = {
            name               = "test-ip"
            private_ip_address = "10.0.0.4"
          }
        }
      }
    }
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 1 &&
      one(output.private_endpoints["test"].private_service_connection).subresource_names == tolist(["namespace"]) &&
      one(output.private_endpoints["test"].ip_configuration).member_name == "namespace" &&
      one(output.private_endpoints["test"].ip_configuration).subresource_name == "namespace"
    )
    error_message = "Unmanaged DNS must preserve the same omitted subresource and member defaults as managed DNS."
  }
}

run "managed_dns_overrides" {
  command = apply

  assert {
    condition = (
      output.private_endpoints["test"].name == "custom-endpoint" &&
      output.private_endpoints["test"].location == "westus2" &&
      output.private_endpoints["test"].resource_group_name == "rg-private" &&
      output.private_endpoints["test"].custom_network_interface_name == "custom-nic" &&
      output.private_endpoints["test"].tags == tomap({ environment = "test" }) &&
      one(output.private_endpoints["test"].private_service_connection).name == "custom-connection" &&
      one(output.private_endpoints["test"].private_service_connection).subresource_names == tolist(["custom-subresource"]) &&
      one(output.private_endpoints["test"].ip_configuration).member_name == "custom-member" &&
      one(output.private_endpoints["test"].ip_configuration).subresource_name == "custom-subresource" &&
      one(output.private_endpoints["test"].private_dns_zone_group).name == "custom-dns" &&
      toset(one(output.private_endpoints["test"].private_dns_zone_group).private_dns_zone_ids) == var.private_endpoints["test"].private_dns_zone_resource_ids
    )
    error_message = "Endpoint overrides must reach the managed-DNS resource."
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_locks["test"].name == "custom-lock" &&
      azapi_resource.private_endpoint_locks["test"].body.properties.level == "ReadOnly" &&
      azapi_resource.private_endpoint_locks["test"].body.properties.notes == "Protect the private endpoint." &&
      azapi_resource.private_endpoint_locks["test"].parent_id == output.private_endpoints["test"].id &&
      azurerm_private_endpoint_application_security_group_association.this["test-test"].private_endpoint_id == output.private_endpoints["test"].id
    )
    error_message = "The lock, lock notes, and security-group association must target the created endpoint."
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_role_assignments["test-reader"].name == "00000000-0000-0000-0000-000000000001" &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].parent_id == output.private_endpoints["test"].id &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].body.properties.principalId == var.private_endpoints["test"].role_assignments["reader"].principal_id &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].body.properties.principalType == "ServicePrincipal" &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].body.properties.description == "Read the private endpoint." &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].body.properties.condition == var.private_endpoints["test"].role_assignments["reader"].condition &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].body.properties.conditionVersion == "2.0" &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].body.properties.delegatedManagedIdentityResourceId == var.private_endpoints["test"].role_assignments["reader"].delegated_managed_identity_resource_id
    )
    error_message = "Private-endpoint role assignments must preserve names, resolved roles, and optional properties."
  }
}

run "unmanaged_dns_existing_namespace" {
  command = apply

  variables {
    existing_parent_resource                = { name = "existing-namespace" }
    private_endpoints_manage_dns_zone_group = false
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 1 &&
      one(output.private_endpoints["test"].private_service_connection).private_connection_resource_id == data.azurerm_eventhub_namespace.this[0].id &&
      one(output.private_endpoints["test"].private_service_connection).subresource_names == tolist(["custom-subresource"]) &&
      one(output.private_endpoints["test"].ip_configuration).member_name == "custom-member" &&
      one(output.private_endpoints["test"].ip_configuration).subresource_name == "custom-subresource" &&
      azurerm_private_endpoint_application_security_group_association.this["test-test"].private_endpoint_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["test"].id &&
      azapi_resource.private_endpoint_locks["test"].parent_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["test"].id &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].parent_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["test"].id
    )
    error_message = "Unmanaged DNS must support existing namespaces and attach every extension to the selected endpoint."
  }
}

run "legacy_resource_group_name_and_generated_names" {
  command = apply

  variables {
    private_endpoints = {
      test = {
        subnet_resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        resource_group_name = "rg-legacy"
        lock                = { kind = "CanNotDelete" }
        role_assignments = {
          reader = {
            role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            principal_id               = "00000000-0000-0000-0000-000000000002"
          }
        }
      }
    }
  }

  assert {
    condition = (
      output.private_endpoints["test"].resource_group_name == "rg-legacy" &&
      azapi_resource.private_endpoint_locks["test"].name == "lock-CanNotDelete" &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].name == "00000000-0000-0000-0000-000000000004" &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].body.properties.roleDefinitionId == var.private_endpoints["test"].role_assignments["reader"].role_definition_id_or_name
    )
    error_message = "Legacy resource-group names, role definition IDs, and generated extension names must work."
  }
}

run "azapi_controls" {
  command = apply

  variables {
    resource_types = {
      authorization_locks            = "Microsoft.Authorization/locks@2016-09-01"
      authorization_role_assignments = "Microsoft.Authorization/roleAssignments@2020-04-01-preview"
    }
    ignore_body_changes = {
      authorization_locks            = ["properties.notes"]
      authorization_role_assignments = ["properties.description"]
    }
    retry = {
      error_message_regex  = ["ScopeLocked"]
      interval_seconds     = 2
      max_interval_seconds = 10
    }
    timeouts = {
      create = "10m"
      read   = "2m"
      update = "10m"
      delete = "5m"
    }
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_locks["test"].type == var.resource_types.authorization_locks &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].type == var.resource_types.authorization_role_assignments &&
      alltrue([
        for resource in concat(values(azapi_resource.private_endpoint_locks), values(azapi_resource.private_endpoint_role_assignments)) :
        resource.retry.error_message_regex == var.retry.error_message_regex &&
        resource.retry.interval_seconds == var.retry.interval_seconds &&
        resource.retry.max_interval_seconds == var.retry.max_interval_seconds &&
        resource.timeouts == var.timeouts
      ])
    )
    error_message = "Each private-endpoint extension must honor resource type, retry, and timeout overrides."
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_locks["test"].ignore_body_changes == null &&
      azapi_resource.private_endpoint_role_assignments["test-reader"].ignore_body_changes == null
    )
    error_message = "Configured ignored-body paths are write-only and must not appear in Terraform state."
  }
}

run "different_subscription_rejected" {
  command = plan

  variables {
    private_endpoints = {
      test = {
        subnet_resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        resource_group_name = "/subscriptions/00000000-0000-0000-0000-000000000099/resourceGroups/rg-private"
      }
    }
  }

  expect_failures = [azurerm_private_endpoint.this]
}

run "invalid_subnet_rejected" {
  command = plan

  variables {
    private_endpoints = {
      test = { subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/test" }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "invalid_dns_zone_rejected" {
  command = plan

  variables {
    private_endpoints = {
      test = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/dnsZones/example.com"]
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "invalid_security_group_rejected" {
  command = plan

  variables {
    private_endpoints = {
      test = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        application_security_group_associations = {
          test = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/networkSecurityGroups/test"
        }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "invalid_delegated_identity_rejected" {
  command = plan

  variables {
    private_endpoints = {
      test = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/test/subnets/private"
        role_assignments = {
          reader = {
            role_definition_id_or_name             = "Reader"
            principal_id                           = "00000000-0000-0000-0000-000000000002"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/test"
          }
        }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}
