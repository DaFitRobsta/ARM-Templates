// Creates a VNET with 3 subnets and NSGs associated with those subnets
@description('VNet configuration object with properites')
param vnetObj object = {}

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Enable Network Platform Diagnostics')
param enableNetworkPlatformDiagnostics bool

@description('Log Analytics Workspace ID. Used for Diagnostic Settings')
param lawId string = ''

@description('Storage Account Id used for NSG Flow Logs')
param nsgStorageAccountId string = ''

@description('Create UDR and assign to subnet(s)')
param routeAllTrafficThroughFirewall bool

@description('Predetermined Azure Firewall IP address calucated based on AzureFirewallSubnet Address Prefix')
param azFirewallIP string

@description('Defines all the Virtual Networks, subnets and their properites')
param allVnetConfigs array = []

@description('Tags for deployed resources.')
param tags object = {}

// Create the Gateway Subnet UDR (in Hub VNET resource group) if all traffic is routed through Azure Firewall
module createVnetUDR 'routeTable.bicep' = if(routeAllTrafficThroughFirewall) {
  scope: resourceGroup(vnetObj.resourceGroupName)
  name: 'createUDR-${vnetObj.resourceGroupName}'
  params: {
    azFirewallIP: azFirewallIP
    location: vnetObj.resourceGroupLocation
    udrName: 'rt-${vnetObj.vnetName}'
    vnetType: vnetObj.peeringOption
    allVnetConfigs: (vnetObj.peeringOption == 'HubToSpoke') ? allVnetConfigs : []
    tags: tags
  }
}

// Create the NSGs for each VNET's subnet(s)
module createNSGs 'nsg.bicep' = [for subnet in vnetObj.subnets: if (!contains(subnet.name, 'AzureFirewallSubnet') && !contains(subnet.name, 'GatewaySubnet')){
  scope: resourceGroup(vnetObj.resourceGroupName)
  name: 'createNSGs-${vnetObj.vnetName}-${subnet.name}'
  params: {
    location: location
    tags: tags
    subnetProperties: subnet
    vnetName: vnetObj.vnetName
    enableNetworkPlatformDiagnostics: enableNetworkPlatformDiagnostics
    lawId: lawId
    storageAccountId: nsgStorageAccountId
  }
}] 

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetObj.vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetObj.vnetAddressSpace
      ]
    }
    dhcpOptions: {
      dnsServers: empty(vnetObj.dnsServers) ? [] : vnetObj.dnsServers
    }
    subnets: [for (subnet, index) in vnetObj.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: ((!contains(subnet.name, 'AzureFirewallSubnet') && (!contains(subnet.name, 'GatewaySubnet'))) ? json('{"id": "${createNSGs[index].outputs.nsgID}"}') : null)
        routeTable: (((routeAllTrafficThroughFirewall==true) && ((contains(vnetObj.peeringOption, 'HubToSpoke') && contains(subnet.name, 'GatewaySubnet')) || contains(vnetObj.peeringOption, 'SpokeToHub'))) ? json('{"id": "${createVnetUDR.outputs.udrID}"}') : null)
        serviceEndpoints: subnet.serviceEndpoints
        //privateEndpointNetworkPolicies: 'Disabled'
      }
    }]
  }
}

// Set diagnostic settings
resource diagVnet 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableNetworkPlatformDiagnostics) {
  name: 'diag-${vnet.name}'
  scope: vnet
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

output vnetId string = vnet.id
output vnetName string = vnet.name
output vnetAddressPrefixes array = vnet.properties.addressSpace.addressPrefixes
//output subnetProperties array = vnet.properties.subnets
/* output privateEndpointSubnet array = [for (subnet, index) in subnets: (subnet.name == vnetPrivateEndpointSubnetName) ? {
    subnetName: vnet.properties.subnets[index].name
    subnetId: vnet.properties.subnets[index].id
} : null ] */
