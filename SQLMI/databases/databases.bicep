
param sqlMIDatabaseNames array = []
param sqlmiName string = ''
param location string = ''
param tags object = {}
param sqlManagedInstanceCollation string = ''
param dbRetentionDays int = 7
/*
param sqlmiDBsecurityAlertPolicyState string = 'Enabled'
param sqlmiDBsecurityAlertPolicyDisabledAlerts array = []
param sqlmiDBsecurityAlertPolicyEmailAddresses array = []
param sqlmiDBsecurityAlertPolicyEmailAccountAdmins bool = false
*/

// Create a database
resource sqlmiDBs 'Microsoft.Sql/managedInstances/databases@2020-11-01-preview' = [for dbName in sqlMIDatabaseNames: {
  name: '${sqlmiName}/${dbName}'
  location: location
  tags: tags
  dependsOn: []
  properties: {
    collation: sqlManagedInstanceCollation
  }
}]

// Set the backupShortTermRetention for the database
resource sqlmiDBsShortTermRetention 'Microsoft.Sql/managedInstances/databases/backupShortTermRetentionPolicies@2021-02-01-preview' = [for dbName in sqlMIDatabaseNames: {
  name: '${sqlmiName}/${dbName}/default'
  properties: {
    retentionDays: dbRetentionDays
  }
  dependsOn: [
    sqlmiDBs
  ]
}]

// Commenting out because the SQL MI databases inherit the settings from the instance
/*
// Set the database Security Alert Policies
resource sqlmiDBsSecurityAlertPolicies 'Microsoft.Sql/managedInstances/databases/securityAlertPolicies@2021-02-01-preview' = [for dbName in sqlMIDatabaseNames: {
  name: '${sqlmiName}/${dbName}/Default'
  properties: {
    state: sqlmiDBsecurityAlertPolicyState
    disabledAlerts: sqlmiDBsecurityAlertPolicyDisabledAlerts
    emailAddresses: sqlmiDBsecurityAlertPolicyEmailAddresses
    emailAccountAdmins: sqlmiDBsecurityAlertPolicyEmailAccountAdmins
  }
}]
*/
