param storName string = 'stansg${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param storSKU string = 'Standard_LRS'
param storKind string = 'StorageV2'
param subnetIDs array = []
param clientIPcidr array = []

@description('Tags for deployed resources.')
param tags object = {}

var clientAllowRule = [for IP in clientIPcidr: {
  action: 'Allow'
  value: IP
} ]

/* var clientAllowRule = [
  {
    action: 'Allow'
    value: clientIPcidr
  }
] */

var vnetRules = [for (subnet, index) in subnetIDs: {
    id: subnet
    action: 'Allow'
}]

resource sqlStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storName
  location: location
  tags: tags
  sku: {
    name: storSKU
  }
  kind: storKind
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Cool'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices, Logging, Metrics'
      resourceAccessRules: []
      ipRules: empty(clientIPcidr) ? [] : clientAllowRule
      virtualNetworkRules: !empty(subnetIDs) ? vnetRules : []
    }
  }  
}

output storageAccountBlobUri string = sqlStorageAccount.properties.primaryEndpoints.blob
output storageAccountId string = sqlStorageAccount.id
output blobStorageAccountFQDN string = split(sqlStorageAccount.properties.primaryEndpoints.blob, '/')[2]
// output storageAccountKey string = sqlStorageAccount.listKeys().keys[0].value
output storageAccountName string = sqlStorageAccount.name
