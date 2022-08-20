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
param adminUsername string = 'adm.infra.usr'
param storeAdminPasswordInKeyVault bool = false
@description('List of client IP address(es) in CIDR notation')
param clientIPcidr array = [
  '134.114.0.0/16'
  '8.8.8.8/32'
]

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
    addressPrefix: replace(vnetAddressPrefix, '/24', '/26') //'172.16.0.0/26'
    nsgName: '${vnetName}-bastion-nsg'
  }
  {
    name: vnetJumpboxSubnetName
    addressPrefix: '${substring(vnetAddressPrefix, 0, lastIndexOf(vnetAddressPrefix, '.'))}.192/27' //'172.16.0.192/27'
    nsgName: '${vnetName}-${vnetJumpboxSubnetName}-nsg'
  }
  {
    name: vnetPrivateEndpointSubnetName
    addressPrefix: '${substring(vnetAddressPrefix, 0, lastIndexOf(vnetAddressPrefix, '.'))}.64/26' //'172.16.0.64/26'
    nsgName: '${vnetName}-${vnetPrivateEndpointSubnetName}-nsg'
  }
]

@description('Key Vault name')
param sqlAdminKeyVaultName string ='kv-sqladm${uniqueString(resourceGroup().id)}'
@allowed([
  'standard'
  'premium'
])
param sqlAdminKeyVaultSkuName string = 'standard'

@description('Storage Account Name')
param storageAccountName string = 'stasqladm${uniqueString(resourceGroup().id)}'

param privateDnsZoneNames array = [
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink${environment().suffixes.sqlServerHostname}'
]

@description('Azure Bastion Resource Name')
param bastionHostName string = 'sqlAdminBastion'

@description('Tags for deployed resources.')
param Tags object = {}

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
    Tags: Tags
  }
}

// create private dns zones and link to virtual network
module createPrivateDnsZonesAndLinks 'network/private-dns-zone.bicep' = {
  name: 'createPrivateDnsZonesAndLinks'
  params: {
    privateDnsZoneNames: privateDnsZoneNames
    vnetId: createVirtualNetwork.outputs.vnetId
    vnetName: vnetName
    Tags: Tags
  }
}

// create SQL Admins Key Vault
module createKeyVault 'keyvault/keyvault.bicep' = {
  name: 'createKeyVault'
  params: {
    location: location
    sqlAdminKeyVaultName: sqlAdminKeyVaultName
    sqlAdminKeyVaultSkuName: sqlAdminKeyVaultSkuName
    ipRules: [for IP in clientIPcidr:{
      value: IP
    } ]
    Tags: Tags
  }
}

// create SQL Admins storage account
module createSqlAdminStorageAccount 'storageaccount/storageaccount.bicep' = {
  name: 'createSqlAdminStorageAccount'
  dependsOn: [
    createVirtualNetwork
  ]
  params: {
    location: location
    clientIPcidr: clientIPcidr
    storName: storageAccountName
    subnetIDs: [
      jumpboxSubnet.id
    ]
    Tags: Tags
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
    location: location
    blobPrivateDnsZoneId: blobPrivateDnsZone.id
    blobStorageAccountFQDN: createSqlAdminStorageAccount.outputs.blobStorageAccountFQDN
    blobStorageAccountId: createSqlAdminStorageAccount.outputs.storageAccountId
    blobStorageAccountPrivateEndpointName: '${createSqlAdminStorageAccount.outputs.storageAccountName}-pe'
    subnetId: privateEndpointSubnet.id
    privateDnsZoneConfigName: replace('privatelink.blob.${environment().suffixes.storage}','.', '-')
    Tags: Tags
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
    Tags: Tags
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
    sqlAdminKeyVaultName: createKeyVault.outputs.keyVaultName
    adminUsername: adminUsername
    storeAdminPasswordInKeyVault: storeAdminPasswordInKeyVault
    Tags: Tags
  }
}]
