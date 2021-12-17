param privateDnsZoneNames array = [
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink${environment().suffixes.sqlServerHostname}'
]

param vnetId string
param vnetName string
@description('Tags for deployed resources.')
param Tags object = {}

resource createPrivateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zone in privateDnsZoneNames: {
  name: zone
  location: 'global'
  tags: Tags
}]

resource createPrivateDnsZoneVirtualLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, index) in privateDnsZoneNames: {
  name: '${vnetName}-link'
  parent: createPrivateDnsZones[index]
  location: 'global'
  tags: Tags
  dependsOn: [
    createPrivateDnsZones
  ]
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}]

output privateDnsZoneProperties array = [for (dnsName, index) in privateDnsZoneNames: (dnsName == 'privatelink.blob.${environment().suffixes.storage}') ? {
  privateDnsName: createPrivateDnsZones[index].name
  privateDnsZoneId: createPrivateDnsZones[index].id
} : null ]
