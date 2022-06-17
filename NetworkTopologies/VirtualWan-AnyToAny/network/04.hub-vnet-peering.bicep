@description('Name of the Virtual Hub.')
param vHubName string

@description('Source VNet configuration object with properites')
param vnet object


// Only create hub to spoke peerings
resource vnetHubPeeringToRemoteVnet 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2021-03-01' = {
  name: '${vHubName}/${vnet.vnetName}_connection'
  properties: {
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnet.vnetName)
    }
  }
}
