@description('Name of the SQL MI')
param sqlManagedInstanceName string = 'dz-wu1-dev-sqlmi-01'
param location string = resourceGroup().location

@allowed([
  'GeneralPurpose'
  'BusinessCritical'
])
@description('SKU Edition (GeneralPurpose, BusinessCritical)')
param sqlManagedInstanceSkuEdition string = 'GeneralPurpose'

@allowed([
  'GP_Gen4'
  'GP_Gen5'
  'BC_Gen4'
  'BC_Gen5'
])
@description('SKU NAME (GP_Gen4, GP_Gen5, BC_Gen4, BC_GEN5)')
param sqlManagedInstanceSkuName string = 'GP_Gen5'

@allowed([
  'Gen4'
  'Gen5'
])
@description('Hardware family (Gen4, Gen5)')
param sqlManagedInstanceHardwareFamily string = 'Gen5'

@description('Name of the existing VNET\'s Resource Group')
param vnetResourceGroupName string = 'dz-wu1-net-np-rg01'

@description('Name of the existing VNET')
param vnetName string = 'dz-wu1-net-np-vnet01'

@description('Name of the existing subnet')
param managedInstanceSubnetName string = 'sqlmi-sn'

@description('Admin user for Managed Instance')
param sqlManagedInstanceAdminLogin string

@secure()
@description('Admin user password - must be 16-128 characters, must contain 3 of uppercase, lowercase, numbers and non-alphanumeric characters, and cannot contain all or part of the login name')
param sqlManagedInstancePassword string

@description('Amount of Storage in GB for this instance. Minimum value: 32. Maximum value: 8192. Increments of 32 GB allowed only.')
param sqlManagedInstanceStorageSizeInGB int = 32

@allowed([
  4
  8
  16
  24
  32
  40
  64
  80
])
@description('The number of vCores. Allowed values: 4, 8, 16, 24, 32, 40, 64, 80.')
param sqlManagedInstancevCores int = 4

@allowed([
  'BasePrice'
  'LicenseIncluded'
])
@description('Type of license: BasePrice (BYOL) or LicenceIncluded')
param sqlManagedInstanceLicenseType string = 'BasePrice'

@description('SQL Collation')
param sqlManagedInstanceCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('Id of the timezone. Allowed values are timezones supported by Windows. List of Ids can also be obtained by executing [System.TimeZoneInfo]::GetSystemTimeZones() in PowerShell.')
param sqlManagedInstanceTimeZoneId string = 'Pacific Standard Time'

@description('Minimal TLS version. Allowed values: None, 1.0, 1.1, 1.2')
param sqlManagedInstanceMinimalTlsVersion string = '1.2'

@description('The storage account type used to store backups for this instance. The options are LRS (LocallyRedundantStorage), ZRS (ZoneRedundantStorage) and GRS (GeoRedundantStorage). - GRS, LRS, ZRS')
param sqlManagedInstanceStorageAccountType string = 'LRS'

@allowed([
  'Proxy'
  'Redirect'
  'Default'
])
@description('Connection type used for connecting to the instance. - Proxy, Redirect, Default')
param sqlManagedInstanceProxyOverride string = 'Redirect'

@description('Tags for the Managed Instance SQL resources.')
param sqlManagedInstanceTags object = {}

@description('Provide a comma seperated quoted Database names')
param sqlMIDatabaseNames array = [
  'forRobert'
  'forGary'
  'DW'
]

// Referencing an existing Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}

// Need a reference to an existing subnet to determine if it's already been delegated to SQL MI
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${managedInstanceSubnetName}'
  scope: resourceGroup(vnetResourceGroupName)
}

// Retrieve properties of the subnet, like delegation, NSG, and UDR
var sqlmiSubnetDelegations = !empty(subnet.properties.delegations) ? subnet.properties.delegations[0].properties.serviceName : ''
//var sqlmiSubnetNSGid = !empty(subnet.properties.networkSecurityGroup) ? subnet.properties.networkSecurityGroup.id : ''
var sqlmiSubnetNSGid = contains(subnet.properties, 'networkSecurityGroup') ? subnet.properties.networkSecurityGroup.id : ''
//var sqlmiSubnetUDRid = !empty(subnet.properties.routeTable) ? subnet.properties.routeTable.id : ''
var sqlmiSubnetUDRid = contains(subnet.properties, 'routeTable') ? subnet.properties.routeTable.id : ''
var sqlmiSubnetAddressPrefix = subnet.properties.addressPrefix

