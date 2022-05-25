@description('Defines all the Virtual Networks, subnets and their properites')
param allVnetConfigs array = []

@description('Virtual WAN and Hub configuration settings')
param vWanConfig object = {}

@description('Azure region to deploy networking resources')
param location string = resourceGroup().location

@description('Deploy Azure Bastion into the AzureBastionSubnet (true or false)')
param deployAzureBastion bool = false

@description('Deploy Azure Firewall in the Virtual Hub')
param deploySecuredVirtualHub bool

@description('Basic, Standard, or Premium')
param azureFirewallSkuTier string = 'Standard'

@description('Currently setting all resoruces to the same resource TAGS')
param tags object = {}

// Create the VNET's and NSGs
module createVnets 'network/01.vnet.bicep' = [for vnet in allVnetConfigs: {
  name: 'createVnets-${vnet.vnetName}'
  params: {
    location: location
    deployAzureBastion: deployAzureBastion
    tags: tags
    vnetObj: vnet
  }
}] 

// Create vWAN
resource createVwan 'Microsoft.Network/virtualWans@2021-05-01' = {
  name: vWanConfig.vWanName
  location: location
  properties: {
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    type: 'Standard' 
  }
}

// Create vHub
resource createVhub 'Microsoft.Network/virtualHubs@2021-05-01' = {
  name: vWanConfig.vHubName
  location: location
  properties: {
    addressPrefix: vWanConfig.vHubAddressPrefix
    virtualWan: {
      id: createVwan.id
    }
  }
}

// Establish Hub Virtual Network Connections (Peering for Hub and Spoke)
module createHubVnetPeerings 'network/04.hub-vnet-peering.bicep' = [for vnet in allVnetConfigs: {
  name: 'createVnetHubPeering-${vnet.vnetName}'
  dependsOn: [
    createVnets
  ]
  params: {
   vHubName: createVhub.name
   vnet: vnet
  }
}]

// Create VPN Gateway in Hub
resource createHubVpnGateway 'Microsoft.Network/vpnGateways@2021-05-01' = if (vWanConfig.deployVpnGateway) {
  name: '${createVhub.name}-S2SVpnGw'
  location: location
  properties: {
    vpnGatewayScaleUnit: vWanConfig.vpnGatewayScaleUnit
    virtualHub: {
      id: createVhub.id
    }
    bgpSettings: {
      asn: 65515
    }
  }
}

// Create ER Gateway in Hub
resource createHubErGateway 'Microsoft.Network/expressRouteGateways@2021-05-01' = if (vWanConfig.deployErGateway) {
  name: '${createVhub.name}-ErGw'
  location: location
  properties: {
    virtualHub: {
      id: createVhub.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: vWanConfig.erGatewayScaleUnit
      }
    }
  }
}

// Create Azure Firewall Policy
module createAzureFirewallPolicy 'network/firewallPolicy/firewallPolicy.bicep' = if(deploySecuredVirtualHub) {
  name: 'createAzureFirewallPolicy'
  scope: resourceGroup()
  params: {
    location: location
    firewallPolicySku: azureFirewallSkuTier
    adRulesDestinationAddresses: [
      '*'
    ]
    adRulesSourceAddresses: [
      '*'
    ]
    coreSysRulesDestinationAddresses: [
      '*'
    ]
    coreSysRulesSourceAddresses: [
      '*'
    ]
  }
}
// Create Secured Hub, aka Azure Firewall
resource createSecuredHub 'Microsoft.Network/azureFirewalls@2021-08-01' = if (deploySecuredVirtualHub) {
  name: '${createVhub.name}-AFW'
  location: location
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: azureFirewallSkuTier
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    virtualHub: {
      id: createVhub.id
    }
    firewallPolicy: {
      id: createAzureFirewallPolicy.outputs.afwPolicyId
    }
  }
}
