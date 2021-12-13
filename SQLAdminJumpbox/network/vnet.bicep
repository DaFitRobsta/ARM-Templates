// Creates a VNET with 3 subnets and NSGs associated with those subnets
@description('VNet name')
param vnetName string = 'nz-wu3-sqlAdmins-vnet01'

@description('Address prefix')
param vnetAddressPrefix string = '172.16.0.0/24'

param vnetJumpboxSubnetName string = 'sql-jumpboxes-sn'
param vnetPrivateEndpointSubnetName string = 'private-endpoints-sn'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Set Service Endpoints')
param setSubnetServiceEndpoints bool = true

@description('Define the subnets for the Vnet')
param subnets array = [
  {
    name: 'AzureBastionSubnet'
    addressPrefix: '172.16.0.0/27'
    nsgName: '${vnetName}-bastion-nsg'
  }
  {
    name: vnetJumpboxSubnetName
    addressPrefix: '172.16.0.32/27'
    nsgName: '${vnetName}-${vnetJumpboxSubnetName}-nsg'
  }
  {
    name: vnetPrivateEndpointSubnetName
    addressPrefix: '172.16.0.64/26'
    nsgName: '${vnetName}-${vnetPrivateEndpointSubnetName}-nsg'
  }
]

var subnetServiceEndpoints = [
  {
    service: 'Microsoft.Storage'
    locations: [
      location
    ]
  }
]

module createNSGs 'nsg.bicep' = [for subnet in subnets: {
  name: 'createNSG-${subnet.nsgName}'
  params: {
    location: location
    tags: {
    }
    nsgName: subnet.nsgName
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [for (subnet, index) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressprefix
        networkSecurityGroup: {
          id: createNSGs[index].outputs.nsgID
        }
        serviceEndpoints: (setSubnetServiceEndpoints == true) ? subnetServiceEndpoints : []
        privateEndpointNetworkPolicies: 'Disabled'
      }
    }]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetProperties array = vnet.properties.subnets
output privateEndpointSubnet array = [for (subnet, index) in subnets: (subnet.name == vnetPrivateEndpointSubnetName) ? {
    subnetName: vnet.properties.subnets[index].name
    subnetId: vnet.properties.subnets[index].id
} : null ]
