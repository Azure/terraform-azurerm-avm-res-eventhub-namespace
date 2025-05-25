variable "event_hubs" {
  type = map(object({
    namespace_name      = string
    resource_group_name = string
    partition_count     = number
    message_retention   = number
    capture_description = optional(object({
      enabled             = bool
      encoding            = string
      interval_in_seconds = optional(number)
      size_limit_in_bytes = optional(number)
      skip_empty_archives = optional(bool)
      destination = object({
        name                = optional(string, "EventHubArchive.AzureBlockBlob")
        archive_name_format = string
        blob_container_name = string
        storage_account_id  = string
      })
    }))
    status = optional(string)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
Map of Azure Event Hubs configurations.

- `name` - (Required) Specifies the name of the Event Hub resource. Changing this forces a new resource to be created.
- `namespace_name` - (Required) Specifies the name of the Event Hub Namespace. Changing this forces a new resource to be created.
- `resource_group_name` - (Required) The name of the resource group in which the Event Hub's parent Namespace exists. Changing this forces a new resource to be created.
- `partition_count` - (Required) Specifies the current number of shards on the Event Hub. Cannot be changed unless Event Hub Namespace SKU is Premium and cannot be decreased. Defaults to 1.
  - Note: When using a dedicated Event Hubs cluster, the maximum value of partition_count is 1024. When using a shared parent EventHub Namespace, the maximum value is 32.
- `message_retention` - (Required) Specifies the number of days to retain the events for this Event Hub. Defaults to 7 days for shared parent EventHub Namespace with Basic SKU, 1 day for others.
  - Note: When using a dedicated Event Hubs cluster, the maximum value of message_retention is 90 days. When using a shared parent EventHub Namespace, the maximum value is 7 days; or 1 day when using a Basic SKU for the shared parent EventHub Namespace.
- `capture_description` - (Optional) A capture_description block as defined below.
  - `enabled` - (Required) Specifies if the Capture Description is Enabled.
  - `encoding` - (Required) Specifies the Encoding used for the Capture Description. Possible values are Avro and AvroDeflate.
  - `interval_in_seconds` - (Optional) Specifies the time interval in seconds at which the capture will happen. Values can be between 60 and 900 seconds. Defaults to 300 seconds.
  - `size_limit_in_bytes` - (Optional) Specifies the amount of data built up in your EventHub before a Capture Operation occurs. Value should be between 10485760 and 524288000 bytes. Defaults to 314572800 bytes.
  - `skip_empty_archives` - (Optional) Specifies if empty files should not be emitted if no events occur during the Capture time window. Defaults to false.
  - `destination` - (Required) A destination block as defined below.
    - `name` - (Required) The Name of the Destination where the capture should take place. At this time, the only supported value is EventHubArchive.AzureBlockBlob.
      - Note: At this time, it's only possible to Capture EventHub messages to Blob Storage.
    - `archive_name_format` - (Required) The Blob naming convention for archiving. e.g. {Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}. Here, all the parameters (Namespace, EventHub, etc.) are mandatory irrespective of order.
    - `blob_container_name` - (Required) The name of the Container within the Blob Storage Account where messages should be archived.
    - `storage_account_id` - (Required) The ID of the Blob Storage Account where messages should be archived.
- `status` - (Optional) Specifies the status of the Event Hub resource. Possible values are Active, Disabled, and SendDisabled. Defaults to Active.
- `role_assignments` - (Optional) RBAC permissions applied to the event hub resource.
DESCRIPTION 

  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.capture_description == null ? true : contains(["Avro", "AvroDeflate"], config.capture_description.encoding)
      )
    ])
    error_message = "Invalid encoding value for Event Hub capture encoding. Allowed values are Avro and AvroDeflate."
  }
  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.capture_description == null ? true : config.capture_description.size_limit_in_bytes == null ? true : config.capture_description.size_limit_in_bytes >= 314572800 && config.capture_description.size_limit_in_bytes <= 524288000
      )
    ])
    error_message = "Invalid size_limit_in_bytes value.  If specified, it must be between 10485760 and 524288000 bytes."
  }
  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.capture_description == null ? true : config.capture_description.interval_in_seconds == null ? true : config.capture_description.interval_in_seconds <= 900 && config.capture_description.interval_in_seconds >= 60
      )
    ])
    error_message = "Invalid interval_in_seconds value.  If specified, it must be between 60 and 900 seconds."
  }
  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.capture_description == null ? true : config.capture_description.destination.name == null ? true : config.capture_description.destination.name == "EventHubArchive.AzureBlockBlob"
      )
    ])
    error_message = "Invalid capture destination. At this time, only EventHubArchive.AzureBlockBlob is supported."
  }
  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.status == null ? true : contains(["Active", "Disabled", "SendDisabled"], config.status)
      )
    ])
    error_message = "Invalid status value. If supplied, possible values are Active, Disabled, and SendDisabled."
  }
}
