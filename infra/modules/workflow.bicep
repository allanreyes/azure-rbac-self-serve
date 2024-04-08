param location string = resourceGroup().location
param workflowName string
param workflow_apply_id string
param workflow_notify_id string
param workflow_approval_id string
param workflow_getid_id string
param connections_azuretables_id string
param connections_office365users_id string

resource workflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflowName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
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
                reason: {
                  type: 'string'
                }
                requestedBy: {
                  type: 'string'
                }
                requestedFor: {
                  type: 'string'
                }
                role: {
                  type: 'string'
                }
                subscriptionId: {
                  type: 'string'
                }
                whatIf: {
                  type: 'boolean'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Condition_WhatIf: {
          actions: {}
          runAfter: {
            Scope_Preapproved: [
              'Succeeded'
            ]
            Scope_RequestedFor: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Condition_Preapproved: {
                actions: {
                  Compose: {
                    runAfter: {
                      'logic-assign-roles-apply': [
                        'Succeeded'
                      ]
                    }
                    type: 'Compose'
                    inputs: 'This is to notify you that the role \'@{triggerBody()?[\'role\']}\' has been granted to \'@{triggerBody()?[\'name\']}\' as requested by @{body(\'Get_user_profile_RequestedFor\')?[\'displayName\']}.'
                  }
                  'logic-assign-roles-apply': {
                    runAfter: {}
                    type: 'Workflow'
                    inputs: {
                      body: {
                        principalId: '@variables(\'PrincipalId\')'
                        roleDefinitionId: '@variables(\'RoleDefinitionId\')'
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
                      Compose: [
                        'Succeeded'
                      ]
                    }
                    type: 'Workflow'
                    inputs: {
                      body: {
                        body: '@{outputs(\'Compose\')}'
                        cc: '@triggerBody()?[\'requestedFor\']'
                        subject: 'Role \'@{triggerBody()?[\'role\']}\' has been granted to \'@{triggerBody()?[\'name\']}\''
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
                runAfter: {}
                else: {
                  actions: {
                    Compose_2: {
                      runAfter: {
                        'logic-assign-roles-infosec-approval': [
                          'Succeeded'
                        ]
                      }
                      type: 'Compose'
                      inputs: 'This is to notify you that we\'ve started the approval process for assigning the the role \'@{triggerBody()?[\'role\']}\' to the \'@{triggerBody()?[\'name\']}\' as requested by @{body(\'Get_user_profile_RequestedFor\')?[\'displayName\']}.'
                    }
                    'logic-assign-roles-infosec-approval': {
                      runAfter: {}
                      type: 'Workflow'
                      inputs: {
                        body: {
                          name: '@triggerBody()?[\'name\']'
                          prinicipalId: '@variables(\'PrincipalId\')'
                          reason: '@triggerBody()?[\'reason\']'
                          requestedBy: '@triggerBody()?[\'requestedBy\']'
                          requestedByName: '@body(\'Get_user_profile_RequestedBy\')?[\'displayName\']'
                          requestedFor: '@triggerBody()?[\'requestedFor\']'
                          requestedForName: '@body(\'Get_user_profile_RequestedFor\')?[\'displayName\']'
                          role: '@triggerBody()?[\'role\']'
                          roleDefinitionId: '@variables(\'RoleDefinitionId\')'
                          subscriptionId: '@triggerBody()?[\'subscriptionId\']'
                          subscriptionName: '@variables(\'SubscriptionName\')'
                        }
                        host: {
                          triggerName: 'manual'
                          workflow: {
                            id: workflow_approval_id
                          }
                        }
                      }
                    }
                    'logic-assign-roles-notify_2': {
                      runAfter: {
                        Compose_2: [
                          'Succeeded'
                        ]
                      }
                      type: 'Workflow'
                      inputs: {
                        body: {
                          body: '@{outputs(\'Compose_2\')}'
                          cc: '@triggerBody()?[\'requestedFor\']'
                          subject: 'Approval process for assigning role \'@{triggerBody()?[\'role\']}\' to \'@{triggerBody()?[\'name\']}\' has started'
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
                      equals: [
                        '@variables(\'IsPreapproved\')'
                        '@true'
                      ]
                    }
                  ]
                }
                type: 'If'
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@triggerBody()?[\'whatIf\']'
                  '@true'
                ]
              }
            ]
          }
          type: 'If'
        }
        Initialize_variable_IsPreapproved: {
          runAfter: {
            Initialize_variable_Scope: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'IsPreapproved'
                type: 'boolean'
                value: '@false'
              }
            ]
          }
        }
        Initialize_variable_PrincipalId: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'PrincipalId'
                type: 'string'
              }
            ]
          }
        }
        Initialize_variable_RoleDefinitionId: {
          runAfter: {
            Initialize_variable_PrincipalId: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'RoleDefinitionId'
                type: 'string'
              }
            ]
          }
        }
        Initialize_variable_Scope: {
          runAfter: {
            Initialize_variable_RoleDefinitionId: [
              'Succeeded'
            ]
          }
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
        Initialize_variable_SubscriptionName: {
          runAfter: {
            Initialize_variable_IsPreapproved: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'SubscriptionName'
                type: 'string'
              }
            ]
          }
        }
        Response_4: {
          runAfter: {
            Condition_WhatIf: [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            body: 'RoleDef: @{variables(\'RoleDefinitionId\')}\nId: @{variables(\'PrincipalId\')}\nPreapproved: @{variables(\'IsPreapproved\')}'
            statusCode: 200
          }
        }
        Scope_Name: {
          actions: {
            Response: {
              runAfter: {
                'logic-assign-roles-get-id': [
                  'Failed'
                ]
              }
              type: 'Response'
              kind: 'Http'
              inputs: {
                body: '@body(\'logic-assign-roles-get-id\')'
                statusCode: 400
              }
            }
            Set_variable_3: {
              runAfter: {
                'logic-assign-roles-get-id': [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
              inputs: {
                name: 'PrincipalId'
                value: '@{body(\'logic-assign-roles-get-id\')}'
              }
            }
            Terminate_2: {
              runAfter: {
                Response: [
                  'Succeeded'
                ]
              }
              type: 'Terminate'
              inputs: {
                runError: {
                  message: '@{body(\'logic-assign-roles-get-id\')}'
                }
                runStatus: 'Failed'
              }
            }
            'logic-assign-roles-get-id': {
              runAfter: {}
              type: 'Workflow'
              inputs: {
                body: {
                  name: '@triggerBody()?[\'name\']'
                }
                host: {
                  triggerName: 'manual'
                  workflow: {
                    id: workflow_getid_id
                  }
                }
              }
            }
          }
          runAfter: {
            Initialize_variable_SubscriptionName: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
        Scope_Preapproved: {
          actions: {
            Condition_IsPreapproved: {
              actions: {
                Set_variable_2: {
                  runAfter: {}
                  type: 'SetVariable'
                  inputs: {
                    name: 'IsPreapproved'
                    value: '@true'
                  }
                }
              }
              runAfter: {
                'Get_entities_(V2)': [
                  'Succeeded'
                ]
              }
              expression: {
                and: [
                  {
                    greater: [
                      '@length(outputs(\'Get_entities_(V2)\')?[\'body/value\'])'
                      0
                    ]
                  }
                ]
              }
              type: 'If'
            }
            'Get_entities_(V2)': {
              runAfter: {}
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'azuretables\'][\'connectionId\']'
                  }
                }
                method: 'get'
                path: '/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent(\'AccountNameFromSettings\'))}/tables/@{encodeURIComponent(\'preapproved\')}/entities'
                queries: {
                  '$filter': 'Name eq \'@{triggerBody()?[\'role\']}\''
                }
              }
            }
          }
          runAfter: {
            Scope_Role: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
        Scope_RequestedBy: {
          actions: {
            Condition_Requested_By_Error: {
              actions: {
                Response_Requested_By_Error: {
                  runAfter: {}
                  type: 'Response'
                  kind: 'Http'
                  inputs: {
                    body: 'Requested By User with Principal Id \'@{triggerBody()?[\'requestedBy\']}\' cannot be found.'
                    statusCode: 400
                  }
                }
              }
              runAfter: {
                Parse_JSON_Requested_By_Error: [
                  'Succeeded'
                ]
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@body(\'Parse_JSON_Requested_By_Error\')?[\'error\']?[\'code\']'
                      'Request_ResourceNotFound'
                    ]
                  }
                ]
              }
              type: 'If'
            }
            Get_user_profile_RequestedBy: {
              runAfter: {}
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'office365users\'][\'connectionId\']'
                  }
                }
                method: 'get'
                path: '/codeless/v1.0/users/@{encodeURIComponent(triggerBody()?[\'requestedBy\'])}'
                queries: {
                  '$select': 'displayName'
                }
              }
            }
            Parse_JSON_Requested_By_Error: {
              runAfter: {
                Get_user_profile_RequestedBy: [
                  'Failed'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'Get_user_profile_RequestedBy\')'
                schema: {
                  properties: {
                    error: {
                      properties: {
                        code: {
                          type: 'string'
                        }
                        innerError: {
                          properties: {
                            'client-request-id': {
                              type: 'string'
                            }
                            date: {
                              type: 'string'
                            }
                            'request-id': {
                              type: 'string'
                            }
                          }
                          type: 'object'
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
            Terminate: {
              runAfter: {
                Condition_Requested_By_Error: [
                  'Succeeded'
                ]
              }
              type: 'Terminate'
              inputs: {
                runError: {
                  code: '@body(\'Parse_JSON_Requested_By_Error\')?[\'error\']?[\'code\']'
                  message: '@body(\'Parse_JSON_Requested_By_Error\')?[\'error\']?[\'message\']'
                }
                runStatus: 'Failed'
              }
            }
          }
          runAfter: {
            Scope_Name: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
        Scope_RequestedFor: {
          actions: {
            Condition_Requested_For_Error: {
              actions: {
                Response_Requested_For_Error: {
                  runAfter: {}
                  type: 'Response'
                  kind: 'Http'
                  inputs: {
                    body: 'Requested For User with Principal Id \'@{triggerBody()?[\'requestedFor\']}\' cannot be found.'
                    statusCode: 400
                  }
                }
              }
              runAfter: {
                Parse_JSON_Requested_For_Error: [
                  'Succeeded'
                ]
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@body(\'Parse_JSON_Requested_For_Error\')?[\'error\']?[\'code\']'
                      'Request_ResourceNotFound'
                    ]
                  }
                ]
              }
              type: 'If'
            }
            Get_user_profile_RequestedFor: {
              runAfter: {}
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'office365users\'][\'connectionId\']'
                  }
                }
                method: 'get'
                path: '/codeless/v1.0/users/@{encodeURIComponent(triggerBody()?[\'requestedFor\'])}'
                queries: {
                  '$select': 'displayName'
                }
              }
            }
            Parse_JSON_Requested_For_Error: {
              runAfter: {
                Get_user_profile_RequestedFor: [
                  'Failed'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'Get_user_profile_RequestedFor\')'
                schema: {
                  properties: {
                    error: {
                      properties: {
                        code: {
                          type: 'string'
                        }
                        innerError: {
                          properties: {
                            'client-request-id': {
                              type: 'string'
                            }
                            date: {
                              type: 'string'
                            }
                            'request-id': {
                              type: 'string'
                            }
                          }
                          type: 'object'
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
            Terminate_5: {
              runAfter: {
                Condition_Requested_For_Error: [
                  'Succeeded'
                ]
              }
              type: 'Terminate'
              inputs: {
                runError: {
                  code: '@body(\'Parse_JSON_Requested_For_Error\')?[\'error\']?[\'code\']'
                  message: '@body(\'Parse_JSON_Requested_For_Error\')?[\'error\']?[\'message\']'
                }
                runStatus: 'Failed'
              }
            }
          }
          runAfter: {
            Scope_RequestedBy: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
        Scope_Role: {
          actions: {
            Condition_Role_found: {
              actions: {
                For_each_3: {
                  foreach: '@body(\'Parse_JSON\')?[\'value\']'
                  actions: {
                    Set_variable_RoleDefinitionId: {
                      runAfter: {}
                      type: 'SetVariable'
                      inputs: {
                        name: 'RoleDefinitionId'
                        value: '@items(\'For_each_3\')?[\'name\']'
                      }
                    }
                  }
                  runAfter: {}
                  type: 'Foreach'
                }
              }
              runAfter: {
                Parse_JSON: [
                  'Succeeded'
                ]
              }
              else: {
                actions: {
                  Response_3: {
                    runAfter: {}
                    type: 'Response'
                    kind: 'Http'
                    inputs: {
                      body: 'Role name \'@{triggerBody()?[\'role\']}\' not found'
                      statusCode: 400
                    }
                  }
                  Terminate_3: {
                    runAfter: {
                      Response_3: [
                        'Succeeded'
                      ]
                    }
                    type: 'Terminate'
                    inputs: {
                      runError: {
                        message: 'Invalid Role name'
                      }
                      runStatus: 'Failed'
                    }
                  }
                }
              }
              expression: {
                and: [
                  {
                    greater: [
                      '@length(body(\'Parse_JSON\')?[\'value\'])'
                      0
                    ]
                  }
                ]
              }
              type: 'If'
            }
            HTTP: {
              runAfter: {}
              type: 'Http'
              inputs: {
                authentication: {
                  type: 'ManagedServiceIdentity'
                }
                method: 'GET'
                uri: '${environment().resourceManager}@{variables(\'scope\')}/providers/Microsoft.Authorization/roleDefinitions?$filter=roleName eq \'@{triggerBody()?[\'role\']}\'&api-version=2022-04-01'
              }
            }
            Parse_JSON: {
              runAfter: {
                HTTP: [
                  'Succeeded'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'HTTP\')'
                schema: {
                  properties: {
                    value: {
                      items: {
                        properties: {
                          id: {
                            type: 'string'
                          }
                          name: {
                            type: 'string'
                          }
                          properties: {
                            properties: {
                              assignableScopes: {
                                items: {
                                  type: 'string'
                                }
                                type: 'array'
                              }
                              createdBy: {}
                              createdOn: {
                                type: 'string'
                              }
                              description: {
                                type: 'string'
                              }
                              permissions: {
                                items: {
                                  properties: {
                                    actions: {
                                      items: {
                                        type: 'string'
                                      }
                                      type: 'array'
                                    }
                                    dataActions: {
                                      type: 'array'
                                    }
                                    notActions: {
                                      items: {
                                        type: 'string'
                                      }
                                      type: 'array'
                                    }
                                    notDataActions: {
                                      type: 'array'
                                    }
                                  }
                                  required: [
                                    'actions'
                                    'notActions'
                                    'dataActions'
                                    'notDataActions'
                                  ]
                                  type: 'object'
                                }
                                type: 'array'
                              }
                              roleName: {
                                type: 'string'
                              }
                              type: {
                                type: 'string'
                              }
                              updatedBy: {}
                              updatedOn: {
                                type: 'string'
                              }
                            }
                            type: 'object'
                          }
                          type: {
                            type: 'string'
                          }
                        }
                        required: [
                          'properties'
                          'id'
                          'type'
                          'name'
                        ]
                        type: 'object'
                      }
                      type: 'array'
                    }
                  }
                  type: 'object'
                }
              }
            }
          }
          runAfter: {
            Scope_Subscription: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
        Scope_Subscription: {
          actions: {
            For_each: {
              foreach: '@body(\'Parse_JSON_2\')?[\'value\']'
              actions: {
                Set_variable: {
                  runAfter: {}
                  type: 'SetVariable'
                  inputs: {
                    name: 'SubscriptionName'
                    value: '@items(\'For_each\')?[\'displayName\']'
                  }
                }
              }
              runAfter: {
                Parse_JSON_2: [
                  'Succeeded'
                ]
              }
              type: 'Foreach'
            }
            HTTP_2: {
              runAfter: {}
              type: 'Http'
              inputs: {
                authentication: {
                  type: 'ManagedServiceIdentity'
                }
                method: 'GET'
                uri: '${environment().resourceManager}subscriptions?$filter=subscriptionId eq \'@{triggerBody()?[\'subscriptionId\']}\'&api-version=2016-06-01'
              }
            }
            Parse_JSON_2: {
              runAfter: {
                HTTP_2: [
                  'Succeeded'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'HTTP_2\')'
                schema: {
                  properties: {
                    value: {
                      items: {
                        properties: {
                          authorizationSource: {
                            type: 'string'
                          }
                          displayName: {
                            type: 'string'
                          }
                          id: {
                            type: 'string'
                          }
                          state: {
                            type: 'string'
                          }
                          subscriptionId: {
                            type: 'string'
                          }
                          subscriptionPolicies: {
                            properties: {
                              locationPlacementId: {
                                type: 'string'
                              }
                              quotaId: {
                                type: 'string'
                              }
                              spendingLimit: {
                                type: 'string'
                              }
                            }
                            type: 'object'
                          }
                        }
                        required: [
                          'id'
                          'authorizationSource'
                          'subscriptionId'
                          'displayName'
                          'state'
                          'subscriptionPolicies'
                        ]
                        type: 'object'
                      }
                      type: 'array'
                    }
                  }
                  type: 'object'
                }
              }
            }
            Response_5: {
              runAfter: {
                HTTP_2: [
                  'Failed'
                ]
              }
              type: 'Response'
              kind: 'Http'
              inputs: {
                body: 'Subscription with Id \'@{triggerBody()?[\'subscriptionId\']}\' not found or is out of scope of this automation'
                statusCode: 400
              }
            }
            Terminate_4: {
              runAfter: {
                Response_5: [
                  'Succeeded'
                ]
              }
              type: 'Terminate'
              inputs: {
                runError: {
                  code: '@{body(\'HTTP_2\')?[\'code\']}'
                  message: '@{body(\'HTTP_2\')?[\'error/message\']}'
                }
                runStatus: 'Failed'
              }
            }
          }
          runAfter: {
            Initialize_variable_SubscriptionName: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azuretables: {
            connectionId: connections_azuretables_id
            connectionName: 'azuretables'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuretables')
          }
          office365users: {
            connectionId: connections_office365users_id
            connectionName: 'office365users'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365users')
          }
        }
      }
    }
  }
}

output workflow_id string = workflow.id
var workflow_url = workflow.listCallbackUrl().value
output workflow_url string = workflow_url
