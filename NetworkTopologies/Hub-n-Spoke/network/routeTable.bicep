 param location string = resourceGroup().location
 param udrName string
 param azFirewallIP string
 @allowed( [
  'HubToSpoke'
  'SpokeToHub'
 ])
 param vnetType string
 
 @description('Defines all the Virtual Networks, subnets and their properites')
param allVnetConfigs array = []
param tags object

var gatewayRoutes = [for vnet in allVnetConfigs: {
  name: 'to-${vnet.vnetName}'
  properties: {
    nextHopType: 'VirtualAppliance'
    addressPrefix: vnet.vnetAddressSpace
    nextHopIpAddress: azFirewallIP
  }
}]

var spokeRoutes = [
  {
    name: 'ZeroRoute'
    properties: {
      nextHopType: 'VirtualAppliance'
      addressPrefix: '0.0.0.0/0'
      nextHopIpAddress: azFirewallIP
    }
  }
]

 // Create a single Route Table (UDR) per Virtual Network, assigned to each subnet
 resource createUDR 'Microsoft.Network/routeTables@2020-11-01' = {
   name: udrName
   location: location
   tags: tags
   properties: {
     disableBgpRoutePropagation: (vnetType == 'HubToSpoke') ? false : true
     routes: (vnetType == 'HubToSpoke') ? gatewayRoutes : spokeRoutes
   }
 }

 output udrID string = createUDR.id
