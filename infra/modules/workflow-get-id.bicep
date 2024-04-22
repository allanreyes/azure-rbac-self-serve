param location string = resourceGroup().location
param workflow_name string
param connections_office365groups_id string
param connections_webcontents_id string

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
                name: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Condition: {
          actions: {
            Response_2: {
              runAfter: {}
              type: 'Response'
              kind: 'Http'
              inputs: {
                body: 'A group and a service principal with the same name (@{triggerBody()?[\'name\']}) exists, please contact CCOE for additional support.'
                statusCode: 400
              }
            }
            Terminate: {
              runAfter: {
                Response_2: [
                  'Succeeded'
                ]
              }
              type: 'Terminate'
              inputs: {
                runError: {
                  message: 'More than 1 record found'
                }
                runStatus: 'Failed'
              }
            }
          }
          runAfter: {
            For_each: [
              'Succeeded'
            ]
            For_each_2: [
              'Succeeded'
            ]
          }
          expression: {
            and: [
              {
                greater: [
                  '@length(body(\'Parse_JSON\')?[\'value\'])'
                  0
                ]
              }
              {
                greater: [
                  '@length(body(\'List_groups\')?[\'value\'])'
                  0
                ]
              }
            ]
          }
          type: 'If'
          description: 'Name exists as a group and as an app registation'
        }
        Condition_2: {
          actions: {
            Response_3: {
              runAfter: {}
              type: 'Response'
              kind: 'Http'
              inputs: {
                body: 'More than one service principal with the same name (@{triggerBody()?[\'name\']}) exists, please contact CCOE for additional support.'
                statusCode: 400
              }
            }
            Terminate_2: {
              runAfter: {
                Response_3: [
                  'Succeeded'
                ]
              }
              type: 'Terminate'
              inputs: {
                runError: {
                  message: 'More than one service principal with the same name'
                }
                runStatus: 'Failed'
              }
            }
          }
          runAfter: {
            Parse_JSON: [
              'Succeeded'
            ]
          }
          expression: {
            and: [
              {
                greater: [
                  '@length(body(\'Parse_JSON\')?[\'value\'])'
                  1
                ]
              }
            ]
          }
          type: 'If'
          description: 'There\'s more than 1 app registration with the same name'
        }
        Condition_3: {
          actions: {
            Response_4: {
              runAfter: {}
              type: 'Response'
              kind: 'Http'
              inputs: {
                body: 'A group or a service principal with the name (@{triggerBody()?[\'name\']}) cannot be found, please contact CCOE for additional support.'
                statusCode: 400
              }
            }
            Terminate_3: {
              runAfter: {
                Response_4: [
                  'Succeeded'
                ]
              }
              type: 'Terminate'
              inputs: {
                runError: {
                  message: 'No records found'
                }
                runStatus: 'Failed'
              }
            }
          }
          runAfter: {
            Condition: [
              'Succeeded'
            ]
          }
          expression: {
            and: [
              {
                equals: [
                  '@length(body(\'Parse_JSON\')?[\'value\'])'
                  0
                ]
              }
              {
                equals: [
                  '@length(body(\'List_groups\')?[\'value\'])'
                  0
                ]
              }
            ]
          }
          type: 'If'
        }
        For_each: {
          foreach: '@body(\'Parse_JSON\')?[\'value\']'
          actions: {
            Set_variable: {
              runAfter: {}
              type: 'SetVariable'
              inputs: {
                name: 'Id'
                value: '@items(\'For_each\')?[\'id\']'
              }
            }
          }
          runAfter: {
            Condition_2: [
              'Succeeded'
            ]
          }
          type: 'Foreach'
        }
        For_each_2: {
          foreach: '@body(\'List_groups\')?[\'value\']'
          actions: {
            Set_variable_2: {
              runAfter: {}
              type: 'SetVariable'
              inputs: {
                name: 'Id'
                value: '@items(\'For_each_2\')?[\'id\']'
              }
            }
          }
          runAfter: {
            List_groups: [
              'Succeeded'
            ]
          }
          type: 'Foreach'
        }
        Initialize_variable_Id: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'Id'
                type: 'string'
              }
            ]
          }
        }
        Invoke_an_HTTP_request: {
          runAfter: {
            Initialize_variable_Id: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              method: 'GET'
              url: 'https://graph.microsoft.com/v1.0/servicePrincipals?$filter=displayName eq \'@{triggerBody()?[\'name\']}\''
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'webcontents\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/codeless/InvokeHttp'
          }
        }
        List_groups: {
          runAfter: {
            Initialize_variable_Id: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365groups\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v1.0/groups'
            queries: {
              '$filter': 'displayName eq \'@{triggerBody()?[\'name\']}\''
            }
          }
        }
        Parse_JSON: {
          runAfter: {
            Invoke_an_HTTP_request: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Invoke_an_HTTP_request\')'
            schema: {
              properties: {
                '@@odata.context': {
                  type: 'string'
                }
                value: {
                  items: {
                    properties: {
                      displayName: {
                        type: 'string'
                      }
                      id: {
                        type: 'string'
                      }
                    }
                    type: 'object'
                  }
                  type: 'array'
                }
              }
              type: 'object'
            }
          }
        }
        Response: {
          runAfter: {
            Condition: [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            body: '@variables(\'Id\')'
            statusCode: 200
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          office365groups: {
            connectionId: connections_office365groups_id
            connectionName: 'office365groups'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365groups')
          }
          webcontents: {
            connectionId: connections_webcontents_id
            connectionName: 'webcontents'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'webcontents')
          }
        }
      }
    }
  }
}

output workflow_id string = workflow.id
