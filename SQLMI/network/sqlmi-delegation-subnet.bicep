param sqlmiSubnetAddressPrefix string
param subnetName string
param sqlManagedInstanceName string
param subnetDelegations string
param vnetName string

resource sqlmiSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = if (empty(subnetDelegations)){
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
  }
}
