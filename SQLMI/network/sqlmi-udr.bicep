param location string
param sqlmiSubnetAddressPrefix string
param subnetName string
param sqlmiUDRid string
param tags object
param vnetName string
param udrName string

resource sqlmiUDR 'Microsoft.Network/routeTables@2020-11-01' = if (empty(sqlmiUDRid)){
  name: udrName
  location: location
  tags: tags
  properties: {
    routes: []
  }
}

// Assign UDR to subnet
resource sqlmiSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = if(empty(sqlmiUDRid)){
  name: subnetName
  properties: {
    addressPrefix: sqlmiSubnetAddressPrefix
    routeTable: {
       id: sqlmiUDR.id 
    }
  }
  dependsOn: [
    sqlmiUDR
  ]
}
