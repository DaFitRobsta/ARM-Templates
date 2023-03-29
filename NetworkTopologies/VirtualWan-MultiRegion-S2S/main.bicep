@description('Defines all the properties of Virtual Hubs within a Virtual WAN to support multi-region hubs. In addition, defines spoke virtual networks as well')
param vWanHubs array = []

@description('Virtual WAN and Hub configuration settings')
param vWanConfig object = {}

@description('Azure region to deploy networking resources')
param location string = resourceGroup().location

@description('Deploy Azure Bastion into the AzureBastionSubnet (true or false)')
param deployAzureBastion bool = false

@description('Currently setting all resoruces to the same resource TAGS')
param tags object = {}

// Create vWAN
resource createVwan 'Microsoft.Network/virtualWans@2021-05-01' = {
  name: vWanConfig.vWanName
  location: location
  properties: {
    allowBranchToBranchTraffic: vWanConfig.allowBranchToBranchTraffic
    allowVnetToVnetTraffic: vWanConfig.allowVnetToVnetTraffic
    type: vWanConfig.type
  }
}

// Create vHubs
module createVhubsAndOnPrem 'network/00.vhub.and.onprem.bicep' = [for vHub in vWanHubs: {
  name: vHub.vHubName
  params: {
    vWanHubConfig: vHub
    vWanId: createVwan.id
    deployAzureBastion: deployAzureBastion
    tags: tags
  }  
}]
