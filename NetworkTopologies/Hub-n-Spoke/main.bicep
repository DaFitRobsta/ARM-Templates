@description('Defines all the Virtual Networks, subnets and their properites')
param allVnetConfigs array = []

@description('Virtual Network Gateway configuration settings')
param vngConfig object = {}

@description('Local Network Gateway configuration settings')
param lngConfig object = {}

@description('Azure Firewall configuration settings')
param afwConfig object = {}

@description('true = deploy bastion, false = no deploy')
param deployBastion bool

@description('Enable Network Platform Diagnostics')
param enableNetworkPlatformDiagnostics bool

@description('Azure Firewall Workbook definition')
param afwWorkbookSerializedData string

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

// Create Log Analytics Workspace for Network Logging
module createNetworkLAW 'management/logAnalytics.bicep' = [for vnet in allVnetConfigs: if(vnet.peeringOption == 'HubToSpoke' && enableNetworkPlatformDiagnostics) {
  scope: resourceGroup(vnet.resourceGroupName)
  name: 'createNetworkLAW-${vnet.resourceGroupName}'
  dependsOn: createRGs
  params: {
    location: vnet.resourceGroupLocation
    afwWorkbookSerializedData: afwWorkbookSerializedData
    tags: tags
  }  
}]

// Create Storage Account for NSG Flow Logs
module createNsgStorageAccount 'management/storageaccount.bicep' = [for vnet in allVnetConfigs: if(vnet.peeringOption == 'HubToSpoke' && enableNetworkPlatformDiagnostics) {
  scope: resourceGroup(vnet.resourceGroupName)
  name: 'createNsgStorageAccount-${vnet.resourceGroupName}'
  dependsOn: createRGs
  params: {
    location: vnet.resourceGroupLocation    
    tags: tags
  }  
}]

// Predetermine the Azure Firewall Private IP Address
module determineAzFirewallPrivateIP 'network/generateFirewallPrivateIP.bicep' = [for vnet in allVnetConfigs: if(vnet.peeringOption == 'HubToSpoke' && afwConfig.routeAllTrafficThroughFirewall) {
  scope: resourceGroup(vnet.resourceGroupName)
  name: 'determineAzFirewallPrivateIP-${vnet.vnetName}'
  dependsOn: [
    createRGs
  ]
  params: {
    vnetObj: vnet
  }
}]

// Create the VNET's, NSGs, and Route Table(s)
module createVnets 'network/vnet.bicep' = [for vnet in allVnetConfigs: {
  scope: resourceGroup(vnet.resourceGroupName)
  dependsOn: [
    createRGs
  ]
  name: 'createVnets-${vnet.vnetName}'
  params: {
    location: vnet.resourceGroupLocation
    tags: tags
    vnetObj: vnet
    enableNetworkPlatformDiagnostics: enableNetworkPlatformDiagnostics
    lawId: (enableNetworkPlatformDiagnostics==true) ? createNetworkLAW[0].outputs.workspaceId : ''
    nsgStorageAccountId: (enableNetworkPlatformDiagnostics==true) ? createNsgStorageAccount[0].outputs.storageAccountId : ''
    azFirewallIP: determineAzFirewallPrivateIP[0].outputs.azFirewallPrivateIP
    allVnetConfigs: allVnetConfigs
    routeAllTrafficThroughFirewall: afwConfig.routeAllTrafficThroughFirewall
  }
}] 

// Create VPN, ER Gateway, or none
// iterate through all VNETs until we identify the hub net and deploy Virtual Network Gateway bool property is true
module createVirtualNetworkGateway 'network/virtualNetworkGateway.bicep' = [for vnet in allVnetConfigs: if(vnet.peeringOption == 'HubToSpoke' && vngConfig.deployVirtualNetworkGateway == true) {
  scope: resourceGroup(vnet.resourceGroupName)
  name: 'createVirtualNetworkGateway-${vnet.vnetName}'
  dependsOn: [
    createVnets
  ]
  params: {
    location: vnet.resourceGroupLocation
    hubVnetResourceGroupName: vnet.resourceGroupName
    hubVnetName: vnet.vnetName    
    virtualNetworkGatewaySKU: vngConfig.virtualNetworkGatewaySKU
    virtualNetworkGatewayType: vngConfig.virtualNetworkGatewayType
    virtualNetworkGatewayEnableBGP: vngConfig.virtualNetworkGatewayEnableBGP    
    virtualNetworkGatewayGeneration: vngConfig.virtualNetworkGatewayGeneration
    virtualNetworkGatewayVpnType: vngConfig.virtualNetworkGatewayVpnType
    virtualNetworkGatewayName: vngConfig.virtualNetworkGatewayName
    localNetworkGatewayName: lngConfig.localNetworkGatewayName
    localGatewayIpAddress: lngConfig.localGatewayIpAddress
    localNetworkAddressSpace: lngConfig.localNetworkAddressSpace
    localGatewaySharedKey: lngConfig.localGatewaySharedKey
    enableNetworkPlatformDiagnostics: enableNetworkPlatformDiagnostics
    lawId: (enableNetworkPlatformDiagnostics==false) ? '' : createNetworkLAW[0].outputs.workspaceId
    tags: tags   
  }
}]

// Create Azure Firewall in Hub virtual network
// iterate through all VNETs until we identify the hub vnet and deploy azure firewall bool property is true
module createAzureFirewall 'network/azureFirewall.bicep' = [for vnet in allVnetConfigs: if(vnet.peeringOption == 'HubToSpoke' && afwConfig.deployAzureFirewall == true) {
  scope: resourceGroup(vnet.resourceGroupName)
  name: 'createAzureFirewall-${vnet.vnetName}'
  dependsOn: [
    createVnets
  ]
  params: {
    location: vnet.resourceGroupLocation
    azureFirewallName: afwConfig.afwName
    azureFirewallSkuTier: afwConfig.afwSkuTier
    vnetName: vnet.vnetName
    enableNetworkPlatformDiagnostics: enableNetworkPlatformDiagnostics
    lawId: (enableNetworkPlatformDiagnostics==false) ? '' : createNetworkLAW[0].outputs.workspaceId
    tags: tags   
  }
}]

// Create Azure Bastion
module createAzureBastion 'network/bastion.bicep' = [for vnet in allVnetConfigs: if(vnet.peeringOption == 'HubToSpoke' && deployBastion == true) {
  scope: resourceGroup(vnet.resourceGroupName)
  name: 'createAzureBastion-${vnet.vnetName}'
  dependsOn: [
    createVnets
  ]
  params: {
    location: vnet.resourceGroupLocation
    vnetName: vnet.vnetName
    enableNetworkPlatformDiagnostics: enableNetworkPlatformDiagnostics
    lawId: (enableNetworkPlatformDiagnostics==false) ? '' : createNetworkLAW[0].outputs.workspaceId
    tags: tags   
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
