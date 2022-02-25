param hubVnetName string
param hubVnetResourceGroupName string
param deployVirtualNetworkGateway bool = true
param virtualNetworkGatewayName string
param virtualNetworkGatewaySKU string
param virtualNetworkGatewayGeneration string
param virtualNetworkGatewayType string
param virtualNetworkGatewayVpnType string
param virtualNetworkGatewayEnableBGP bool
param location string = resourceGroup().location

// Create Public IP address for the gateway
resource createGwPublicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = if (deployVirtualNetworkGateway) {
  name: 'pip-${virtualNetworkGatewayName}'
  location: location
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
resource createVirtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = if (deployVirtualNetworkGateway) {
  name: virtualNetworkGatewayName
  location: location
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
