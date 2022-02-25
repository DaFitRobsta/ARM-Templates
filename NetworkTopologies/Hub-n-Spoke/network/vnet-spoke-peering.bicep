@description('Defines the various properties for peering between Vnets')
param peeringOptions object

@description('Sets whether or not to useRemoteGateways')
param deployVirtualNetworkGateway bool

@description('Source VNet configuration object with properites')
param sourceVnet object

@description('All Vnets in parameter file')
param allVnetsConfigs array

// Only create spoke to hub peerings
resource vnetSpokePeeringToHubVnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = [for vnet in allVnetsConfigs: if (vnet.peeringOption == 'HubToSpoke') {
  name: '${sourceVnet.vnetName}/to-${vnet.vnetName}'
  properties: {
    allowForwardedTraffic: peeringOptions.allowForwardedTraffic
    allowGatewayTransit: peeringOptions.allowGatewayTransit
    allowVirtualNetworkAccess: peeringOptions.allowVirtualNetworkAccess
    useRemoteGateways: deployVirtualNetworkGateway
    remoteVirtualNetwork: {
      id: resourceId(vnet.resourceGroupName, 'Microsoft.Network/virtualNetworks', vnet.vnetName)
    }
  }
}]
