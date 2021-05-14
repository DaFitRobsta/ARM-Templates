
@description('Name of the Policy this rule collection belongs')
param fwPolicyName string = 'BaseFWPolicy'

@description('For the AD Rules, set the destination addresses in comma seperated quoted IP addresses')
param adRulesDestinationAddresses array = []

@description('For the AD Rules, set the destination IP Groups resource Id in comma seperated quoted IDs')
param adRulesDestinationIPGroups array = []

@description('For the AD Rules, set the source addresses in comma seperated quoted IP addresses')
param adRulesSourceAddresses array = []

@description('For the AD Rules, set the source IP Groups resource Id in comma seperated quoted IDs')
param adRulesSourceIPGroups array = []

resource adRulesGroupCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  name: '${fwPolicyName}/ActiveDirectoryRulesCollectionGroup'
  properties:{
    priority: 110
    ruleCollections:[
      {
        name: 'ActiveDirectoryRules'
        priority: 100
        ruleCollectionType:'FirewallPolicyFilterRuleCollection'
        action:{
          type: 'Allow'
        }
        rules:[
          {
            ruleType: 'NetworkRule'
            name: 'NTP'
            ipProtocols:[
              'UDP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '123'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'RPC'
            ipProtocols:[
              'TCP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '135'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'Kerberos password change'
            ipProtocols:[
              'TCP'
              'UDP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '464'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'RPC for LSA, SAM, NetLogon'
            ipProtocols:[
              'TCP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '49152-65535'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'LDAP'
            ipProtocols:[
              'TCP'
              'UDP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '389'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'LDAP SSL'
            ipProtocols:[
              'TCP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '636'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'LDAP GC'
            ipProtocols:[
              'TCP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '3268'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'LDAP GC SSL'
            ipProtocols:[
              'TCP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '3269'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'DNS'
            ipProtocols:[
              'TCP'
              'UDP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '53'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'FRS RPC'
            ipProtocols:[
              'TCP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '49252 - 65535'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'Kerberos'
            ipProtocols:[
              'TCP'
              'UDP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '88'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'SMB'
            ipProtocols:[
              'TCP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '445'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'DFSR RPC'
            ipProtocols:[
              'TCP'
            ]
            destinationAddresses: adRulesDestinationAddresses
            destinationIpGroups: adRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '49152 - 65535'
            ]
            sourceAddresses: adRulesSourceAddresses
            sourceIpGroups: adRulesSourceIPGroups
          }                                                                  
        ]
      }
    ]
  }
}
