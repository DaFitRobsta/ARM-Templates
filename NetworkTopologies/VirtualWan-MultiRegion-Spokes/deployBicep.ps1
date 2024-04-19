<#
.SYNOPSIS
Deploys Azure Bicep template to Azure Resource Manager

.DESCRIPTION
Determines whether a user is logged into Azure, if not, user is prompted to log in. 
User is allowed to select which Azure subscription and Resource Group for deployment of Azure Bicep template

.PARAMETER AzureEnvironment
The default value is AzureCloud and the user can override with AzureUSGovernment, AzureGermanCloud, AzureChinaCloud.

.PARAMETER TemplateParameterFile
Override the default main.parameters.json with your own parameters file.

.PARAMETER TenantId
Azure AD Tenant Id of the subscription if it's not associated with your home tenant.

.NOTES
LEGAL DISCLAIMER:
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree:
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys' fees, that arise or result from the use or distribution of the Sample Code.
This posting is provided "AS IS" with no warranties, and confers no rights.
#>
[CmdletBinding()]
param (
    [Parameter( HelpMessage="Enter the Azure Cloud to connect to. Default is AzureCloud.")]
    [ValidateSet("AzureCloud", "AzureUSGovernment", "AzureGermanCloud", "AzureChinaCloud")]
    [string]
    $AzureEnvironment='AzureCloud',
    [Parameter( HelpMessage="Enter the parameters file name or path. For example '.\main.parameters.json'")]
    [string]
    $TemplateParameterFile='.\main.parameters.json',
    [Parameter( HelpMessage="Enter the Azure AD Tenant Id if the subscription is not associated with your home tenant.")]
    [string]
    $TenantId=""
)

# Determine if already connected to Azure
try {
  if($TenantId.length -gt 0){
    $connected = Get-AzSubscription -TenantId $TenantId
  }
  else {
    $connected = Get-AzSubscription
  }
}
catch {
  Write-Host "Not connected to Azure and you will prompt you to connect to Azure" -ForegroundColor Green
  if($TenantId.length -gt 0){
    $result = Connect-AzAccount -Environment $AzureEnvironment -TenantId $TenantId
  }
  else {
    $result = Connect-AzAccount -Environment $AzureEnvironment
  }
}

$TenantId = (Get-AzContext).Tenant.Id
Write-Host ""
Write-Host "List of available subscriptions:" -ForegroundColor Green
(Get-AzSubscription -TenantId $TenantId).name
Write-Host ""
$subscriptionName = Read-Host -Prompt "Enter Subscription Name"
$result = Select-AzSubscription -SubscriptionName $subscriptionName -TenantId $TenantId
Write-Host ""
# Write-Host "List of available Resource Groups:" -ForegroundColor Green
# (Get-AzResourceGroup).ResourceGroupName
# Write-Host ""
# $resourceGroup = Read-Host -Prompt "Enter the Resource Group Name (where ARM template will be deployed into)"
$bicepFile = '.\main.bicep'
$mainParametersFiles = $TemplateParameterFile

# Parameters necessary for deployment
$inputObject = @{
  DeploymentName        = 'deployVirtualWAN-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westus3'
  TemplateFile          = $bicepFile
  TemplateParameterFile = $mainParametersFiles
}
New-AzDeployment @inputObject