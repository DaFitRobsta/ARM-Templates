@description('Defines all the Virtual Networks, subnets and their properites')
param allVnetConfigs array = []

@description('Virtual Network Gateway configuration settings')
param vngConfig object = {}

@description('Currently setting all resoruces to the same resource TAGS')
param tags object = {}

var peeringOptions = {
  HubToSpoke: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: true
    useRemoteGateways: false
  }
  SpokeToHub: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    // useRemoteGateways: true /* Determined based on whether or not a Virtual Network Gateway is deployed to the Hub VNET in the main.parameters.json */
  }
}

targetScope = 'subscription'

// Create Resource Groups for each VNET
resource createRGs 'Microsoft.Resources/resourceGroups@2021-04-01' = [for vnet in allVnetConfigs : {
  name: vnet.resourceGroupName
  location: vnet.resourceGroupLocation
  tags: tags
}]

// Create the VNET's and NSGs
module createVnets 'network/vnet.bicep' = [for vnet in allVnetConfigs: {
  scope: resourceGroup(vnet.resourceGroupName)
  dependsOn: createRGs
  name: 'createVnets-${vnet.vnetName}'
  params: {
    location: vnet.resourceGroupLocation
    tags: tags
    vnetObj: vnet
  }
}] 

// Create VPN, ER Gateway, or none
// iterate through all VNETs until Virtual Network Gateway bool property is found
module createVirtualNetworkGateway 'network/virtualNetworkGateway.bicep' = [for vnet in allVnetConfigs: if(vnet.peeringOption == 'HubToSpoke') {
  scope: resourceGroup(vnet.resourceGroupName)
  name: 'createVirtualNetworkGateway-${vnet.vnetName}'
  dependsOn: [
    createVnets
  ]
  params: {
    location: vnet.resourceGroupLocation
    hubVnetResourceGroupName: vnet.resourceGroupName
    hubVnetName: vnet.vnetName
    deployVirtualNetworkGateway: vngConfig.deployVirtualNetworkGateway
    virtualNetworkGatewaySKU: vngConfig.virtualNetworkGatewaySKU
    virtualNetworkGatewayType: vngConfig.virtualNetworkGatewayType
    virtualNetworkGatewayEnableBGP: vngConfig.virtualNetworkGatewayEnableBGP    
    virtualNetworkGatewayGeneration: vngConfig.virtualNetworkGatewayGeneration
    virtualNetworkGatewayVpnType: vngConfig.virtualNetworkGatewayVpnType
    virtualNetworkGatewayName: vngConfig.virtualNetworkGatewayName    
  }
}]

// Establish Vnet Peering for Hub and Spoke
module createHubVnetPeerings 'network/vnet-hub-peering.bicep' = [for vnet in allVnetConfigs: if( vnet.peeringOption == 'HubToSpoke') {
  scope: resourceGroup(vnet.resourceGroupName)
  name: 'createVnetHubPeering-${vnet.vnetName}'
  dependsOn: [
    createVnets
  ]
  params: {
    peeringOptions: peeringOptions[vnet.peeringOption]
    sourceVnet: vnet
    allVnetsConfigs: allVnetConfigs
  }
}]

module createSpokeVnetPeerings 'network/vnet-spoke-peering.bicep' = [for vnet in allVnetConfigs: if( vnet.peeringOption == 'SpokeToHub') {
  scope: resourceGroup(vnet.resourceGroupName)
  name: 'createVnetSpokePeering-${vnet.vnetName}'
  dependsOn: [
    createVnets
    createVirtualNetworkGateway
  ]
  params: {
    peeringOptions: peeringOptions[vnet.peeringOption]
    sourceVnet: vnet
    allVnetsConfigs: allVnetConfigs
    deployVirtualNetworkGateway: vngConfig.deployVirtualNetworkGateway
  }
}]
