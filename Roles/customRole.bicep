@description('Name of the custom role')
param roleName string = '[org]Subscription Owner'

@description('Role Description')
param roleDescription string = 'Include a useful description'

@description('Which scope(s) is this custom role available. Highly recommend at a Management Group level.')
param assignableScopes array = [
  '/providers/Microsoft.Management/managementGroups/{groupId1}'
]

@description('Array of actions for the roleDefinition')
param actions array = []

@description('Array of notActions for the roleDefinition')
param notActions array = []

@description('Array of dataActions for the roleDefinition')
param dataActions array = []

@description('Array of notDataActions for the roleDefinition')
param notDataActions array = []

// Generate an unique ID for the custom role.
var nameId = guid(roleName, assignableScopes[0]) 

resource customOwner 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: nameId
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    assignableScopes: assignableScopes
    permissions: [
      {
        actions: actions
        notActions: notActions
        dataActions: dataActions
        notDataActions: notDataActions
      }
    ]
  }
}
