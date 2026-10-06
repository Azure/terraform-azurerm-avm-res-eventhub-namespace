locals {
  event_hub_namespace_resource_id = var.existing_parent_resource == null ? azurerm_eventhub_namespace.this[0].id : data.azurerm_eventhub_namespace.this[0].id
  event_hub_role_assignments = { for ra in flatten([
    for sk, sv in var.event_hubs : [
      for rk, rv in sv.role_assignments : {
        event_hub_key   = sk
        ra_key          = rk
        role_assignment = rv
      }
    ]
  ]) : "${ra.event_hub_key}-${ra.ra_key}" => ra }
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
  private_endpoint_resource_groups = {
    for key, endpoint in var.private_endpoints : key => try(
      provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", endpoint.resource_group_name),
      null
    )
  }
  private_endpoint_resource_group_names = {
    for key, endpoint in var.private_endpoints : key => endpoint.resource_group_name == null ? var.resource_group_name : try(
      local.private_endpoint_resource_groups[key].name,
      endpoint.resource_group_name
    )
  }
  private_endpoint_resource_group_subscription_matches = {
    for key, group in local.private_endpoint_resource_groups : key => group == null ? true : lower(group.subscription_id) == lower(provider::azapi::parse_resource_id("Microsoft.EventHub/namespaces", local.event_hub_namespace_resource_id).subscription_id)
  }
  private_endpoints                  = merge(azurerm_private_endpoint.this, azurerm_private_endpoint.this_unmanaged_dns_zone_groups)
  resource_group_location            = try(data.azurerm_resource_group.parent[0].location, null)
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
