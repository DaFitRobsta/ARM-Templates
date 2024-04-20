@description('Name of the Policy this rule collection belongs')
param fwPolicyName string = 'BaseFWPolicy'

@description('Priority of the Asset Rule Collection Group')
param assetDiscoveryRCGPriority int = 200

@description('For the Snow Discovery Rules, set the destination addresses in comma seperated quoted IP addresses')
param snowRulesDestinationAddresses array = []

@description('For the Snow Discovery Rules, set the destination IP Groups resource Id in comma seperated quoted IDs')
param snowRulesDestinationIPGroups array = []

@description('For the Snow Discovery Rules, set the source addresses in comma seperated quoted IP addresses')
param snowRulesSourceAddresses array = []

@description('For the Snow Discovery Rules, set the source IP Groups resource Id in comma seperated quoted IDs')
param snowRulesSourceIPGroups array = []

var snowDiscoveryRulesPriority = assetDiscoveryRCGPriority

resource snowDiscoveryRuleCollectionGroups 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  name: '${fwPolicyName}/AssetDiscoveryRCG'
  properties: {
    priority: assetDiscoveryRCGPriority
    ruleCollections: [
      {
        name: 'ServiceNowDiscoveryRules'
        priority: snowDiscoveryRulesPriority
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'RemotePowerShell'
            ipProtocols: [
              'TCP'
            ]
            destinationAddresses: snowRulesDestinationAddresses
            destinationIpGroups: snowRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '5985-5986'
            ]
            sourceAddresses: snowRulesSourceAddresses
            sourceIpGroups: snowRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'SSH'
            ipProtocols: [
              'TCP'
            ]
            destinationAddresses: snowRulesDestinationAddresses
            destinationIpGroups: snowRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '22'
            ]
            sourceAddresses: snowRulesSourceAddresses
            sourceIpGroups: snowRulesSourceIPGroups
          }
        ]
      }
    ]
  }  
}
