@description('An Virtual Hub object containing configuration properties and virtual network config.')
param vWanHubConfig object

@description('Virtual WAN resource Id that the hub will be associated with')
param vWanId string

@description('Deploy Azure Bastion into the AzureBastionSubnet (true or false)')
param deployAzureBastion bool

@description('Currently setting all resoruces to the same resource TAGS')
param tags object

var varLocation = vWanHubConfig.location

// Create any Hub's connected virtual network and NSGs
module createVnets '01.vnet.bicep' = [for vnet in vWanHubConfig.spokeVnets: {
  name: 'createVnet-${vnet.vnetName}'
  scope: resourceGroup(vnet.subscriptionId, vnet.resourceGroupName)
  params: {
    location: vnet.resourceGroupLocation
    deployAzureBastion: deployAzureBastion
    tags: tags
    vnetObj: vnet
  }
}] 

// Create vHub
resource createVhub 'Microsoft.Network/virtualHubs@2023-09-01' = {
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

// Create P2S Gateway in Hub
// First create the VPN Server Configuration
var tenantId = subscription().tenantId
var azureCloud = environment().name
resource createVPNServerConfiguration 'Microsoft.Network/vpnServerConfigurations@2022-11-01' = if (vWanHubConfig.deployP2SGateway) {
  name: '${createVhub.name}-P2SConfig'
  location: varLocation
  properties: {
    aadAuthenticationParameters: {
      aadTenant: '${environment().authentication.loginEndpoint}${tenantId}'
      aadAudience: azureCloud == 'AzureCloud' ? '41b23e61-6c1e-4545-b367-cd054e0ed4b4' : '51bb15d4-3a4f-4ebf-9dca-40096fe32426' // Azure Public AD or Azure Government AD
      aadIssuer: 'https://sts.windows.net/${tenantId}/'
    }
    vpnProtocols: [
      'IkeV2'
      'OpenVPN'
    ]
    vpnAuthenticationTypes: [
      'Certificate'
      'AAD'
    ]
    vpnClientRootCertificates: [
      {
        name: '${createVhub.name}-DefaultRootCert'
        publicCertData: loadTextContent('P2SRootCert.b64')
      }
    ]
  }
}
// Second create the P2S Gateway
resource createP2SGateway 'Microsoft.Network/p2sVpnGateways@2022-07-01' = if (vWanHubConfig.deployP2SGateway) {
  name: '${createVhub.name}-P2SGw'
  location: varLocation
  properties: {
    vpnGatewayScaleUnit: vWanHubConfig.p2sGatewayScaleUnit
    virtualHub: {
      id: createVhub.id
    }
    vpnServerConfiguration: {
      id: createVPNServerConfiguration.id
    }
    p2SConnectionConfigurations: [
      {
        name: '${createVhub.name}-P2SConnectionConfigDefault'
        properties: {
          vpnClientAddressPool: {
            addressPrefixes: [
              vWanHubConfig.p2sAddressPrefix
            ]
          }
        }
      }
    ]
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
