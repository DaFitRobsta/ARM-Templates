@description('Name of the Firewall Policy')
param policyName string = 'CoreFWPolicy'
param location string = resourceGroup().location

@allowed([
  'Alert'
  'Deny'
  'Off'
])
@description('The operation mode for Threat Intelligence. - Alert, Deny, Off')
param threatIntelMode string = 'Deny'

@description('List of IP addresses for the ThreatIntel Whitelist. - comma seperated quoted IP addresses')
param threatIntelWhiteListIpAddresses array = []

@description('List of FQDNs for the ThreatIntel Whitelist. - comma seperated quoted FQDNs')
param threatIntelWhiteListFQDNs array = []

@description('List of Custom DNS Servers - comma seperated quoted IP addresses')
param dnsServersIPAddresses array = []

@description('Enable DNS Proxy on Firewalls attached to the Firewall Policy.')
param dnsEnableProxy bool = false

@allowed([
  'Standard'
  'Premium'
])
@description('Tier of Firewall Policy. - Standard or Premium')
param firewallPolicySku string = 'Standard'

@description('Private IP ranges (SNAT) that will not be SNAT\'d by the Az Firewall')
param fwPolicyPrivateIPAddresses array = [
  '10.0.0.0/8'
  '172.16.0.0/12'
  '192.168.0.0/16'
  '100.64.0.0/10'
]

resource baseFwPolicy 'Microsoft.Network/firewallPolicies@2020-11-01' = {
  name: policyName
  location: location
  tags: {}
  properties: {
    threatIntelMode: threatIntelMode
    threatIntelWhitelist: {
      ipAddresses: threatIntelWhiteListIpAddresses
      fqdns: threatIntelWhiteListFQDNs
    }
    dnsSettings: {
      servers: dnsServersIPAddresses
      enableProxy: dnsEnableProxy
    }
    sku: {
      tier: firewallPolicySku
    }
    snat: {
      privateRanges: fwPolicyPrivateIPAddresses
    }
  }
}

// ADDS Rule Collection Source/Destination IP Addresses or IP Groups
@description('List of Destination AD DS Server IP Addresses or range - comma seperated quoted IP addresses')
param adRulesDestinationAddresses array = []

@description('List of Destination AD DS Server IP Group(s) - comma seperated quoted IP Groups ID(s)')
param adRulesDestinationIPGroups array = []

@description('List of Source AD DS Server IP Addresses or range - comma seperated quoted IP addresses')
param adRulesSourceAddresses array = []

@description('List of Source AD DS Server IP Group(s) - comma seperated quoted IP Groups ID(s)')
param adRulesSourceIPGroups array = []

// Core Systems Rule Collection Source/Destination IP Addresses or IP Groups
@description('For the Core Systems Rules, set the destination addresses in comma seperated quoted IP addresses')
param coreSysRulesDestinationAddresses array = []

@description('For the Core Systems Rules, set the destination IP Groups resource Id in comma seperated quoted IDs')
param coreSysRulesDestinationIPGroups array = []

@description('For the Core Systems Rules, set the source addresses in comma seperated quoted IP addresses')
param coreSysRulesSourceAddresses array = []

@description('For the Core Systems Rules, set the source IP Groups resource Id in comma seperated quoted IDs')
param coreSysRulesSourceIPGroups array = []

@description('Priority of the Core Infrastructrue Rule Collection Group')
param coreRuleCollectionGroupPriority int = 100

module coreInfrastructureRCG 'RuleGroups/coreInfraRCG.bicep' = {
  name: 'coreInfrastructureRCG'
  params:{
    fwPolicyName: baseFwPolicy.name
    adRulesDestinationAddresses: empty(adRulesDestinationAddresses) ? [] : adRulesDestinationAddresses
    adRulesDestinationIPGroups: empty(adRulesDestinationIPGroups) ? [] : adRulesDestinationIPGroups
    adRulesSourceAddresses: empty(adRulesSourceAddresses) ? [] : adRulesSourceAddresses
    adRulesSourceIPGroups: empty(adRulesSourceIPGroups) ? [] : adRulesSourceIPGroups
    coreSysRulesDestinationAddresses: empty(coreSysRulesDestinationAddresses) ? [] : coreSysRulesDestinationAddresses
    coreSysRulesDestinationIPGroups: empty(coreSysRulesDestinationIPGroups) ? [] : coreSysRulesDestinationIPGroups
    coreSysRulesSourceAddresses: empty(coreSysRulesSourceAddresses) ? [] : coreSysRulesSourceAddresses
    coreSysRulesSourceIPGroups: empty(coreSysRulesSourceIPGroups) ? [] : coreSysRulesSourceIPGroups
    coreRuleCollectionGroupPriority: coreRuleCollectionGroupPriority
  }
}

output afwPolicyId string = baseFwPolicy.id
