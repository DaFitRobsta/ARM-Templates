param storName string = uniqueString(resourceGroup().id)
param location string = resourceGroup().location
param storSKU string = 'Standard_LRS'
param storKind string = 'StorageV2'
param subnetID string = ''

resource sqlmiStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storName
  location: location
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
      ipRules: []
      virtualNetworkRules:[
        {
          id: subnetID
          action: 'Allow'
        }
      ]
    }
  }  
}

output storageAccountBlobUri string = sqlmiStorageAccount.properties.primaryEndpoints.blob
//output storageAccountAccessKey string = listkeys(sqlmiStorageAccount.name, '2021-04-01').keys[0].value
// output storageAccountResourceId string = sqlmiStorageAccount.id
