param blobStorageAccountPrivateEndpointName string
param location string = resourceGroup().location
param blobStorageAccountId string
param subnetId string
param blobStorageAccountFQDN string
param blobPrivateDnsZoneId string
param privateDnsZoneConfigName string = 'privatelink-blob-core-windows-net'

@description('Tags for deployed resources.')
param Tags object = {}

var blobStorageAccountPrivateEndpointGroupName = 'blob'

// Create the private endpoint
resource createBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: blobStorageAccountPrivateEndpointName
  location: location
  tags: Tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: blobStorageAccountPrivateEndpointName
        properties: {
          privateLinkServiceId: blobStorageAccountId
          groupIds: [
            blobStorageAccountPrivateEndpointGroupName
          ]
        }
      }
    ]
    subnet: {
      id: subnetId
    }
    customDnsConfigs: [
      {
        fqdn: blobStorageAccountFQDN
      }
    ]
  }
}

// create the Private DNS Record in an existing Private DNS Zone
resource createBlobPrivateDnsRecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = {
  name: '${createBlobPrivateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneConfigName
        properties: {
          privateDnsZoneId: blobPrivateDnsZoneId
        }
      }
    ]
  }
}
