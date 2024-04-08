param location string = resourceGroup().location
param workflow_name string
param connection_office365_id string

resource workflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflow_name
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                body: {
                  type: 'string'
                }
                cc: {
                  type: 'string'
                }
                subject: {
                  type: 'string'
                }
                to: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Compose: {
          runAfter: {}
          type: 'Compose'
          inputs: '@triggerBody()?[\'body\']'
        }
        Response_4: {
          runAfter: {
            'Send_an_email_(V2)': [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 200
          }
        }
        'Send_an_email_(V2)': {
          runAfter: {
            Compose: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              Body: '@{outputs(\'Compose\')}'
              Cc: '@triggerBody()?[\'cc\']'
              Importance: 'Normal'
              Subject: '@triggerBody()?[\'subject\']'
              To: '@triggerBody()?[\'to\']'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/Mail'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          office365: {
            connectionId: connection_office365_id
            connectionName: 'office365'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
          }
        }
      }
    }
  }
}

output workflow_id string = workflow.id
