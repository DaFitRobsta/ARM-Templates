Get-AzSubscription | select name
$subscriptionName = Read-Host -Prompt "Enter Subscription Name"
Select-AzSubscription -SubscriptionName $subscriptionName
Get-AzResourceGroup | select ResourceGroupName
$resourceGroup = Read-Host -Prompt "Enter the Resource Group Name (where ARM template will be deployed into)"
$bicepFile = '.\main.bicep'
$mainParametersFiles = '.\main.parameters.json'
New-AzResourceGroupDeployment `
  -Name coreFWPolicy `
  -ResourceGroupName $resourceGroup `
  -TemplateFile $bicepFile `
  -TemplateParameterFile $mainParametersFiles