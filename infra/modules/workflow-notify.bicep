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
                objectName: {
                  type: 'string'
                }
                roleName: {
                  type: 'string'
                }
                subject: {
                  type: 'string'
                }
                subscriptionName: {
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
          runAfter: {
            Initialize_variable_Logo: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '<div\n  style="\n    background-color: #e3e3e3;\n    font-family: \'Segoe UI\', Segoe, Arial, sans-serif;\n    line-height: normal;\n    padding: 0px;\n  "\n>\n  <table\n    width="100%"\n    border="0"\n    cellpadding="0"\n    cellspacing="0"\n    align="center"\n    min-scale="0.9733333333333334"\n    style="transform: scale(0.973333, 0.973333); transform-origin: left top"\n  >\n    <tbody>\n      <tr>\n        <td align="center">\n          <br />\n          <table\n            align="center"\n            border="0"\n            cellspacing="0"\n            cellpadding="30"\n            width="100%"\n            style="max-width: 600px; border-collapse: collapse"\n          >\n            <tbody>\n              <tr>\n                <td bgcolor="#FFFFFF">\n                  <table align="center" width="100%">\n                    <tbody>\n                      <tr>\n                        <td\n                          bgcolor="#FFFFFF"\n                          style="font-size: 11pt; color: #000000"\n                        >\n                          @{variables(\'Logo\')}\n                          <br /><br />\n                          <h1 style="font-size: 16pt; font-weight: 600">\n                            @{triggerBody()?[\'subject\']}\n                          </h1>\n                          <p>@{triggerBody()?[\'body\']}</p>\n\n                          <hr />\n                          <div\n                            style="\n                              font-family: Consolas, Monaco, monospace;\n                              background: #f2f2f2;\n                              font-size: 12pt;\n                            "\n                          >\n                            <br />\n                            <ul>\n                              <li style="margin-bottom: 10px">\n                                Subscription:&nbsp;<strong\n                                  >@{triggerBody()?[\'subscriptionName\']}</strong\n                                >\n                              </li>\n                              <li style="margin-bottom: 10px">\n                                Object Name:&nbsp;&nbsp;<strong\n                                  >@{triggerBody()?[\'objectName\']}</strong\n                                >\n                              </li>\n                              <li style="margin-bottom: 10px">\n                                Role Name:&nbsp;&nbsp;&nbsp;&nbsp;<strong\n                                  >@{triggerBody()?[\'roleName\']}</strong\n                                >\n                              </li>\n                            </ul>\n                            <br />\n                          </div>\n                          <hr />\n                          <p>\n                            Add message here.\n                          </p>\n                          <p>Thank you.</p>\n                        </td>\n                      </tr>\n                    </tbody>\n                  </table>\n                </td>\n              </tr>\n            </tbody>\n          </table>\n          <br />\n        </td>\n      </tr>\n    </tbody>\n  </table>\n</div>\n'
        }
        Initialize_variable_Logo: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'Logo'
                type: 'string'
                value: '<img alt="Amdocs Logo" src="data:image/png;base64,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" />'
              }
            ]
          }
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
