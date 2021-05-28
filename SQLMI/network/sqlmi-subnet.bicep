param location string
param sqlmiSubnetAddressPrefix string
param sqlManagedInstanceName string
param subnetName string
param sqlmiNSGid string
param sqlmiUDRid string
param subnetDelegations string
param tags object
param vnetName string
param nsgName string
param udrName string


// Create a new NSG if one is not already assigned to subnet
resource sqlmiNSG  'Microsoft.Network/networkSecurityGroups@2020-07-01' = if (empty(sqlmiNSGid)){
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

// Create a new UDR if one is not already assigned to subnet
resource sqlmiUDR 'Microsoft.Network/routeTables@2020-11-01' = if (empty(sqlmiUDRid)){
  name: udrName
  location: location
  tags: tags
  properties: {
    routes: []
  }
}

// Assign delgation, NSG, and UDR to subnet if it's not already setup
resource sqlmiNewNsgAndUdrSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = if((empty(sqlmiNSGid) && empty(sqlmiUDRid)) || (empty(sqlmiNSGid) && !empty(sqlmiUDRid)) || (!empty(sqlmiNSGid) && empty(sqlmiUDRid)) || (!empty(sqlmiNSGid) && !empty(sqlmiUDRid) && empty(subnetDelegations))){
  name: subnetName
  properties: {
    addressPrefix: sqlmiSubnetAddressPrefix
    delegations: [
      {
        name: sqlManagedInstanceName
        properties:{
          serviceName: 'Microsoft.Sql/managedInstances'
        }
      }
    ]
    networkSecurityGroup: {
      id: empty(sqlmiNSGid) ? sqlmiNSG.id : sqlmiNSGid
    }
    routeTable: {
      id: empty(sqlmiUDRid) ? sqlmiUDR.id : sqlmiUDRid
    }    
  }
}


output nsgNameout string = nsgName
output subnetName string = subnetName
output nsgId string = sqlmiNSG.id 
