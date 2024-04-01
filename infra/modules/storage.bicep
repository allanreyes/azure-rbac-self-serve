param location string = resourceGroup().location
param storage_name string

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storage_name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storage_table_service 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

resource storage_table_preapproved 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-01-01' = {
  parent: storage_table_service
  name: 'preapproved'  
}

var storage_key = storage.listKeys().keys[0].value
output storage_key string = storage_key
