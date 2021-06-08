param sqlmiKeyVaultKeyUriWithVersion string = ''
param sqlmiKeyVaultName string = ''
param sqlmiName string = ''

// Set the SQL MI key to the AzureKeyVault
//var sqlmiKeyUri = sqlmiKeyVault.properites.keyUriWithVersion
var sqlmiKeyName = '${sqlmiKeyVaultName}_${sqlmiName}_${substring(sqlmiKeyVaultKeyUriWithVersion, lastIndexOf(sqlmiKeyVaultKeyUriWithVersion, '/') + 1)}'
resource sqlmiKey 'Microsoft.Sql/managedInstances/keys@2021-02-01-preview' = {
  name: '${sqlmiName}/${sqlmiKeyName}'
  properties: {
    serverKeyType: 'AzureKeyVault'
    uri: sqlmiKeyVaultKeyUriWithVersion
  }
}
resource sqlmiTDE 'Microsoft.Sql/managedInstances/encryptionProtector@2021-02-01-preview' = {
  name: '${sqlmiName}/current'
  properties: {
    serverKeyName: sqlmiKeyName
    serverKeyType: 'AzureKeyVault'
    autoRotationEnabled: false
  }
  dependsOn: [
    sqlmiKey
  ]
}
