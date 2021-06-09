# Deploy SQL MI into an existing Azure Virtual Network using Azure Bicep

## Background/Scenario

There are situations where AppDevOps teams will need to deploy resources into an existing network infrastructure. This deployment covers such a situation and assumes the virtual network/subnet already exists. What isn't assumed is an existing NSG or UDR already assigned to the subnet. If either a NSG or UDR are not already assigned, the deployment user will need to have at a minimum, Network Contributor rights. SQL MI requires a NSG, UDR, and Microsoft.SQL/ManagedInstance delegation on the subnet before it can deploy successfully.

This deployment checks for those network requirements before submitting

## Features

- [Customer-Managed Key for Transparent Data Encryption](https://docs.microsoft.com/en-us/azure/azure-sql/database/transparent-data-encryption-byok-overview)
  - Key Vault integration
    - Only SQL MI managed identity has access to Key Vault
    - Only Azure Trusted Services are allowed to connect to Key Vault
- Secure Storage Account
  - Only SQL MI subnet and Azure Trusted Services can connect
- Create many databases by specifying their names as an array parameter in the main.parameters.json file

## Prerequisites

- [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/bicep-tutorial-create-first-bicep?tabs=azure-powershell) - Read through the Bicep tutorial to setup your environment.
- An existing Virtual Network with an empty subnet (/27 or larger)
- RBAC roles needed, any combination of the following:
  - Owner
  - User Access Administrator
    - Granting SQL MI Managed Identity access to the storage account for storing Azure Defender Vulnerability Assessment reports
  - Contributor (Not needed if Owner is already assigned)
    - Deployment of all Azure resources:
      - Network Security Group (NSG)
      - Route Table (UDR)
      - SQL Managed Instance
      - Storage Account
      - Key Vault
  - Network Contributor (Not needed if one the previous two roles are assigned)
    - Updating virtual network/subnet delegation to SQLMI
    - Creating NSG and/or UDR if one doesn't already exists on subnet

<a name="powershell"></a>

## PowerShell Deployment

Run this deployment from the same directory that contains the main.bicep and main.parameters.json files.
```powershell
   deployBicep.ps1
```
