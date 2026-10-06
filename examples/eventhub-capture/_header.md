# Default example

This deploys a single example event hub, with event hub capture enabled.

The deployment identity needs `Storage Blob Data Contributor` at storage-account scope to enable Capture; container-scoped access is insufficient. This example creates that assignment before the event hub. See [Capture storage permissions](https://learn.microsoft.com/azure/event-hubs/event-hubs-capture-overview#azure-storage-account-as-a-destination).
