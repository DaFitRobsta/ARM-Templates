param location string = resourceGroup().location
@description('Network Watcher name')
param networkWatcherName string = 'NetworkWatcher_${location}'
@description('Log Analytics Workspace ID. Used for Diagnostic Settings')
param lawId string
param storageAccountId string
param subnetNsgId string
param subnetName string
param tags object = {}

var flowLogsStorageRetention = 7

// Setup NSG Flow Logs
resource nsgFlowLog 'Microsoft.Network/networkWatchers/flowLogs@2021-05-01' = {
  name: '${networkWatcherName}/${subnetName}'
  location: location
  tags: tags
  properties: {
    enabled: true
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: empty(lawId) ? false : true
        trafficAnalyticsInterval: 60
        workspaceResourceId: empty(lawId) ? null : lawId
      }
    }
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      days: flowLogsStorageRetention
      enabled: true
    }
    storageId: storageAccountId
    targetResourceId: subnetNsgId
  }
}
