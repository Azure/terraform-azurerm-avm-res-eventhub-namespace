# terraform-azurerm-avm-eventhub-namespace

This is a Terraform AVM module for Event Hub resources in Azure.

Private endpoints default to the `namespace` subresource. Their `resource_group_name` override accepts a resource-group ID in the provider's subscription or a legacy resource-group name. Configured private-endpoint locks and role assignments are created with AzAPI.

> [!WARNING]
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>
