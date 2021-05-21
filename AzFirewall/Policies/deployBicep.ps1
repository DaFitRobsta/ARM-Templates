$subscriptionName = Read-Host -Prompt "Enter Subscription Name"
Select-AzSubscription -SubscriptionName $subscriptionName
$bicepFile = '.\main.bicep'
$mainParametersFiles = '.\main.parameters.json'
New-AzResourceGroupDeployment `
  -Name coreFWPolicy `
  -ResourceGroupName demo `
  -TemplateFile $bicepFile `
  -TemplateParameterFile $mainParametersFiles