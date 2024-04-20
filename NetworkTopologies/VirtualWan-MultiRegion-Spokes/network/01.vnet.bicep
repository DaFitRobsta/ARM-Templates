// Creates a VNET with 3 subnets and NSGs associated with those subnets
@description('VNet configuration object with properites')
param vnetObj object = {}

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Deploy Azure Bastion into the AzureBastionSubnet (true or false)')
param deployAzureBastion bool = false

@description('Tags for deployed resources.')
param tags object = {}

// Create the NSGs for each VNET's subnet(s)
module createNSGs '02.nsg.bicep' = [for subnet in vnetObj.subnets: {
  name: 'createNSG-${vnetObj.vnetName}-${subnet.name}'
  params: {
    location: location
    tags: tags
    subnetProperties: subnet
    //vnetName: vnetObj.vnetName
  }
}] 

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetObj.vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: vnetObj.vnetAddressSpace
    }
    dhcpOptions: {
      dnsServers: empty(vnetObj.dnsServers) ? [] : vnetObj.dnsServers
    }
    subnets: [for (subnet, index) in vnetObj.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: ((!contains(subnet.name, 'AzureFirewallSubnet') && (!contains(subnet.name, 'GatewaySubnet'))) ? json('{"id": "${createNSGs[index].outputs.nsgID}"}') : null)
        serviceEndpoints: (!empty(subnet.serviceEndpoints)) ? subnet.serviceEndpoints : []
        //privateEndpointNetworkPolicies: 'Disabled'
      }
    }]
  }
}

// Deploy Azure Bastion if requested
module createAzureBastion '03.bastion.bicep' = [for subnet in vnetObj.subnets : if ((deployAzureBastion) && (subnet.name == 'AzureBastionSubnet')) {
  name: 'createAzureBastion-In-${subnet.name}'
  params: {
    vnetName: vnet.name
    location: location
  }
}]

output vnetId string = vnet.id
output vnetName string = vnet.name
//output subnetProperties array = vnet.properties.subnets
/* output privateEndpointSubnet array = [for (subnet, index) in subnets: (subnet.name == vnetPrivateEndpointSubnetName) ? {
    subnetName: vnet.properties.subnets[index].name
    subnetId: vnet.properties.subnets[index].id
} : null ] */
