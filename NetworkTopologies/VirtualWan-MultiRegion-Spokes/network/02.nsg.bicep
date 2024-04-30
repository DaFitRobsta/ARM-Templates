param location string
param tags object
//param vnetName string
param vnetObject object = {}

/* var bastionSecurityRules = [
  {
    name: 'AllowHttpsInBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'Internet'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowGatewayManagerInBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'GatewayManager'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowLoadBalancerInBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'AzureLoadBalancer'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 120
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowBastionHostCommunicationInBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
          '8080'
          '5701'
      ]
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 130
      direction: 'Inbound'
    }
  }
  {
    name: 'DenyAllInBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRange: '*'
      destinationAddressPrefix: '*'
      access: 'Deny'
      priority: 1000
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowSshRdpOutBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRanges: [
          '22'
          '3389'
      ]
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 100
      direction: 'Outbound'
    }
  }
  {
    name: 'AllowAzureCloudCommunicationOutBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRange: '443'
      destinationAddressPrefix: 'AzureCloud'
      access: 'Allow'
      priority: 110
      direction: 'Outbound'
    }
  }
  {
    name: 'AllowBastionHostCommunicationOutBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
          '8080'
          '5701'
      ]
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 120
      direction: 'Outbound'
    }
  }
  {
    name: 'AllowGetSessionInformationOutBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRanges: [
          '80'
          '443'
      ]
      access: 'Allow'
      priority: 130
      direction: 'Outbound'
    }
  }
  {
    name: 'DenyAllOutBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Deny'
      priority: 1000
      direction: 'Outbound'
    }
  }  
] */

var securityRules = contains(vnetObject, 'nsgSecurityRules') ? vnetObject.nsgSecurityRules : []

resource subnetNSG 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-${vnetObject.vnetName}'
  location: location
  tags: tags
  properties: {
    securityRules: securityRules
  }
}

 output nsgID string =  ((!empty(subnetNSG.id)) ? subnetNSG.id : '')
