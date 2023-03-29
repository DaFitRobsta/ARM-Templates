@description('An Virtual Hub object containing configuration properties and virtual network config.')
param vWanHubConfig object

@description('Virtual WAN resource Id that the hub will be associated with')
param vWanId string

@description('Deploy Azure Bastion into the AzureBastionSubnet (true or false)')
param deployAzureBastion bool

@description('Currently setting all resoruces to the same resource TAGS')
param tags object

var varLocation = vWanHubConfig.location
var sharedKey = uniqueString(vWanHubConfig.vHubName)

// Create any Hub's connected virtual network and NSGs
module createVnets '01.vnet.bicep' = [for vnet in vWanHubConfig.spokeVnets: {
  name: 'createVnets-${vnet.vnetName}'
  params: {
    location: varLocation
    deployAzureBastion: deployAzureBastion
    tags: tags
    vnetObj: vnet
  }
}] 

// Create vHub
resource createVhub 'Microsoft.Network/virtualHubs@2022-07-01' = {
  name: vWanHubConfig.vHubName
  location: varLocation
  properties: {
    addressPrefix: vWanHubConfig.vHubAddressPrefix
    virtualWan: {
      id: vWanId
    }
  }
}

// Establish Hub Virtual Network Connections (Peering for Hub and Spoke)
module createHubVnetPeerings '04.hub-vnet-peering.bicep' = [for vnet in vWanHubConfig.spokeVnets: {
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
resource createHubVpnGateway 'Microsoft.Network/vpnGateways@2022-07-01' = if (vWanHubConfig.deployVpnGateway) {
  name: '${createVhub.name}-S2SVpnGw'
  location: varLocation
  properties: {
    vpnGatewayScaleUnit: vWanHubConfig.vpnGatewayScaleUnit
    virtualHub: {
      id: createVhub.id
    }
  }
}

// Create ER Gateway in Hub
resource createHubErGateway 'Microsoft.Network/expressRouteGateways@2021-05-01' = if (vWanHubConfig.deployErGateway) {
  name: '${createVhub.name}-ErGw'
  location: varLocation
  properties: {
    virtualHub: {
      id: createVhub.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: vWanHubConfig.erGatewayScaleUnit
      }
    }
  }
}

// Create Azure Firewall Policy
module createAzureFirewallPolicy 'firewallPolicy/firewallPolicy.bicep' = if (vWanHubConfig.deploySecuredHub) {
  name: 'createAzureFirewallPolicy-${createVhub.name}'
  params: {
    location: varLocation
    policyName: 'CoreFWPolicy-${createVhub.name}'
    firewallPolicySku: vWanHubConfig.azureFirewallSkuTier
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
resource createSecuredHub 'Microsoft.Network/azureFirewalls@2022-07-01' = if (vWanHubConfig.deploySecuredHub) {
  name: '${createVhub.name}-AFW'
  location: varLocation
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: vWanHubConfig.azureFirewallSkuTier
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
      id: vWanHubConfig.deploySecuredHub ? createAzureFirewallPolicy.outputs.afwPolicyId : '' 
    }
  }
}

// Create a simulated "on-prem" environment by deploying a VPN GW in a virtual network that connects to this virtual hub
// Start with creating the virtual network to support the VPN GW
module createOnPremVnet '01.vnet.bicep' = if (vWanHubConfig.onPremSite.deployVirtualNetworkGateway) {
  name: 'createOnPremVnet-${vWanHubConfig.onPremSite.vnetName}'
  params: {
    location: varLocation
    deployAzureBastion: deployAzureBastion
    tags: tags
    vnetObj: vWanHubConfig.onPremSite
  }
}

// Create On-prem Virtual Network gateway and configure Local Network Gateway. For this deployment to execute, the cooresdponding 
// Virtual Hub VPN Gateway should have already been deployed. If not, even with the vWanHubConfig.onPremSite.deployVirtualNetworkGateway == true
// this module will not be deployed unless virtual hub vpn gateway has already been deployed.
module createVirtualNetworkGateway '05.virtualNetworkGateway.bicep' = if(vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) {
    name: 'createVirtualNetworkGateway-${vWanHubConfig.onPremSite.vnetName}'
  dependsOn: [
    createVnets
  ]
  params: {
    location: varLocation
    hubVnetResourceGroupName: resourceGroup().name
    hubVnetName: vWanHubConfig.onPremSite.deployVirtualNetworkGateway ? createOnPremVnet.outputs.vnetName : ''
    virtualNetworkGatewaySKU: vWanHubConfig.onPremSite.virtualNetworkGatewaySKU
    virtualNetworkGatewayType: vWanHubConfig.onPremSite.virtualNetworkGatewayType
    virtualNetworkGatewayEnableBGP: vWanHubConfig.onPremSite.virtualNetworkGatewayEnableBGP
    virtualNetworkGatewayASN: vWanHubConfig.onPremSite.virtualNetworkGatewayASN
    virtualNetworkGatewayActiveActive: true
    virtualNetworkGatewayGeneration: vWanHubConfig.onPremSite.virtualNetworkGatewayGeneration
    virtualNetworkGatewayVpnType: vWanHubConfig.onPremSite.virtualNetworkGatewayVpnType
    virtualNetworkGatewayName: vWanHubConfig.onPremSite.virtualNetworkGatewayName
    localNetworkGatewayName: 'lng-${vWanHubConfig.vHubName}'
    localGatewayIpAddress01: vWanHubConfig.deployVpnGateway ? createHubVpnGateway.properties.ipConfigurations[0].publicIpAddress : ''
    localGatewayIpAddress02: vWanHubConfig.deployVpnGateway ? createHubVpnGateway.properties.ipConfigurations[1].publicIpAddress : ''
    localGatewayBGPIpAddress01: vWanHubConfig.deployVpnGateway ? createHubVpnGateway.properties.bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0] : ''
    localGatewayBGPIpAddress02: vWanHubConfig.deployVpnGateway ? createHubVpnGateway.properties.bgpSettings.bgpPeeringAddresses[1].defaultBgpIpAddresses[0] : ''
    localNetworkGatewayASN: vWanHubConfig.deployVpnGateway ? createHubVpnGateway.properties.bgpSettings.asn : 0
    localGatewaySharedKey: sharedKey
    enableNetworkPlatformDiagnostics: false
    lawId: '' 
    tags: tags   
  }
}

