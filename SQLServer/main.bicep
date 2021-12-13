param sqlName string
param sqlAdministratorLogin string
param sqlDBTags object = {}

param setAADAdmins bool = false
@description('Principal Type of the sever administrator. Values include Application, Group, User')
param principalType string
param azureADOnlyAuthentication bool = false
param login string
param sid string
param tenantId string

param publicNetworkAccess string = 'Enabled'

param sqlKeyVaultSkuName string
param sqlTDECustomerManagedKey bool = false

@description('SQL Collation')
param sqlCollation string = 'SQL_Latin1_General_CP1_CI_AS'

param sqlDatabases array = []
@description('Client IP CIDR to allow access to storage account')
param clientIPcidr string

// Specify vulnerability assessment parameters
param sqlVulnerabilityAssessmentRecurringScans bool = true
param sqlVulnerabilityAssessmentRecurringScansEmailSubAdmins bool = true
param sqlVulnerabilityAssessmentRecurringScansEmails array = []

var location = resourceGroup().location

//@description('Admin user password - must be 16-128 characters, must contain 3 of uppercase, lowercase, numbers and non-alphanumeric characters, and cannot contain all or part of the login name')
var sqlPassword = 'P${uniqueString(resourceGroup().id)}-${uniqueString(subscription().id)}x!'

//Set Administrators
var setAdmins = {
  administratorType: 'ActiveDirectory'
  azureADOnlyAuthentication: azureADOnlyAuthentication
  principalType: principalType
  login: login
  sid: sid
  tenantId: tenantId
}

// Create a storage account for the Azure Defender Vulnerablity Assessments
var storageAccountName = 'sql${uniqueString(sqlName)}'
module createStorage 'storageaccount/storageaccount.bicep' = {
  name: 'createStorageAccount'
  params: {
   location: location
   storKind: 'StorageV2'
   storSKU: 'Standard_LRS'
   storName: storageAccountName
   subnetID: ''
   clientIPcidr: clientIPcidr
  }
  dependsOn: []
}

resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlPassword
    minimalTlsVersion: '1.2'
    version: '12.0'
    publicNetworkAccess: publicNetworkAccess
    administrators: setAADAdmins ? setAdmins : {}
    restrictOutboundNetworkAccess: 'Disabled'
  }
  tags: sqlDBTags
}

// Create a sql Key Vault for BYOK/CMK with key
var sqlKeyVaultName = 'kv-${uniqueString(sqlName)}-01'
module createKV 'tde/keyvault.bicep' = if(sqlTDECustomerManagedKey) {
  name: 'DeployKeyVault'
  params: {
    location: location
    sqlIdentity: sqlServer.identity.principalId
    sqlKeyVaultName: sqlKeyVaultName
    sqlKeyVaultSkuName: sqlKeyVaultSkuName
    sqlName: sqlName
    tags: sqlDBTags 
  } 
}

// Assign SQL Server Identity to storage account
module assignSqlServerToResourceGroup 'storageaccount/grantSqlServerAccess.bicep' = {
  name: 'assignSqlServerToResourceGroup'
  params: {
    sqlServerIdentity: sqlServer.identity.principalId
  }
}

// SQL Firewall
resource sqlServer_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  name: '${sqlServer.name}/AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Enable SQL Auditing at the Server level
// reference: https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/auditingsettings?tabs=bicep
resource sqlServerAuditing 'Microsoft.Sql/servers/auditingSettings@2021-02-01-preview' = {
  name: '${sqlServer.name}/default'
  properties: {
    state: 'Enabled'
    auditActionsAndGroups: [
      'BATCH_COMPLETED_GROUP'
      'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
    ]
    retentionDays: 90 //replace with parameter
    storageEndpoint: createStorage.outputs.storageAccountBlobUri
  }
}

// Setup SQL Server Security Alert Policies
resource setSQLSecurityAlertPolicies 'Microsoft.Sql/servers/securityAlertPolicies@2021-02-01-preview' = {
  name: '${sqlServer.name}/Default'
  properties: {
    state: 'Enabled'
  }
}

// Set vulnerability assessment path for storage account
var storageAccountContainerPath = '${createStorage.outputs.storageAccountBlobUri}vulnerability-assessment'
// Setup Azure Defender vulnerability assessments
// reference: https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-database-vulnerability-assessment-storage
resource sqlmiVulnerabilityAssessments 'Microsoft.Sql/servers/vulnerabilityAssessments@2021-02-01-preview' = {
  name: '${sqlServer.name}/Default'
  properties: {
    recurringScans: {
      isEnabled: sqlVulnerabilityAssessmentRecurringScans
      emailSubscriptionAdmins: sqlVulnerabilityAssessmentRecurringScansEmailSubAdmins
      emails: sqlVulnerabilityAssessmentRecurringScansEmails
    }
    storageContainerPath: storageAccountContainerPath
  }
  dependsOn: [
    createStorage
    setSQLSecurityAlertPolicies
  ] 
}

// Create the databases based on the parameter sqlMIDatabaseNames
module createSqlmiDBs 'databases/databases.bicep' = {
  name: 'createDBs'
  params: {
    tags: sqlDBTags
    location: location
    sqlManagedInstanceCollation: sqlCollation
    sqlName: sqlServer.name
    sqlDatabases: sqlDatabases
  }
  dependsOn: []
}
