
# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  value       = try(azurerm_eventhub_namespace.this[0], data.azurerm_eventhub_namespace.this[0])
  description = "This is the full output for the resource."
  sensitive = true
}

output "private_endpoints" {
  value       = azurerm_private_endpoint.this
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
}
output "resource_eventhubs" {
  value       = azurerm_eventhub.this
  description = "A map of event hubs.  The map key is the supplied input to var.event_hubs. The map value is the entire azurerm_event_hubs resource."
}
