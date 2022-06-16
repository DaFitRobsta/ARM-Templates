@description('VNet configuration object with properites')
param vnetObj object = {}

module getAzFirewallPrivateIP 'azcidrhost-function.bicep' = [for subnet in vnetObj.subnets: if (subnet.name == 'AzureFirewallSubnet'){
  name: 'getAzFirewallPrivateIP-${subnet.name}'
  scope: resourceGroup(vnetObj.resourceGroupName)
  params: {
    location: vnetObj.resourceGroupLocation
    addressPrefix: subnet.addressPrefix
  }
}]

output azFirewallPrivateIP string = getAzFirewallPrivateIP[0].outputs.FirstUsableIP
