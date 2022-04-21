param location string = resourceGroup().location

param workbookId string = guid(subscription().subscriptionId, resourceGroup().id)
param workbookName string = 'Azure Firewall Workbook'
param afwWorkbookSerializedData string

param tags object

var lawName = 'law-network-pd-${location}-001'

resource createLogAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: lawName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource createAfwWorkbook 'Microsoft.Insights/workbooks@2021-08-01' = {
  name: workbookId
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    serializedData: afwWorkbookSerializedData
    category: 'workbook'
    displayName: workbookName
    version: '1.0'
    sourceId: createLogAnalytics.id
  }
}

output workspaceId string = createLogAnalytics.id
