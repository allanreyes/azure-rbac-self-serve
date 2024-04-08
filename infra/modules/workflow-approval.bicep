param location string = resourceGroup().location
param workflow_name string
param connection_office365_id string
param workflow_apply_id string
param workflow_notify_id string
param workflow_remove_id string
param approver_email string

resource workflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflow_name
  location: location
  properties: {
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
                prinicipalId: {
                  type: 'string'
                }
                reason: {
                  type: 'string'
                }
                requestedBy: {
                  type: 'string'
                }
                requestedByName: {
                  type: 'string'
                }
                requestedFor: {
                  type: 'string'
                }
                requestedForName: {
                  type: 'string'
                }
                role: {
                  type: 'string'
                }
                roleDefinitionId: {
                  type: 'string'
                }
                subscriptionId: {
                  type: 'string'
                }
                subscriptionName: {
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
          runAfter: {
            Response: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: 'The user @{triggerBody()?[\'requestedFor\']} (@{triggerBody()?[\'requestedForName\']}) is requesting the following permission to a subscription:\n\n<br/><br/>\n\nRole: @{triggerBody()?[\'role\']}<br/>\nSubscription Name: @{triggerBody()?[\'subscriptionName\']}  <br/>\nSubscription Id: @{triggerBody()?[\'subscriptionId\']} <br/>\nReason: @{triggerBody()?[\'reason\']}<br/>\n\n<br/>\nThanks,<br/>\n@{triggerBody()?[\'requestedByName\']} <br/>\n@{triggerBody()?[\'requestedBy\']}<br/>\n(on behalf of CCOE Team)'
        }
        Condition: {
          actions: {
            Delay: {
              runAfter: {
                Switch: [
                  'Succeeded'
                ]
              }
              type: 'Wait'
              inputs: {
                interval: {
                  count: '@variables(\'Duration\')'
                  unit: 'Minute'
                }
              }
              description: 'TODO: Change to Days'
            }
            Switch: {
              runAfter: {
                'logic-assign-roles-notify': [
                  'Succeeded'
                ]
              }
              cases: {
                Case: {
                  case: 'Approve for 7 days'
                  actions: {
                    Set_variable: {
                      runAfter: {}
                      type: 'SetVariable'
                      inputs: {
                        name: 'Duration'
                        value: 7
                      }
                    }
                  }
                }
                Case_2: {
                  case: 'Approve for 14 days'
                  actions: {
                    Set_variable_2: {
                      runAfter: {}
                      type: 'SetVariable'
                      inputs: {
                        name: 'Duration'
                        value: 14
                      }
                    }
                  }
                }
              }
              default: {
                actions: {
                  Terminate: {
                    runAfter: {}
                    type: 'Terminate'
                    inputs: {
                      runStatus: 'Succeeded'
                    }
                  }
                }
              }
              expression: '@body(\'Send_email_with_options\')?[\'SelectedOption\']'
              type: 'Switch'
            }
            'logic-assign-roles-apply': {
              runAfter: {}
              type: 'Workflow'
              inputs: {
                body: {
                  principalId: '@triggerBody()?[\'prinicipalId\']'
                  roleDefinitionId: '@triggerBody()?[\'roleDefinitionId\']'
                  subscriptionId: '@triggerBody()?[\'subscriptionId\']'
                }
                host: {
                  triggerName: 'manual'
                  workflow: {
                    id: workflow_apply_id
                  }
                }
              }
            }
            'logic-assign-roles-notify': {
              runAfter: {
                'logic-assign-roles-apply': [
                  'Succeeded'
                ]
              }
              type: 'Workflow'
              inputs: {
                body: {
                  body: '@variables(\'Message\')'
                  cc: '@triggerBody()?[\'requestedFor\']'
                  subject: 'APPROVED: Role \'@{triggerBody()?[\'role\']}\' has been granted to \'@{triggerBody()?[\'name\']}\''
                  to: '@triggerBody()?[\'requestedBy\']'
                }
                host: {
                  triggerName: 'manual'
                  workflow: {
                    id: workflow_notify_id
                  }
                }
              }
            }
            'logic-assign-roles-notify_removed': {
              runAfter: {
                'logic-assign-roles-remove': [
                  'Succeeded'
                ]
              }
              type: 'Workflow'
              inputs: {
                body: {
                  body: 'This is to notify you that the role \'@{triggerBody()?[\'role\']}\' previously assigned to \'@{triggerBody()?[\'name\']}\' as requested by @{triggerBody()?[\'requestedByName\']}, has been removed according to the original approved duration of @{string(variables(\'Duration\'))} days.'
                  subject: 'Role \'@{triggerBody()?[\'role\']}\' assigned to \'@{triggerBody()?[\'name\']}\' has been removed according to approved duration'
                  to: '@triggerBody()?[\'requestedFor\']'
                }
                host: {
                  triggerName: 'manual'
                  workflow: {
                    id: workflow_notify_id
                  }
                }
              }
            }
            'logic-assign-roles-remove': {
              runAfter: {
                Delay: [
                  'Succeeded'
                ]
              }
              type: 'Workflow'
              inputs: {
                body: {
                  roleAssignmentName: '@{body(\'logic-assign-roles-apply\')}'
                  subscriptionId: '@triggerBody()?[\'subscriptionId\']'
                }
                host: {
                  triggerName: 'manual'
                  workflow: {
                    id: workflow_remove_id
                  }
                }
              }
            }
          }
          runAfter: {
            Switch_2: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              'logic-assign-roles-notify_2': {
                runAfter: {}
                type: 'Workflow'
                inputs: {
                  body: {
                    body: '@variables(\'Message\')'
                    cc: '@triggerBody()?[\'requestedFor\']'
                    subject: 'DENIED: Role \'@{triggerBody()?[\'role\']}\' cannot be assigned to \'@{triggerBody()?[\'name\']}\''
                    to: '@triggerBody()?[\'requestedBy\']'
                  }
                  host: {
                    triggerName: 'manual'
                    workflow: {
                      id: workflow_notify_id
                    }
                  }
                }
              }
            }
          }
          expression: {
            and: [
              {
                startsWith: [
                  '@body(\'Send_email_with_options\')?[\'SelectedOption\']'
                  'Approve'
                ]
              }
            ]
          }
          type: 'If'
        }
        Initialize_variable_Duration: {
          runAfter: {
            Initialize_variable_Message: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'Duration'
                type: 'integer'
              }
            ]
          }
        }
        Initialize_variable_Message: {
          runAfter: {
            Compose: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'Message'
                type: 'string'
              }
            ]
          }
        }
        Response: {
          runAfter: {}
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 201
          }
        }
        Send_email_with_options: {
          runAfter: {
            Initialize_variable_Duration: [
              'Succeeded'
            ]
          }
          type: 'ApiConnectionWebhook'
          inputs: {
            body: {
              Message: {
                Body: '@{outputs(\'Compose\')}'
                HeaderText: 'Role Assignment Request: @{triggerBody()?[\'role\']}'
                HideHTMLMessage: false
                HideMicrosoftFooter: true
                Importance: 'Normal'
                Options: 'Approve for 7 days, Approve for 14 days, Approve indefinitely, Deny'
                ShowHTMLConfirmationDialog: true
                Subject: 'Role Assignment Request'
                To: approver_email
                UseOnlyHTMLMessage: true
              }
              NotificationUrl: '@{listCallbackUrl()}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            path: '/mailwithoptions/$subscriptions'
          }
        }
        Switch_2: {
          runAfter: {
            Send_email_with_options: [
              'Succeeded'
            ]
          }
          cases: {
            Case: {
              case: 'Approve for 7 days'
              actions: {
                Set_variable_3: {
                  runAfter: {}
                  type: 'SetVariable'
                  inputs: {
                    name: 'Message'
                    value: 'This is to notify you that your request has been Approved for 7 days and the role \'@{triggerBody()?[\'role\']}\' has been granted to \'@{triggerBody()?[\'name\']}\' as requested by @{triggerBody()?[\'requestedByName\']}.'
                  }
                }
              }
            }
            Case_2: {
              case: 'Approve for 14 days'
              actions: {
                Set_variable_4: {
                  runAfter: {}
                  type: 'SetVariable'
                  inputs: {
                    name: 'Message'
                    value: 'This is to notify you that your request has been Approved for 14 days and the role \'@{triggerBody()?[\'role\']}\' has been granted to \'@{triggerBody()?[\'name\']}\' as requested by @{triggerBody()?[\'requestedByName\']}.'
                  }
                }
              }
            }
            Case_3: {
              case: 'Approve indefinitely'
              actions: {
                Set_variable_5: {
                  runAfter: {}
                  type: 'SetVariable'
                  inputs: {
                    name: 'Message'
                    value: 'This is to notify you that your request has been Approved and the role \'@{triggerBody()?[\'role\']}\' has been granted to \'@{triggerBody()?[\'name\']}\' as requested by @{triggerBody()?[\'requestedByName\']}.'
                  }
                }
              }
            }
          }
          default: {
            actions: {
              Set_variable_6: {
                runAfter: {}
                type: 'SetVariable'
                inputs: {
                  name: 'Message'
                  value: 'This is to notify you that your request is Denied and the role \'@{triggerBody()?[\'role\']}\' cannot be granted to \'@{triggerBody()?[\'name\']}\' as requested by @{triggerBody()?[\'requestedByName\']}.'
                }
              }
            }
          }
          expression: '@body(\'Send_email_with_options\')?[\'SelectedOption\']'
          type: 'Switch'
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
