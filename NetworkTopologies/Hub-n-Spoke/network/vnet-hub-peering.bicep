@description('Defines the various properties for peering between Vnets')
param peeringOptions object

@description('Source VNet configuration object with properites')
param sourceVnet object

@description('All Vnets in parameter file')
param allVnetsConfigs array

// Only create hub to spoke peerings
resource vnetHubPeeringToRemoteVnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = [for vnet in allVnetsConfigs: if ((vnet.vnetName != sourceVnet.vnetName)) {
  name: '${sourceVnet.vnetName}/to-${vnet.vnetName}'
  properties: {
    allowForwardedTraffic: peeringOptions.allowForwardedTraffic
    allowGatewayTransit: peeringOptions.allowGatewayTransit
    allowVirtualNetworkAccess: peeringOptions.allowVirtualNetworkAccess
    useRemoteGateways: peeringOptions.useRemoteGateways
    remoteVirtualNetwork: {
      id: resourceId(vnet.resourceGroupName, 'Microsoft.Network/virtualNetworks', vnet.vnetName)
    }
  }
}]


/* // Only create spoke to hub peerings
resource vnetSpokePeeringToHubVnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = [for vnet in allVnetsConfigs: if (!contains(vnet.vnetName, sourceVnet.vnetName) && (vnet.peeringOption == 'HubToSpoke')) {
  name: '${sourceVnet.vnetName}/to-${vnet.vnetName}'
  properties: {
    allowForwardedTraffic: peeringOptions.allowForwardedTraffic
    allowGatewayTransit: peeringOptions.allowGatewayTransit
    allowVirtualNetworkAccess: peeringOptions.allowVirtualNetworkAccess
    useRemoteGateways: peeringOptions.useRemoteGateways
    doNotVerifyRemoteGateways: peeringOptions.doNotVerifyRemoteGateways
    remoteVirtualNetwork: {
      id: resourceId(vnet.resourceGroupName, 'Microsoft.Network/virtualNetworks', vnet.vnetName)
    }
  }
}] */