// At this point, the VPN "on-prem" gateways should be trying to connect to the Virtual Hub's VPN GW.
// Create the VPN Site(s)
module createVwanVpnSite '06.vwan.vpn.site.bicep' = if (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) {
  name: 'createVwanVpnSite-${vWanHubConfig.onPremSite.name}'
  dependsOn: [
    createVirtualNetworkGateway
  ]
  params: {
    tags: tags
    vWanHubConfig: vWanHubConfig
    vWanId: vWanId
    vpnGatewayBgpIp00: (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) ? createVirtualNetworkGateway.outputs.vpnGatewayBgpIp00 : ''
    vpnGatewayBgpIp01: (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) ? createVirtualNetworkGateway.outputs.vpnGatewayBgpIp01 : ''
    vpnGatewayPublicFqdn00: (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) ? createVirtualNetworkGateway.outputs.vpnGatewayPublicFqdn00 : ''
    vpnGatewayPublicFqdn01: (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) ? createVirtualNetworkGateway.outputs.vpnGatewayPublicFqdn01 : ''
  }
}

// Need to connect the VPN Site to Virtual Hub
resource createVhubVpnGatewayConnections 'Microsoft.Network/vpnGateways/vpnConnections@2022-05-01' = if (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) {
  name: 'connectTo-${vWanHubConfig.onPremSite.name}'
  parent: createHubVpnGateway
  dependsOn: [
    createVwanVpnSite
  ]
  properties: {
    remoteVpnSite: {
      id: (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) ? createVwanVpnSite.outputs.vpnSiteId : ''
    }
    vpnLinkConnections: [
      {
        name: (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) ? createVwanVpnSite.outputs.vpnSiteLinkName01 : null
        properties: {
          vpnSiteLink: {
            id: (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) ? createVwanVpnSite.outputs.vpnSiteLink01 : null
          }
          sharedKey: sharedKey
          enableBgp: vWanHubConfig.onPremSite.virtualNetworkGatewayEnableBGP
        }
      }
      {
        name: (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) ? createVwanVpnSite.outputs.vpnSiteLinkName02 : null
        properties: {
          vpnSiteLink: {
            id: (vWanHubConfig.onPremSite.deployVirtualNetworkGateway && vWanHubConfig.deployVpnGateway) ? createVwanVpnSite.outputs.vpnSiteLink02 : null
          }
          sharedKey: sharedKey
          enableBgp: vWanHubConfig.onPremSite.virtualNetworkGatewayEnableBGP
        }
      }
    ]
  }
}
