@description('Name of the SQL MI')
param sqlManagedInstanceName string = 'ois-drm-dev-gaz-sqlmi-01'
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

@description('Name of the existing VNET')
param vnetResourceName string = 'VN-OIS-DRM-SQL-DEV01'

@description('Name of the existing subnet')
param managedInstanceSubnetName string = 'SN-OIS-DRM-SQLMI-DEV01'

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

@description('Tags for the Managed Instance SQL resource.')
param sqlManagedInstanceTags object = {}

// Referencing an existing Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetResourceName
}

resource sqlmi 'Microsoft.Sql/managedInstances@2020-11-01-preview' = {
  name: sqlManagedInstanceName
  location: location
  tags: sqlManagedInstanceTags
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
    subnetId: '${vnet.id}/subnets/${managedInstanceSubnetName}'
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
