# Two event hubs with role assignments

This deploys two example event hubs, illustrating role assignments.

The deployment identity needs `Storage Blob Data Contributor` at storage-account scope to enable Capture; container-scoped access is insufficient. This example creates that assignment before the event hubs. See [Capture storage permissions](https://learn.microsoft.com/azure/event-hubs/event-hubs-capture-overview#azure-storage-account-as-a-destination).
