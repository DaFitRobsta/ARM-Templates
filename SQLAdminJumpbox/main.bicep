// Create two resource groups (Allow user to specify region)
// Allow user to add a prefix to the static suffix
// connectivity
// jumpboxes

// Virtual Network (check)
// Subnets (check)
// NSGs (check)

// Private DNS Zones (check)
// Link to Virtual Network (check)

// Storage account (check)
// Set Private Endpoint (check)

// Bastion (check)

// SQL Jumpbox(es)

@description('VM Prefix Name. Example sqlAdminJmp. We will add -0# as a suffix')
param vmNamePrefix string
@description('Number of SQL Admin VMs')
param numberOfVMs int = 1

@description('VNet name')
param vnetName string = 'nz-wu3-sqlAdmins-vnet01'
@description('Address prefix')
param vnetAddressPrefix string = '172.16.0.0/24'
@description('Sql admin jumpbox(es) subnet name')
param vnetJumpboxSubnetName string = 'sql-jumpboxes-sn'
param vnetPrivateEndpointSubnetName string = 'private-endpoints-sn'
@description('Set Service Endpoints')
param setSubnetServiceEndpoints bool = true

@description('Object array defining the subnets')
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

@description('Storage Account Name')
param storageAccountName string = 'stasqladm${uniqueString(resourceGroup().id)}'

param privateDnsZoneNames array = [
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink${environment().suffixes.sqlServerHostname}'
]

@description('Azure Bastion Resource Name')
param bastionHostName string = 'sqlAdminBastion'

var location = resourceGroup().location

module createVirtualNetwork 'network/vnet.bicep' = {
  name: 'createVirtualNetwork'
  params: {
    location: location
    vnetName: vnetName
    subnets: subnets
    vnetJumpboxSubnetName: vnetJumpboxSubnetName
    vnetAddressPrefix: vnetAddressPrefix
    vnetPrivateEndpointSubnetName: vnetPrivateEndpointSubnetName
    setSubnetServiceEndpoints: setSubnetServiceEndpoints
  }
}

// create private dns zones and link to virtual network
module createPrivateDnsZonesAndLinks 'network/private-dns-zone.bicep' = {
  name: 'createPrivateDnsZonesAndLinks'
  params: {
    privateDnsZoneNames: privateDnsZoneNames
    vnetId: createVirtualNetwork.outputs.vnetId
    vnetName: vnetName
  }
}


// create SQL Admins storage account
module createSqlAdminStorageAccount 'storageaccount/storageaccount.bicep' = {
  name: 'createSqlAdminStorageAccount'
  dependsOn: [
    createVirtualNetwork
  ]
  params: {
    clientIPcidr: '134.114.0.0/16'
    storName: storageAccountName
    subnetIDs: [
      jumpboxSubnet.id
    ]
  }
}

// Reference existing private endpoint subnet
resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: '${vnetName}/${vnetPrivateEndpointSubnetName}'
}

// Reference blob private DNS zone
resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
}

// create Sql Admins Storage Account Private Endpoint and register it in Private DNS Zone
module createSqlAdminBlobStorageAccountPrivateEndpoint 'storageaccount/blobPrivateEndpoint.bicep' = {
  name: 'createSqlAdminBlobStorageAccountPrivateEndpoint'
  dependsOn: [
    createVirtualNetwork
  ]
  params: {
    blobPrivateDnsZoneId: blobPrivateDnsZone.id
    blobStorageAccountFQDN: createSqlAdminStorageAccount.outputs.blobStorageAccountFQDN
    blobStorageAccountId: createSqlAdminStorageAccount.outputs.storageAccountId
    blobStorageAccountPrivateEndpointName: '${createSqlAdminStorageAccount.outputs.storageAccountName}-pe'
    subnetId: privateEndpointSubnet.id
    privateDnsZoneConfigName: replace('privatelink.blob.${environment().suffixes.storage}','.', '-')
  }
}

// Create Azure Bastion
module createSqlBastion 'network/bastion.bicep' = {
  name: 'createSqlBastion'
  params: {
    bastionHostName: bastionHostName
    vnetNewOrExisting: 'existing'
    vnetSubnetNewOrExisting: 'existing'
    vnetName: createVirtualNetwork.outputs.vnetName
    location: location
  }
}

// Reference existing jumpbox subnet
resource jumpboxSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: '${vnetName}/${vnetJumpboxSubnetName}'
}

// Create SQL Admin Jumpbox(es)
module createSqlAdminJumpbox 'compute/jumpboxVM.bicep' = [for i in range(1, numberOfVMs) : {
  name: 'createSqlAdminJumpbox-${i}'
  dependsOn: [
    createVirtualNetwork
  ]
  params: {
    location: location
    subnetRef: jumpboxSubnet.id
    vmName: format('{0}-{1:00}', vmNamePrefix, i) 
  }
}]
