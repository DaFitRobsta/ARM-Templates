@description('VNet configuration object with properites')
param hubSpokes array = []

@description('Currently setting all resoruces to the same resource TAGS')
param tags object

module vNetResourceGroups 'br/public:avm/res/resources/resource-group:0.2.3' = [for spoke in hubSpokes : {
  name: '${spoke.resourceGroupName}-${uniqueString(spoke.vnetName)}'
  scope: subscription(spoke.subscriptionId)
  params: {
    name: spoke.resourceGroupName
    location: spoke.resourceGroupLocation
    tags: tags
  }
}]
