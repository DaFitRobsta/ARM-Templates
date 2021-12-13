param sqlmiKeyVaultName string = ''
param location string = ''
@allowed([
  'standard'
  'premium'
])
param sqlmiKeyVaultSkuName string = 'standard'
param sqlmiIdentity string = ''
param sqlmiName string = ''
//param sqlmiResourceId string = ''
param tags object = {}

resource sqlmiKeyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: sqlmiKeyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: sqlmiKeyVaultSkuName
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: sqlmiIdentity
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
/*
resource sleep 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'Sleep'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '3.0'
    retentionInterval: 'PT1H'
    scriptContent: 'Start-Sleep 15'
  }  
}
*/

// The individual deploying this ARM template must be an Owner or User Access Administrator over the Subscription
// in order to create a key within the key vault.
resource sqlmiKey 'Microsoft.KeyVault/vaults/keys@2021-04-01-preview' = {
  name: '${sqlmiKeyVault.name}/${sqlmiName}'
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
    sqlmiKeyVaultKeyUriWithVersion: sqlmiKey.properties.keyUriWithVersion
    sqlmiKeyVaultName: sqlmiKeyVault.name
    sqlmiName: sqlmiName
    sqlmiServerKeyType: 'AzureKeyVault'
  }
}
/*
resource addSqlmiAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${sqlmiKeyVault.name}/add'
  properties: {
    accessPolicies: [
      {
        objectId: sqlmiIdentity
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
  }
}
*/
/* Not Needed, but keeping here for historical purposes
// Allow SQL MI identity to read the key vault
// Key Vault Crypto Service Encryption User
var roleDefinitionID = resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')
var roleAssignmentName = guid(sqlmiIdentity, roleDefinitionID, resourceGroup().id)
var sqlmiProviderScope = substring(sqlmiResourceId, indexOf(sqlmiResourceId, 'Microsoft.Sql'))
resource grantAccessToKeyVault 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: roleAssignmentName
  properties: {
    principalId: sqlmiIdentity
    roleDefinitionId: roleDefinitionID
    principalType: 'ServicePrincipal'
  }
  // Issue with Bicep where I'm unable to assign to the individual resource
  scope: resourceGroup()
}
*/
output keyVaultUri string = sqlmiKeyVault.properties.vaultUri
output sqlmiKeyVaultKeyUriWithVersion string = sqlmiKey.properties.keyUriWithVersion
