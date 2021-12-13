param sqlKeyVaultName string = ''
param location string = ''
@allowed([
  'standard'
  'premium'
])
param sqlKeyVaultSkuName string = 'standard'
param sqlIdentity string = ''
param sqlName string = ''
//param sqlmiResourceId string = ''
param tags object = {}

resource sqlKeyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: sqlKeyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: sqlKeyVaultSkuName
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: sqlIdentity
        tenantId: subscription().tenantId
        permissions: {
          keys: [
            'get'
            'wrapKey'
            'unwrapKey'
          ]
        }
      }
    ]
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    enableSoftDelete: true
    enablePurgeProtection: true
  }
}

// The individual deploying this ARM template must be an Owner or User Access Administrator over the Subscription
// in order to create a key within the key vault.
resource sqlKey 'Microsoft.KeyVault/vaults/keys@2021-04-01-preview' = {
  name: '${sqlKeyVault.name}/${sqlName}'
  tags: tags
  properties: {
    attributes: {}
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'unwrapKey'
      'wrapKey'
    ]
    //curveName: 'P-256'
  }
}

// Set the SQL MI key to the AzureKeyVault
module setTDE 'setTDE.bicep' = {
  name: 'setTDEtoCMK'
  params: {
    sqlKeyVaultKeyUriWithVersion: sqlKey.properties.keyUriWithVersion
    sqlKeyVaultName: sqlKeyVault.name
    sqlName: sqlName
    sqlServerKeyType: 'AzureKeyVault'
  }
}

output keyVaultUri string = sqlKeyVault.properties.vaultUri
output sqlmiKeyVaultKeyUriWithVersion string = sqlKey.properties.keyUriWithVersion
