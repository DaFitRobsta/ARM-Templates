# Deploy SQL MI into an existing Azure Virtual Network using Azure Bicep

## Background/Scenario

There are situations where AppDevOps teams will need to deploy resources into an existing virtual network infrastructure. This deployment covers such a situation and assumes the virtual network/subnet already exists. What isn't assumed is an existing NSG or UDR already assigned to the subnet. If either a NSG or UDR are not already assigned, the deployment user will need to have at a minimum, Network Contributor rights. SQL MI requires a NSG, UDR, and Microsoft.SQL/ManagedInstance delegation on the subnet before it can deploy successfully.

This deployment checks for those network requirements before starting the deployment of SQL Managed Instance.

## Features

- [optional] [Customer-Managed Key for Transparent Data Encryption](https://docs.microsoft.com/en-us/azure/azure-sql/database/transparent-data-encryption-byok-overview) support
  - Key Vault integration
    - Only SQL MI managed identity has access to Key Vault
    - Only Azure Trusted Services are allowed to connect to Key Vault
- Azure Defender Vulnerability Assessment reports
  - Specify which email addresses receives an email
- Secure Storage Account
  - Only SQL MI subnet and Azure Trusted Services can connect
- Create many databases by specifying their names as an array parameter in the main.parameters.json file

## Prerequisites

- [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/bicep-tutorial-create-first-bicep?tabs=azure-powershell) - Read through the Bicep tutorial to setup your environment.
- An existing Virtual Network with an empty subnet (/27 or larger)
- RBAC roles needed, any combination of the following:
  - Owner
  - User Access Administrator
    - Granting SQL MI Managed Identity access to the storage account for storing Azure Defender Vulnerability Assessment reports
  - Contributor (Not needed if Owner is already assigned)
    - Deployment of all Azure resources:
      - Network Security Group (NSG)
      - Route Table (UDR)
      - SQL Managed Instance
      - Storage Account
      - Key Vault
  - Network Contributor or SQL Managed Instance Contributor (Not needed if Owner or Contributor roles are assigned)
    - Updating virtual network/subnet delegation to SQLMI
    - Creating NSG and/or UDR if one doesn't already exists on subnet
- Azure AD roles needed for Azure AD Authentication:
  - The SQL MI Managed Identity will need the **Directory Readers** role in order to enable [Azure AD integration](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-directory-readers-role).

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
|sqlManagedInstanceName|Name of SQL MI|
|sqlManagedInstanceSkuEdition|GeneralPurpose, BusinessCritical|
|sqlManagedInstanceSkuName|GP_Gen5, BC_Gen5|
|vnetName|Name of the SQL MI Virtual Network|
|vnetResourceGroupName|SQL MI Virtual Network Resource Group Name|
|managedInstanceSubnetName|SQL MI Subnet name|
|sqlManagedInstanceAdminLogin|SQL MI Admin name|
|sqlManagedInstanceStorageSizeInGB|Minimum value: 32 <br />Maximum value: 8192. Increments of 32 GB allowed only|
|sqlManagedInstanceStorageAccountType|LRS, ZRS, GRS|
|sqlManagedInstancevCores|4, 8, 16, 24, 32, 40, 64, 80|
|sqlManagedInstanceLicenseType|BasePrice (BYOL), LicenceIncluded|
|sqlManagedInstanceProxyOverride|Proxy, Redirect, Default|
|sqlManagedInstanceTimeZoneId|Id of the timezone. Allowed values are timezones supported by Windows. List of Ids can also be obtained by executing [System.TimeZoneInfo]::GetSystemTimeZones() in PowerShell.|
|sqlmiKeyVaultSkuName|Standard, Premium|
|sqlmiTDECustomerManagedKey|true = Customer Managed Key <br /> false = Service Managed Key|
|sqlManagedInstanceEnableAADAuthentication|true, false <br />Enable Azure AD Authentication?|
|sqlManagedInstanceAdministratorAADLogin|AAD Login name of the server administrator|
|sqlManagedInstanceAdministratorAADSID|SID (object ID) of the server administrator|
|sqlManagedInstanceAdministratorAADTenantID|Tenant ID of the administrator|
|dbRetentionDays|Specify how long you want to keep your point-in-time backups. Default value is 7 days|
|sqlManagedInstanceAADonlyAuthentication|true, false <br /> Set Azure Active Directory only Authentication|
|sqlmiVulnerabilityAssessmentRecurringScans|true, false <br /> Enable or disable Azure Security Center (ASC) SQL Vulnerability Assessment Scans|
|sqlmiVulnerabilityAssessmentRecurringScansEmailSubAdmins|true, false <br /> Email reports to admins|
|sqlmiVulnerabilityAssessmentRecurringScansEmails|Array of email addresses to receive ASC reports|
|clientIPcidr|Client IP address (CIDR format) to allow access to storage account vulnerability reports <br /> (example: 13.168.10.0/24)|
|sqlMIDatabaseNames|Array of database names|
<br />

> ## Important
>
> Deployment of first SQL MI in the subnet might take up to six hours, while subsequent deployments take up to 1.5 hours. This is because a virtual cluster that hosts the instances needs time to deploy or resize the virtual cluster. For more details visit [Overview of Azure SQL Managed Instance management operations](https://docs.microsoft.com/azure/azure-sql/managed-instance/management-operations-overview)  
> Each virtual cluster is associated with a subnet and deployed together with first instance creation. In the same way, a virtual cluster is [automatically removed together with last instance deletion](https://docs.microsoft.com/azure/azure-sql/managed-instance/virtual-cluster-delete) leaving the subnet empty and ready for removal.  
> The SQL MI Admin Password is automatically generated and not saved anywhere. You'll need to manually update it in order to log into SQL MI with the admin account.

## Known Issues

- Azure AD Authentication Integration
  - This deployment supports setting Azure AD Authentication and Azure AD Authentication Only, if the person running this deployment is assigned the Global Admin or Privileged Role Administrator role.
  - For all other roles, a Global Admin or Privileged Role Administrator can create an Azure AD group and assign the Directory Readers permission to the group. Read [Directory Readers role in Azure Active Directory for Azure SQL](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-directory-readers-role) for more information.
  - An alternate solution is for a Global Admin or Privileged Role Administrator run this script to grant your SQL Managed Instance Azure AD read permission:

```powershell
# Gives Azure Active Directory read permission to a Service Principal (System Managed Identity) representing the SQL Managed Instance.
# Can be executed only by a "Global Administrator" or "Privileged Role Administrator" type of user.

Connect-AzureAD

$managedInstanceName = "MyManagedInstance"
# Get Azure AD role "Directory Users" and create if it doesn't exist
$roleName = "Directory Readers"
$role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq $roleName}
if ($role -eq $null) {
    # Instantiate an instance of the role template
    $roleTemplate = Get-AzureADDirectoryRoleTemplate | Where-Object {$_.displayName -eq $roleName}
    Enable-AzureADDirectoryRole -RoleTemplateId $roleTemplate.ObjectId
    $role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq $roleName}
}

# Get service principal for your SQL Managed Instance
$roleMember = Get-AzureADServicePrincipal -SearchString $managedInstanceName
$roleMember.Count
if ($roleMember -eq $null) {
    Write-Output "Error: No Service Principals with name '$    ($managedInstanceName)', make sure that managedInstanceName parameter was     entered correctly."
    exit
}
if (-not ($roleMember.Count -eq 1)) {
    Write-Output "Error: More than one service principal with name pattern '$    ($managedInstanceName)'"
    Write-Output "Dumping selected service principals...."
    $roleMember
    exit
}

# Check if service principal is already member of readers role
$allDirReaders = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
$selDirReader = $allDirReaders | where{$_.ObjectId -match     $roleMember.ObjectId}

if ($selDirReader -eq $null) {
    # Add principal to readers role
    Write-Output "Adding service principal '$($managedInstanceName)' to     'Directory Readers' role'..."
    Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId     $roleMember.ObjectId
    Write-Output "'$($managedInstanceName)' service principal added to     'Directory Readers' role'..."

    #Write-Output "Dumping service principal '$($managedInstanceName)':"
    #$allDirReaders = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
    #$allDirReaders | where{$_.ObjectId -match $roleMember.ObjectId}
}
else {
    Write-Output "Service principal '$($managedInstanceName)' is already     member of 'Directory Readers' role'."
}
```
