param sqlAdminKeyVaultName string = ''
param location string = ''
@allowed([
  'standard'
  'premium'
])
param sqlAdminKeyVaultSkuName string = 'standard'
param sqlAdminPassword string = 'P${uniqueString(resourceGroup().id)}-${uniqueString(subscription().id)}x!'
param sqlIdentity string = ''
param sqlmiName string = ''
//param sqlmiResourceId string = ''
param tags object = {}

resource sqlAdminKeyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: sqlAdminKeyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: sqlAdminKeyVaultSkuName
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    enableSoftDelete: true
    enablePurgeProtection: true
    enabledForTemplateDeployment: true
  }
}

// The individual deploying this ARM template must be an Owner or User Access Administrator over the Subscription
// in order to create a key within the key vault.
resource sqlmiKey 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${sqlAdminKeyVault.name}/${sqlAdminPassword}'
  tags: tags
  properties: {
    attributes: {}
    contentType: 'Sql Admin Password'
    value: ''
  }
}

output keyVaultUri string = sqlmiKeyVault.properties.vaultUri
output sqlmiKeyVaultKeyUriWithVersion string = sqlmiKey.properties.keyUriWithVersion
