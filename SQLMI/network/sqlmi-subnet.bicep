param location string
param sqlmiSubnetAddressPrefix string
param sqlManagedInstanceName string
param subnetName string
param sqlmiNSGid string
param sqlmiUDRid string
param setSqlmiSubnetServiceEndpoints bool = false

var sqlmiServiceEndpointStorage = [
  {
    service: 'Microsoft.Storage'
    locations: [
      location
    ]
  }
]

// Assign delgation, NSG, and UDR to subnet if it's not already setup
// if((empty(sqlmiNSGid) && empty(sqlmiUDRid)) || (empty(sqlmiNSGid) && !empty(sqlmiUDRid)) || (!empty(sqlmiNSGid) && empty(sqlmiUDRid)) || (!empty(sqlmiNSGid) && !empty(sqlmiUDRid) && empty(subnetDelegations)) || (!empty(sqlmiNSGid) && !empty(sqlmiUDRid) && !empty(subnetDelegations) && empty(sqlmiSubnetServiceEndpoints)))
resource sqlmiNewNsgAndUdrSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
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
      id: sqlmiNSGid
    }
    routeTable: {
      id: sqlmiUDRid
    }
    serviceEndpoints: (setSqlmiSubnetServiceEndpoints == true) ? sqlmiServiceEndpointStorage : []
  }
}


output subnetName string = subnetName
output nsgId string = sqlmiNewNsgAndUdrSubnet.properties.networkSecurityGroup.id
output udrId string = sqlmiNewNsgAndUdrSubnet.properties.routeTable.id
output subnetServiceEndpoints array = sqlmiNewNsgAndUdrSubnet.properties.serviceEndpoints
