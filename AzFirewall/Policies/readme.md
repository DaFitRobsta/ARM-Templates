# Deploy Azure Firewall Policies via Bicep/JSON

## Introduction

When deploying a new Azure Firewall a new Firewall Policy is created by default and requires rules.  This deployment will allow you to kick start your base rules. It also allows for modifications and/or additions based on Bicep modules.

## What's Policies are Included?

There is a Core Infrastructure Rules Collection Group that contains rule collections for Active Directory, Core IT rules, and Core IT Application rules:
* CoreInfrastructureRulesCollectionGroup
*        ActiveDirectoryRules
*        coreSystemsRules
*        coreSystemsApplicationRules
* AssetRulesCollectionGroup
*        ServiceNowDiscoveryRules

## Where to begin

1) Install the Bicep client, unless deployment is executing from Azure Cloud Shell

2) Update the main.parameters.json file parameters

3) Edit the deployBicep.ps1 and verify main.bicep and main.parameters.json are referenced to the correct path

4) Run deployBicep.ps1 from client PowerShell console or Azure Cloud Shell

Learn more about [Azure Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/bicep-overview)