@description('Virtual Network name')
param vnetName string

@description('Azure region for Bastion and virtual network')
param location string = resourceGroup().location

@description('Tags for deployed resources.')
param Tags object = {}

var bastionHostName = 'bas-${vnetName}'
var publicIpAddressName = 'pip-${bastionHostName}'
var bastionSubnetName = 'AzureBastionSubnet'

// Reference an existing Azure Bastion Subnet
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: '${vnetName}/${bastionSubnetName}'
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: publicIpAddressName
  location: location
  tags: Tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: bastionHostName
  location: location
  tags: Tags
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
