param location string = resourceGroup().location
param connection_name string

resource connection 'Microsoft.Web/connections@2016-06-01' = {
  name: connection_name
  location: location
  
  properties: {
    api: {    
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, connection_name)
    }
  }
}

output connection_id string = connection.id
