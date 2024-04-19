@description('Name of the Virtual Hub.')
param vHubName string

@description('Source VNet configuration object with properites')
param vnet object


// Create Virtual Hub Virtual Network Connections
resource vnetHubPeeringToRemoteVnet 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-09-01' = {
  name: '${vHubName}/${vnet.vnetName}_connection'
  properties: {
    remoteVirtualNetwork: {
      id: resourceId(vnet.subscriptionId, vnet.resourceGroupName, 'Microsoft.Network/virtualNetworks', vnet.vnetName)
    }
  }
}
