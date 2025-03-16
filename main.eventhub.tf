resource "azurerm_eventhub" "this" {
  for_each = var.event_hubs

  message_retention   = each.value.message_retention
  name                = each.key
  partition_count     = each.value.partition_count
  namespace_name      = try(data.azurerm_eventhub_namespace.this[0].name, azurerm_eventhub_namespace.this[0].name)
  resource_group_name = var.resource_group_name
  status              = each.value.status

  dynamic "capture_description" {
    for_each = each.value.capture_description != null ? { this = each.value.capture_description } : {}

    content {
      enabled             = each.value.capture_description.enabled
      encoding            = each.value.capture_description.encoding
      interval_in_seconds = each.value.capture_description.interval_in_seconds
      size_limit_in_bytes = each.value.capture_description.size_limit_in_bytes
      skip_empty_archives = each.value.capture_description.skip_empty_archives

      destination {
        archive_name_format = each.value.capture_description.destination.archive_name_format
        blob_container_name = each.value.capture_description.destination.blob_container_name
        name                = each.value.capture_description.destination.name
        storage_account_id  = each.value.capture_description.destination.storage_account_id
      }
    }
  }
}

resource "azurerm_role_assignment" "event_hubs" {
  for_each = local.event_hub_role_assignments

  principal_id                           = each.value.role_assignment.principal_id
  scope                                  = azurerm_eventhub.this[each.value.event_hub_key].id
  condition                              = each.value.role_assignment.condition
  condition_version                      = each.value.role_assignment.condition_version
  delegated_managed_identity_resource_id = each.value.role_assignment.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_assignment.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_assignment.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.role_assignment.skip_service_principal_aad_check
}

