targetScope = 'subscription'

param location string
param resourceGroupName string
param approver_email string

var suffix = uniqueString(rg.id)
var storage_name = 'stor${suffix}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    location: rg.location
    storage_name: storage_name
  }
}

var connections = [
  'office365'
  'office365users'
  'office365groups'
]

module apiConnection 'modules/apiConnection.bicep' = [ for connection in connections: {
    name: 'apiConnection-${connection}'
    scope: rg
    params: {
      location: rg.location
      connection_name: connection
    }
  }]

  module apiConnection_storage 'modules/apiConnection-storage.bicep' = {
    name: 'apiConnection-storage'
    scope: rg
    params: {
      location: rg.location
      connection_name: 'azuretables'
      sharedkey: storage.outputs.storage_key
      storageaccount: storage_name
    }
  }

module workflow_main 'modules/workflow.bicep' = {
  name: 'logic-assign-roles'
  scope: rg
  params: {
    location: rg.location
    workflowName: 'logic-assign-roles'
    connections_azuretables_id: apiConnection_storage.outputs.connection_id
    connections_office365users_id: apiConnection[1].outputs.connection_id
    connections_office365groups_id: apiConnection[2].outputs.connection_id
    workflow_apply_id: workflow_apply.outputs.workflow_id
    workflow_approval_id: workflow_approval.outputs.workflow_id
    workflow_notify_id: workflow_notify.outputs.workflow_id
  }
}

module workflow_notify 'modules/workflow-notify.bicep' = {
  name: 'logic-assign-roles-notify'
  scope: rg
  params: {
    location: rg.location
    workflow_name: 'logic-assign-roles-notify'
    connection_office365_id: apiConnection[0].outputs.connection_id
  }
}

module workflow_remove 'modules/workflow-remove.bicep' = {
  name: 'logic-assign-roles-remove'
  scope: rg
  params: {
    location: rg.location
    workflowName: 'logic-assign-roles-remove'
  }
}

module workflow_apply 'modules/workflow-apply.bicep' = {
  name: 'logic-assign-roles-apply'
  scope: rg
  params: {
    location: rg.location
    workflow_name: 'logic-assign-roles-apply'
  }
}

module workflow_approval 'modules/workflow-approval.bicep' = {
  name: 'logic-assign-roles-approval'
  scope: rg
  params: {
    location: rg.location
    workflow_name: 'logic-assign-roles-approval'
    connection_office365_id: apiConnection[0].outputs.connection_id
    workflow_apply_id: workflow_apply.outputs.workflow_id
    workflow_notify_id: workflow_notify.outputs.workflow_id
    workflow_remove_id: workflow_remove.outputs.workflow_id
    approver_email: approver_email
  }
}

output workflow_url string = workflow_main.outputs.workflow_url
