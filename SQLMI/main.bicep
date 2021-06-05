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

@minValue(1)
@maxValue(35)
@description('Specify how long you want to keep your point-in-time backups. Default value is 7 days')
param dbRetentionDays int = 7

// Specify Azure AD Administrator Login
param sqlManagedInstanceEnableAADAuthentication bool = false
param sqlManagedInstanceAdministratorAADLogin string = ''
param sqlManagedInstanceAdministratorAADSID string = ''
param sqlManagedInstanceAdministratorAADTenantID string = ''

// Specify whether or not to only allow AAD authentication
param sqlManagedInstanceAADonlyAuthentication bool = false

// Specify vulnerability assessment parameters
param sqlmiVulnerabilityAssessmentRecurringScans bool = true
param sqlmiVulnerabilityAssessmentRecurringScansEmailSubAdmins bool = true
param sqlmiVulnerabilityAssessmentRecurringScansEmails array = []

// Security Alert parameters
//param 

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
var sqlmiSubnetNSGid = contains(subnet.properties, 'networkSecurityGroup') ? subnet.properties.networkSecurityGroup.id : ''
var sqlmiSubnetUDRid = contains(subnet.properties, 'routeTable') ? subnet.properties.routeTable.id : ''
var sqlmiSubnetAddressPrefix = subnet.properties.addressPrefix
var sqlmiSubnetServiceEndpoints = contains(subnet.properties, 'serviceEndpoints') ? subnet.properties.serviceEndpoints : []

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
    udrName: '${vnetName}-${managedInstanceSubnetName}-UDR'
    tags: sqlManagedInstanceTags
    sqlmiUDRid: sqlmiSubnetUDRid
    sqlmiSubnetServiceEndpoints: sqlmiSubnetServiceEndpoints
  }
  dependsOn: [
    subnet
  ]  
}

// Create a storage account for the Azure Defender Vulnerablity Assessments
var storageAccountName = 'sql${uniqueString(sqlManagedInstanceName)}'
module createStorage 'storageaccount/storageaccount.bicep' = {
  name: 'createStorageAccount'
  params: {
   location: location
   storKind: 'StorageV2'
   storSKU: 'Standard_LRS'
   storName: storageAccountName
   subnetID: subnet.id
  }
  dependsOn: [
    checkSqlMiSubnet
  ]
}
// Get access key of storage account
var storageAccountAccessKey = createStorage.outputs.storageAccountAccessKey
var storageAccountContainerPath = '${createStorage.outputs.storageAccountBlobUri}vulnerability-assessment'

// Create a Key Vault

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

// Set AAD authentication for SQL MI
resource sqlmiAADauthentication 'Microsoft.Sql/managedInstances/administrators@2020-11-01-preview' = if (sqlManagedInstanceEnableAADAuthentication) {
  name: '${sqlmi.name}/ActiveDirectory'
  properties:{
    administratorType: 'ActiveDirectory'
    login: sqlManagedInstanceAdministratorAADLogin
    sid: sqlManagedInstanceAdministratorAADSID
    tenantId: sqlManagedInstanceAdministratorAADTenantID
  }
}

// Set AAD only Authentication for SQL MI
resource sqlmiAADonlyAuthentication 'Microsoft.Sql/managedInstances/azureADOnlyAuthentications@2020-11-01-preview' = if (sqlManagedInstanceAADonlyAuthentication) {
  name: '${sqlmi.name}/Default'
  properties: {
    azureADOnlyAuthentication: sqlManagedInstanceAADonlyAuthentication
  }  
}

// Assign SQL MI Identity to storage account
module assignSqlmiToResourceGroup 'storageaccount/grantSqlMiAccess.bicep' = {
  name: 'assignSqlmiToResourceGroup'
  params: {
    sqlmiIdentity: sqlmi.identity.principalId
  }
}
// Enable Azure Defender
resource sqlmiSecurityAlertPolicies 'Microsoft.Sql/managedInstances/securityAlertPolicies@2021-02-01-preview' = {
  name: '${sqlmi.name}/Default'
  properties: {
   state: 'Enabled'
   //storageAccountAccessKey: storageAccountAccessKey
   //storageEndpoint: createStorage.outputs.storageAccountBlobUri
  }
  dependsOn: [
    createStorage
  ]
}

// Setup Azure Defender vulnerability assessments
resource sqlmiVulnerabilityAssessments 'Microsoft.Sql/managedInstances/vulnerabilityAssessments@2021-02-01-preview' = {
  name: '${sqlmi.name}/Default'
  properties: {
    recurringScans: {
      isEnabled: sqlmiVulnerabilityAssessmentRecurringScans
      emailSubscriptionAdmins: sqlmiVulnerabilityAssessmentRecurringScansEmailSubAdmins
      emails: sqlmiVulnerabilityAssessmentRecurringScansEmails
    }
    storageContainerPath: storageAccountContainerPath
    //storageAccountAccessKey: storageAccountAccessKey
  }
  dependsOn: [
    createStorage
    sqlmiSecurityAlertPolicies
  ] 
}

// Create the databases based on the parameter sqlMIDatabaseNames
module createSqlmiDBs 'databases/databases.bicep' = {
  name: 'createDBs'
  params: {
   dbRetentionDays: dbRetentionDays
   location: location
   sqlManagedInstanceCollation: sqlManagedInstanceCollation
   sqlMIDatabaseNames: sqlMIDatabaseNames
   sqlmiName: sqlmi.name
   tags: sqlManagedInstanceTags
  }
  dependsOn: [
    sqlmiVulnerabilityAssessments
  ]
}
