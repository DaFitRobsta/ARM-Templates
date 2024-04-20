
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

@description('For the Core Systems Rules, set the destination addresses in comma seperated quoted IP addresses')
param coreSysRulesDestinationAddresses array = []

@description('For the Core Systems Rules, set the destination IP Groups resource Id in comma seperated quoted IDs')
param coreSysRulesDestinationIPGroups array = []

@description('For the Core Systems Rules, set the source addresses in comma seperated quoted IP addresses')
param coreSysRulesSourceAddresses array = []

@description('For the Core Systems Rules, set the source IP Groups resource Id in comma seperated quoted IDs')
param coreSysRulesSourceIPGroups array = []

@description('Priority of the AD Rule Collection Group')
param coreRuleCollectionGroupPriority int = 100

// Set the Rules Collection Priority
var adRulesPriority = coreRuleCollectionGroupPriority
var coreSystemsRulesPriority = adRulesPriority + 5
var coreSystemsApplicationRulesPriority = coreSystemsRulesPriority + 5

// Get the environment storage blob URI
var blobStorage = '*.blob.${environment().suffixes.storage}'

resource coreInfraRuleCollectionGroups 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  name: '${fwPolicyName}/CoreInfrastructureRCG'
  properties:{
    priority: coreRuleCollectionGroupPriority
    ruleCollections:[
      {
        name: 'ActiveDirectoryRules'
        priority: adRulesPriority
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
      {
        name: 'coreSystemsRules'
        priority: coreSystemsRulesPriority
        ruleCollectionType:'FirewallPolicyFilterRuleCollection'
        action:{
          type: 'Allow'
        }
        rules:[
          {
            ruleType: 'NetworkRule'
            name: 'RemoteDesktop'
            ipProtocols:[
              'TCP'
            ]
            destinationAddresses: coreSysRulesDestinationAddresses
            destinationIpGroups: coreSysRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '3389'
            ]
            sourceAddresses: coreSysRulesSourceAddresses
            sourceIpGroups: coreSysRulesSourceIPGroups
          }
          {
            ruleType: 'NetworkRule'
            name: 'ICMP-Pingers'
            ipProtocols:[
              'ICMP'
            ]
            destinationAddresses: coreSysRulesDestinationAddresses
            destinationIpGroups: coreSysRulesDestinationIPGroups
            destinationFqdns:[]
            destinationPorts:[
              '*'
            ]
            sourceAddresses: coreSysRulesSourceAddresses
            sourceIpGroups: coreSysRulesSourceIPGroups
          }
        ]
      }
      {
        name: 'coreSystemsApplicationRules'
        priority: coreSystemsApplicationRulesPriority
        ruleCollectionType:'FirewallPolicyFilterRuleCollection'
        action:{
          type: 'Allow'
        }
        rules:[
          {
            ruleType: 'ApplicationRule'
            name: 'AllowLogAnalytics'
            protocols:[
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            destinationAddresses: []
            fqdnTags:[]
            targetFqdns: [
              '*.ods.opinsights.azure.com'
              '*.oms.opinsights.azure.com'
              blobStorage
              '*.azure-automation.net'
            ] 
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
          }
          {
            ruleType: 'ApplicationRule'
            name: 'AllowAzurePaaSServices'
            protocols:[
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            destinationAddresses: []
            fqdnTags:[
              'WindowsDiagnostics'
              'AzureBackup'
              'MicrosoftActiveProtectionService'
              'WindowsUpdate'
              'WindowsVirtualDesktop'
            ]
            targetFqdns:[]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
          }
          {
            ruleType: 'ApplicationRule'
            name: 'Allow-To-MSFT'
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            targetFqdns: [
              '*.microsoft.com'
            ]
            sourceAddresses: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}
