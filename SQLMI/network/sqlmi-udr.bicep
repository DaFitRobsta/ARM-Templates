param location string
param sqlmiUDRid string
param tags object
param udrName string

resource sqlmiUDR 'Microsoft.Network/routeTables@2020-11-01' = if (empty(sqlmiUDRid)){
  name: udrName
  location: location
  tags: tags
  properties: {
    routes: []
  }
}

output udrId string = sqlmiUDR.id
