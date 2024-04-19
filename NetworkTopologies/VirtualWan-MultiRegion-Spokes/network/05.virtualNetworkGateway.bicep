param hubVnetName string
param hubVnetResourceGroupName string
param virtualNetworkGatewayName string
param virtualNetworkGatewaySKU string
param virtualNetworkGatewayGeneration string
param virtualNetworkGatewayType string
param virtualNetworkGatewayVpnType string
param virtualNetworkGatewayEnableBGP bool
param virtualNetworkGatewayASN int
param virtualNetworkGatewayActiveActive bool = true
param localNetworkGatewayName string
param localNetworkGatewayASN int
@description('Public IP vHub VPN GW interface 0')
param localGatewayIpAddress01 string
@description('Public IP vHub VPN GW interface 1')
param localGatewayIpAddress02 string
@description('BGP IP vHub VPN GW interface 0')
param localGatewayBGPIpAddress01 string
@description('BGP IP vHub VPN GW interface 1')
param localGatewayBGPIpAddress02 string
param localGatewaySharedKey string

@description('Enable Network Platform Diagnostics')
param enableNetworkPlatformDiagnostics bool

@description('Log Analytics Workspace ID. Used for Diagnostic Settings')
param lawId string = ''

param tags object
param location string = resourceGroup().location

// Create Public IP address for the gateway
resource createGwPublicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = [for index in range(0, 2): {
  name: 'pip-${virtualNetworkGatewayName}-0${index + 1}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${uniqueString(virtualNetworkGatewayName)}-0${index + 1}'
    }
  }
}]

// Get a handle to the GatewaySubnet
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  scope: resourceGroup(hubVnetResourceGroupName)
  name: '${hubVnetName}/GatewaySubnet'
}

// Create Virtual Network Gateway
resource createVirtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2022-07-01' = {
  name: virtualNetworkGatewayName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnet.id
          }
          publicIPAddress: {
            id: createGwPublicIP[0].id
          }
        }
        name: 'gatewayConfig1'
      }
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnet.id
          }
          publicIPAddress: {
            id: createGwPublicIP[1].id
          }
        }
        name: 'gatewayConfig2'
      }
    ]
    sku: {
      name: virtualNetworkGatewaySKU
      tier: virtualNetworkGatewaySKU
    }
    vpnGatewayGeneration: virtualNetworkGatewayGeneration
    gatewayType: virtualNetworkGatewayType
    vpnType: virtualNetworkGatewayVpnType
    activeActive: virtualNetworkGatewayActiveActive
    enableBgp: virtualNetworkGatewayEnableBGP
    bgpSettings: virtualNetworkGatewayEnableBGP ? {asn: virtualNetworkGatewayASN} : {}
  }
}

// Create Local Network Gateway if gateway type == vpn
resource createLocalNetworkGateway 'Microsoft.Network/localNetworkGateways@2022-07-01' = [for index in range(0, 2) : if (virtualNetworkGatewayType =~ 'vpn') {
 name: '${localNetworkGatewayName}-0${index + 1}'
 location: location
 tags: tags
 properties: {
  bgpSettings: {
    asn: localNetworkGatewayASN
    bgpPeeringAddress: (index == 1) ? localGatewayBGPIpAddress01 : localGatewayBGPIpAddress02
  }
  gatewayIpAddress: (index == 1) ? localGatewayIpAddress01 : localGatewayIpAddress02
 }
}]

// Create connection between Local Network Gateway
resource createOnPremToAzureVpnGwConnection 'Microsoft.Network/connections@2022-07-01' = [for index in range(0, 2) : if (virtualNetworkGatewayType =~ 'vpn') {
  name: 'con-${virtualNetworkGatewayName}-to-${createLocalNetworkGateway[index].name}'
  location: location
  tags: tags
  properties: {
    connectionType: 'IPsec'
    enableBgp: virtualNetworkGatewayEnableBGP
    virtualNetworkGateway1: {
      id: createVirtualNetworkGateway.id
      properties: {
        
      }
    }
    localNetworkGateway2: {
      id: createLocalNetworkGateway[index].id
      properties: {
      }
    }
    sharedKey: localGatewaySharedKey
  }
}]

// Set diagnostic settings
resource diagVNG 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableNetworkPlatformDiagnostics) {
  name: 'diag-${createVirtualNetworkGateway.name}'
  scope: createVirtualNetworkGateway
  properties: {
    workspaceId: lawId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        enabled: true
      }
    ]
  }
}

output vpnGatewayPublicFqdn00 string = createGwPublicIP[0].properties.dnsSettings.fqdn
output vpnGatewayPublicFqdn01 string = createGwPublicIP[1].properties.dnsSettings.fqdn
output vpnGatewayBgpIp00 string = createVirtualNetworkGateway.properties.bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]
output vpnGatewayBgpIp01 string = createVirtualNetworkGateway.properties.bgpSettings.bgpPeeringAddresses[1].defaultBgpIpAddresses[0]
