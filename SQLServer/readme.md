# Deploy Azure SQL Database using Azure Bicep

## Background/Scenario

Deploys Azure SQL Database(s)

## Features

- [optional] [Customer-Managed Key for Transparent Data Encryption](https://docs.microsoft.com/en-us/azure/azure-sql/database/transparent-data-encryption-byok-overview) support
  - Key Vault integration
    - Only SQL Server managed identity has access to Key Vault
    - Only Azure Trusted Services are allowed to connect to Key Vault
- Azure Defender Vulnerability Assessment reports
- Secure Storage Account
  - Only SQL Server and Azure Trusted Services can connect
- Create database(s)
  - Specify the name, short term backup policy, size of database, etc. as an object array in the main.parameters.json file

## Prerequisites

- [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/bicep-tutorial-create-first-bicep?tabs=azure-powershell) - Read through the Bicep tutorial to setup your environment.
- An existing Virtual Network with an empty subnet (/27 or larger)
- RBAC roles needed, any combination of the following:
  - Owner
  - User Access Administrator
    - Granting SQL Server Managed Identity access to the storage account for storing Azure Defender Vulnerability Assessment reports
  - Contributor (Not needed if Owner is already assigned)
    - Deployment of all Azure resources:
      - SQL Server and Database(s)
      - Storage Account
      - Key Vault
  - SQL Server Contributor (Not needed if Owner or Contributor roles are assigned)
- Azure AD roles needed for Azure AD Authentication:
  - The SQL Server Managed Identity will need the **Directory Readers** role in order to enable [Azure AD integration](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-directory-readers-role).

## PowerShell Deployment

The steps outlined assumes the deployment is occurring from a workstation configured with Bicep and PowerShell. Other deployment options include Azure CloudShell via CLI or PowerShell which are not covered below. Update the parameters file before deploying.

Example 1: Deploy to Azure Commercial

```powershell
PS C:\repos\ARM\SQLMI> .\deployBicep.ps1
```

Example 2: Deploy to Azure Government with a specific parameters file

```powershell
PS C:\repos\ARM\SQLMI> .\deployBicep.ps1 -AzureEnvironment AzureUSGovernment -TemplateParameterFile .\main.parameters.gov.json
```

Example 3: Deploy to Azure Government with a specific parameters file and Azure AD tenant. The use of the TenantId would be in situations where you are a guest user in the tenant the subscription is associated with.

```powershell
PS C:\repos\ARM\SQLMI> .\deployBicep.ps1 -AzureEnvironment AzureUSGovernment -TemplateParameterFile .\main.parameters.gov.json -TenantId "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## Parameters

Review the following parameters in main.parameters.json before deployment:

|Parameters|Values (description)|
|------------------------------|-----------------------------------------|
|sqlName|Name of SQL Server|
|sqlAdminLogin|SQL Server Admin name|
|setAADAdmins|Set Azure AD Administrators|
|azureADOnlyAuthentication|true, false <br />Azure Active Directory only Authentication enabled|
|principalType|Application, Group, or User <br />Principal Type of the sever administrator|
|login|Login name of the server administrator|
|sid|SID (object ID) of the server administrator|
|tenantId|Tenant ID of the administrator|
|publicNetworkAccess|Disabled, Enabled <br />Whether or not public endpoint access is allowed for this server|
|sqlKeyVaultSkuName|Standard, Premium|
|sqlTDECustomerManagedKey|true = Customer Managed Key <br /> false = Service Managed Key|
|sqlVulnerabilityAssessmentRecurringScans|true, false <br /> Enable or disable Azure Security Center (ASC) SQL Vulnerability Assessment Scans|
|sqlVulnerabilityAssessmentRecurringScansEmailSubAdmins|true, false <br /> Email reports to admins|
|sqlVulnerabilityAssessmentRecurringScansEmails|Array of email addresses to receive ASC reports|
|clientIPcidr|Client IP address (CIDR format) to allow access to storage account vulnerability reports <br /> (example: 13.168.10.0/24)|
|sqlDBTags|Object of TagName: TagValue|

|sqlDatabases - (Array of Object array(s))|Field|Value (description)|
|--------|--------------|-------------------------------|
||**name**| database name|
||**licenseType**|BasePrice or LicenseIncluded|
||**sampleName**|AdventureWorksLT, "" (null string)|
||**dbShortTermRetentionDays**|The backup retention period in days|
||**dbDiffBackupIntervalInHours**|12, 24 (The differential backup interval in hours)|
||**skuName**|refer to [ServiceObjectiveName](databases/databaseSizes.md) column|
||**skuTier**|refer to [Edition](databases/databaseSizes.md) column|
||**skuFamily**|refer to [Family](databases/databaseSizes.md) column|
||**skuCapacity**|refer to [Capacity](databases/databaseSizes.md) column|

## Important

The SQL Server Admin Password is automatically generated and not saved anywhere. You'll need to manually update it in order to log into SQL Server with the admin account.
