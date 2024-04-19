@description('An Virtual Hub object containing configuration properties and virtual network config.')
param vWanHubConfig object

@description('Virtual WAN resource Id that the hub will be associated with')
param vWanId string

param vpnGatewayPublicFqdn00 string 
param vpnGatewayPublicFqdn01 string 
param vpnGatewayBgpIp00 string
param vpnGatewayBgpIp01 string

@description('Currently setting all resoruces to the same resource TAGS')
param tags object

var varLocation = vWanHubConfig.location


resource vpnSite 'Microsoft.Network/vpnSites@2022-07-01' = {
  name: vWanHubConfig.onPremSite.name
  location: varLocation
  tags: tags
  dependsOn: []
  properties: {
    virtualWan: {
      id: vWanId
    }
    deviceProperties: {
      deviceVendor: 'Microsoft'
      linkSpeedInMbps: 1000
    }
    vpnSiteLinks: [
      {
        name: 'link01'
        properties: {
          linkProperties: {
            linkProviderName: 'Microsoft'
            linkSpeedInMbps: 1000
          }
          fqdn: vpnGatewayPublicFqdn00
          bgpProperties: {
            asn: vWanHubConfig.onPremSite.virtualNetworkGatewayASN
            bgpPeeringAddress: vpnGatewayBgpIp00
          }
        }
      }
      {
        name: 'link02'
        properties: {
          linkProperties: {
            linkProviderName: 'Microsoft'
            linkSpeedInMbps: 1000
          }
          fqdn: vpnGatewayPublicFqdn01
          bgpProperties: {
            asn: vWanHubConfig.onPremSite.virtualNetworkGatewayASN
            bgpPeeringAddress: vpnGatewayBgpIp01
          }
        }
      }
    ]
  }
}

output vpnSiteId string = vpnSite.id
output vpnSiteLink01 string = vpnSite.properties.vpnSiteLinks[0].id
output vpnSiteLink02 string = vpnSite.properties.vpnSiteLinks[1].id
output vpnSiteLinkName01 string = vpnSite.properties.vpnSiteLinks[0].name
output vpnSiteLinkName02 string = vpnSite.properties.vpnSiteLinks[1].name
