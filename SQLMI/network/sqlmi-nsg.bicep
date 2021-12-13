param location string
param sqlmiNSGid string
param tags object
param nsgName string

resource sqlmiNSG  'Microsoft.Network/networkSecurityGroups@2020-07-01' = if (empty(sqlmiNSGid)){
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

output nsgID string = sqlmiNSG.id
