param sqlmiIdentity string = ''

var roleAssignmentName = guid(sqlmiIdentity, roleDefinitionID, resourceGroup().id)
// Storage Blob Data Contributor
var roleDefinitionID = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
resource grantAccessToStorageAccount 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: roleAssignmentName
  properties: {
    principalId: sqlmiIdentity
    roleDefinitionId: roleDefinitionID
   principalType: 'ServicePrincipal'
  }
  scope: resourceGroup()
}
