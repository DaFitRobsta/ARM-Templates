param location string
param sqlmiSubnetAddressPrefix string
param subnetName string
param sqlmiNSGid string
param tags object
param vnetName string
param nsgName string

resource sqlmiNSG  'Microsoft.Network/networkSecurityGroups@2020-07-01' = if (empty(sqlmiNSGid)){
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

// Assign NSG to subnet
resource sqlmiSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = if(empty(sqlmiNSGid)){
  name: subnetName
  properties: {
    addressPrefix: sqlmiSubnetAddressPrefix
    networkSecurityGroup: {
      id: sqlmiNSG.id
    }
  }
  dependsOn: [
    sqlmiNSG
  ]
}

output nsgNameout string = nsgName
output subnetName string = subnetName
output nsgId string = sqlmiNSG.id 
