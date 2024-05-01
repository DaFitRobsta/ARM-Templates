@description('Defines all the properties of Virtual Hubs within a Virtual WAN to support multi-region hubs. In addition, defines spoke virtual networks as well')
param vWanHubs array = []

@description('Virtual WAN and Hub configuration settings')
param vWanConfig object = {}

// @description('Azure region to deploy networking resources')
// param location string = resourceGroup().location

@description('Deploy Azure Bastion into the AzureBastionSubnet (true or false)')
param deployAzureBastion bool = false

@description('Currently setting all resoruces to the same resource TAGS')
param tags object = {}

targetScope = 'subscription'

// Create vWAN resource group
resource createVwanRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: vWanConfig.resourceGroupName
  location: vWanConfig.resourceGroupLocation
  tags: tags
}

// Create vWAN
module virtualWan 'br/public:avm/res/network/virtual-wan:0.1.1' = {
  name: 'virtualWanDeployment'
  scope: resourceGroup(vWanConfig.resourceGroupName)
  dependsOn: [
    createVwanRG
  ]
  params: {
    name: vWanConfig.vWanName
    allowBranchToBranchTraffic: vWanConfig.allowBranchToBranchTraffic
    allowVnetToVnetTraffic: vWanConfig.allowVnetToVnetTraffic
    disableVpnEncryption: true
    location: vWanConfig.resourceGroupLocation
    tags: tags
    type: vWanConfig.type
  }
}

// Create Resource Groups for each VNET
module createVnetResourceGroups 'management/00.resourceGroup.bicep' = [for hub in vWanHubs : {
  name: 'createVnetResourceGroupsConnectedTo-${hub.vHubName}'
  scope: resourceGroup(vWanConfig.resourceGroupName)
  dependsOn: [
    createVwanRG
  ]
  params: {
    hubSpokes: hub.spokeVnets
    tags: tags
  }
}]


// Create vHubs
module createVhubsAndSpokes 'network/00.vhub.and.spokes.bicep' = [for vHub in vWanHubs: {
  name: vHub.vHubName
  scope: resourceGroup(vWanConfig.resourceGroupName)
  params: {
    vWanHubConfig: vHub
    vWanId: virtualWan.outputs.resourceId
    deployAzureBastion: deployAzureBastion
    tags: tags
  }  
}]
