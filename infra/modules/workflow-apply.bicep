param location string = resourceGroup().location
param workflow_name string

resource workflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflow_name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
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
                principalId: {
                  type: 'string'
                }
                roleDefinitionId: {
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
        Compose_Body: {
          runAfter: {
            Compose_Url: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: {
            properties: {
              principalId: '@{triggerBody()?[\'principalId\']}'
              roleDefinitionId: '/@{variables(\'scope\')}/providers/Microsoft.Authorization/roleDefinitions/@{triggerBody()?[\'roleDefinitionId\']}'
            }
          }
        }
        Compose_Url: {
          runAfter: {
            Initialize_variable: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '${environment().resourceManager}@{variables(\'scope\')}/providers/Microsoft.Authorization/roleAssignments/@{variables(\'RoleAssignmentName\')}?api-version=2022-04-01'
        }
        HTTP: {
          runAfter: {
            Compose_Body: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            authentication: {
              type: 'ManagedServiceIdentity'
            }
            body: '@outputs(\'Compose_Body\')'
            method: 'PUT'
            uri: '@{outputs(\'Compose_Url\')}'
          }
        }
        Initialize_variable: {
          runAfter: {
            Initialize_variable_Scope: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'RoleAssignmentName'
                type: 'string'
                value: '@{guid()}'
              }
            ]
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
            body: '@variables(\'RoleAssignmentName\')'
            statusCode: 201
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
                    body: '@variables(\'RoleAssignmentName\')'
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
