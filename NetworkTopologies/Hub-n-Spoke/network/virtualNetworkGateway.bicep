param hubVnetName string
param hubVnetResourceGroupName string
param virtualNetworkGatewayName string
param virtualNetworkGatewaySKU string
param virtualNetworkGatewayGeneration string
param virtualNetworkGatewayType string
param virtualNetworkGatewayVpnType string
param virtualNetworkGatewayEnableBGP bool
param localNetworkGatewayName string
param localNetworkAddressSpace array
param localGatewayIpAddress string
param localGatewaySharedKey string

@description('Enable Network Platform Diagnostics')
param enableNetworkPlatformDiagnostics bool

@description('Log Analytics Workspace ID. Used for Diagnostic Settings')
param lawId string = ''

param tags object
param location string = resourceGroup().location

// Create Public IP address for the gateway
resource createGwPublicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-${virtualNetworkGatewayName}'
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Get a handle to the GatewaySubnet
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  scope: resourceGroup(hubVnetResourceGroupName)
  name: '${hubVnetName}/GatewaySubnet'
}
// Create Virtual Network Gateway
resource createVirtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
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
            id: createGwPublicIP.id
          }
        }
        name: 'gatewayConfig'
      }
    ]
    sku: {
      name: virtualNetworkGatewaySKU
      tier: virtualNetworkGatewaySKU
    }
    vpnGatewayGeneration: virtualNetworkGatewayGeneration
    gatewayType: virtualNetworkGatewayType
    vpnType: virtualNetworkGatewayVpnType
    enableBgp: virtualNetworkGatewayEnableBGP
  }
}

// Create Local Network Gateway if gateway type == vpn
resource createLocalNetworkGateway 'Microsoft.Network/localNetworkGateways@2021-05-01' = if (virtualNetworkGatewayType =~ 'vpn') {
 name: localNetworkGatewayName
 location: location
 tags: tags
 properties: {
   localNetworkAddressSpace: {
     addressPrefixes: localNetworkAddressSpace
   }
   gatewayIpAddress: localGatewayIpAddress
 }
}

// Create connection between Local Network Gateway
resource createOnPremToAzureVpnGwConnection 'Microsoft.Network/connections@2021-05-01' = if (virtualNetworkGatewayType =~ 'vpn') {
  name: 'con-${virtualNetworkGatewayName}-to-${localNetworkGatewayName}'
  location: location
  tags: tags
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: createVirtualNetworkGateway.id
      properties: {
        
      }
    }
    localNetworkGateway2: {
      id: createLocalNetworkGateway.id
      properties: {
      }
    }
    sharedKey: localGatewaySharedKey
  }
}

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
