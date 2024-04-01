param location string = resourceGroup().location
param workflowName string

resource workflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflowName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                roleAssignmentName: {
                  type: 'string'
                }
                subscriptionId: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Compose_Url: {
          runAfter: {
            Initialize_variable_Scope: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '${environment().resourceManager}@{variables(\'scope\')}/providers/Microsoft.Authorization/roleAssignments/@{triggerBody()?[\'roleAssignmentName\']}?api-version=2022-04-01'
        }
        HTTP: {
          runAfter: {
            Compose_Url: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            authentication: {
              type: 'ManagedServiceIdentity'
            }
            method: 'DELETE'
            uri: '@{outputs(\'Compose_Url\')}'
          }
        }
        Initialize_variable_Scope: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'scope'
                type: 'string'
                value: 'subscriptions/@{triggerBody()?[\'subscriptionId\']}'
              }
            ]
          }
        }
        Response_4: {
          runAfter: {
            HTTP: [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 200
          }
        }
        Scope_Catch: {
          actions: {
            Condition_3: {
              actions: {
                Response: {
                  runAfter: {}
                  type: 'Response'
                  kind: 'Http'
                  inputs: {
                    statusCode: 200
                  }
                }
                Terminate: {
                  runAfter: {
                    Response: [
                      'Succeeded'
                    ]
                  }
                  type: 'Terminate'
                  inputs: {
                    runStatus: 'Succeeded'
                  }
                }
              }
              runAfter: {
                Parse_JSON: [
                  'Succeeded'
                ]
              }
              else: {
                actions: {
                  Response_2: {
                    runAfter: {}
                    type: 'Response'
                    kind: 'Http'
                    inputs: {
                      statusCode: 400
                    }
                  }
                  Terminate_5: {
                    runAfter: {
                      Response_2: [
                        'Succeeded'
                      ]
                    }
                    type: 'Terminate'
                    inputs: {
                      runError: {
                        code: '@body(\'Parse_JSON\')?[\'error\']?[\'code\']'
                        message: '@body(\'Parse_JSON\')?[\'error\']?[\'message\']'
                      }
                      runStatus: 'Failed'
                    }
                  }
                }
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@body(\'Parse_JSON\')?[\'error\']?[\'code\']'
                      'RoleAssignmentExists'
                    ]
                  }
                ]
              }
              type: 'If'
            }
            Parse_JSON: {
              runAfter: {}
              type: 'ParseJson'
              inputs: {
                content: '@body(\'HTTP\')'
                schema: {
                  properties: {
                    error: {
                      properties: {
                        code: {
                          type: 'string'
                        }
                        message: {
                          type: 'string'
                        }
                      }
                      type: 'object'
                    }
                  }
                  type: 'object'
                }
              }
            }
          }
          runAfter: {
            HTTP: [
              'Failed'
            ]
          }
          type: 'Scope'
        }
      }
      outputs: {}
    }
    parameters: {}
  }
}

output workflow_id string = workflow.id
