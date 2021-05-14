Select-AzSubscription -SubscriptionName "MSDN Platforms"
$bicepFile = '.\main.bicep'
New-AzResourceGroupDeployment `
  -Name coreFWPolicy `
  -ResourceGroupName demo `
  -TemplateFile $bicepFile `
  -policyName 'CoreFWPolicy-Premium' `
  -adRulesDestinationIPGroups "/subscriptions/7447b514-687a-4370-9c17-5abad6dab9c4/resourceGroups/Demo/providers/Microsoft.Network/ipGroups/ipGroup-wu2-dmo01" `
  -adRulesSourceAddresses "192.168.10.0/24","10.53.0.0/24" `
  -firewallPolicySku 'Premium'
  #-adRulesDestinationAddresses "192.168.10.0/24","10.53.0.0/24" `
  #-adRulesSourceIPGroups "/subscriptions/7447b514-687a-4370-9c17-5abad6dab9c4/resourceGroups/Demo/providers/Microsoft.Network/ipGroups/ipGroup-wu2-dmo01"