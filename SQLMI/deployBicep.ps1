# Determine if already connected to Azure
try {
  $connected = Get-AzSubscription
}
catch {
  Write-Host "Not connected to Azure and you will prompt you to connect to Azure" -ForegroundColor Green
  $result = Connect-AzAccount
}
Write-Host ""
Write-Host "List of available subscriptions:" -ForegroundColor Green
(Get-AzSubscription).name
Write-Host ""
$subscriptionName = Read-Host -Prompt "Enter Subscription Name"
$result = Select-AzSubscription -SubscriptionName $subscriptionName
Write-Host ""
Write-Host "List of available Resource Groups:" -ForegroundColor Green
(Get-AzResourceGroup).ResourceGroupName
Write-Host ""
$resourceGroup = Read-Host -Prompt "Enter the Resource Group Name (where ARM template will be deployed into)"
$bicepFile = '.\main.bicep'
$mainParametersFiles = '.\main.parameters.json'
New-AzResourceGroupDeployment `
  -Name deploySQLMI `
  -ResourceGroupName $resourceGroup `
  -TemplateFile $bicepFile `
  -TemplateParameterFile $mainParametersFiles