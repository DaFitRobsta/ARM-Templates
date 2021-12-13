param sqlKeyVaultKeyUriWithVersion string = ''
param sqlKeyVaultName string = ''
param sqlName string = ''

@allowed([
  'AzureKeyVault'
  'ServiceManaged'
])
param sqlServerKeyType string = 'AzureKeyVault'

// Set the SQL MI key to the AzureKeyVault
//var sqlKeyUri = sqlKeyVault.properites.keyUriWithVersion
var sqlKeyName = '${sqlKeyVaultName}_${sqlName}_${substring(sqlKeyVaultKeyUriWithVersion, lastIndexOf(sqlKeyVaultKeyUriWithVersion, '/') + 1)}'
resource sqlKey 'Microsoft.Sql/servers/keys@2021-02-01-preview' = if (sqlServerKeyType == 'AzureKeyVault'){
  name: '${sqlName}/${sqlKeyName}'
  properties: {
    serverKeyType: sqlServerKeyType
    uri: sqlKeyVaultKeyUriWithVersion
  }
}
resource sqlTDE 'Microsoft.Sql/servers/encryptionProtector@2021-02-01-preview' = {
  name: '${sqlName}/current'
  properties: {
    serverKeyName: (sqlServerKeyType == 'AzureKeyVault') ? sqlKeyName : sqlServerKeyType
    serverKeyType: sqlServerKeyType
    autoRotationEnabled: false
  }
  dependsOn: [
    sqlKey
  ]
}