// Since sqlmiSubnetDelegations can't be evaluated in the main.bicep, we are passing it into another module for evalution. If
// sqlmiSubnetDelegations is empty, then the ARM template will add Microsoft.SQL/managedInstances as a delegation to the subnet
module checkSqlMiSubnet 'network/sqlmi-subnet.bicep' = {
  name: 'checkSqlMiSubnet'
  scope: resourceGroup(vnetResourceGroupName)
  params: {
    location: location
    nsgName: '${vnetName}-${managedInstanceSubnetName}-NSG'
    sqlmiNSGid: sqlmiSubnetNSGid
    sqlmiSubnetAddressPrefix: sqlmiSubnetAddressPrefix
    subnetName: subnet.name
    sqlManagedInstanceName: sqlManagedInstanceName
    subnetDelegations: sqlmiSubnetDelegations
    vnetName: vnet.name
    udrName: '${vnetName}-${managedInstanceSubnetName}-UDR'
    tags: sqlManagedInstanceTags
    sqlmiUDRid: sqlmiSubnetUDRid
  }
  dependsOn: [
    subnet
  ]  
}
/*
module addSqlMiDelegationSubnet 'network/sqlmi-delegation-subnet.bicep' = {
  name: 'addSqlMiDelegationSubnet'
  scope: resourceGroup(vnetResourceGroupName)
  params: {
    subnetName: subnet.name
    sqlManagedInstanceName: sqlManagedInstanceName
    subnetDelegations: sqlmiSubnetDelegations
    sqlmiSubnetAddressPrefix: sqlmiSubnetAddressPrefix
    vnetName: vnet.name
  }
  dependsOn: [
    subnet
  ]
}

// Determine if NSG exists, if not, create NSG and assign it to the subnet
module addNSGtoSubnet 'network/sqlmi-nsg.bicep' = {
  name: 'addNSGtoSubnet'
  scope: resourceGroup(vnetResourceGroupName)
  params: {
    subnetName: subnet.name
    vnetName: vnet.name
    location: location
    nsgName: '${vnetName}-${managedInstanceSubnetName}-NSG'
    tags: sqlManagedInstanceTags
    sqlmiNSGid: sqlmiSubnetNSGid
    sqlmiSubnetAddressPrefix: sqlmiSubnetAddressPrefix
  }
  dependsOn: [
    subnet
    addSqlMiDelegationSubnet
  ]
}

// Determine if UDR exists, if not, create UDR and assign it to the subnet
module addUDRtoSubnet 'network/sqlmi-udr.bicep' = {
  name: 'addUDRtoSubnet'
  scope: resourceGroup(vnetResourceGroupName)
  params: {
    subnetName: subnet.name
    vnetName: vnet.name
    location: location
    udrName: '${vnetName}-${managedInstanceSubnetName}-UDR'
    tags: sqlManagedInstanceTags
    sqlmiUDRid: sqlmiSubnetUDRid
    sqlmiSubnetAddressPrefix: sqlmiSubnetAddressPrefix
  }
  dependsOn: [
    subnet
    addSqlMiDelegationSubnet
    addNSGtoSubnet
  ]
}
*/
// Create the SQL MI resource
resource sqlmi 'Microsoft.Sql/managedInstances@2020-11-01-preview' = {
  name: sqlManagedInstanceName
  location: location
  tags: sqlManagedInstanceTags
  dependsOn: [
    checkSqlMiSubnet
  ]
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: sqlManagedInstanceSkuName
    tier: sqlManagedInstanceSkuEdition
    family: sqlManagedInstanceHardwareFamily
  }
  properties: {
    administratorLogin: sqlManagedInstanceAdminLogin
    administratorLoginPassword: sqlManagedInstancePassword
    subnetId: subnet.id
    licenseType: sqlManagedInstanceLicenseType
    vCores: sqlManagedInstancevCores
    storageSizeInGB: sqlManagedInstanceStorageSizeInGB
    collation: sqlManagedInstanceCollation
    publicDataEndpointEnabled: false
    proxyOverride: sqlManagedInstanceProxyOverride
    timezoneId: sqlManagedInstanceTimeZoneId
    minimalTlsVersion: sqlManagedInstanceMinimalTlsVersion
    storageAccountType: sqlManagedInstanceStorageAccountType
    zoneRedundant: false
  }
}

// Create the databases based on the parameter sqlMIDatabaseNames
resource sqlmiDBs 'Microsoft.Sql/managedInstances/databases@2020-11-01-preview' = [for dbName in sqlMIDatabaseNames: {
  name: '${sqlmi.name}/${dbName}'
  location: location
  tags: sqlManagedInstanceTags
  dependsOn: [
    sqlmi
  ]
  properties: {
    collation: sqlManagedInstanceCollation
  }
}]
