# Creating/Updating Custom Roles with Bicep and Parameters File

## Background

There are many well documented methods ([Azure custom roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/custom-roles)) to create Azure custom roles. This method uses Bicep with a parameters file. The parameter file(s) can be your source of truth, meaning one can have a parameter file per custom role.

## Assumptions

When creating Azure custom roles, I highly recommend creating them at a Management Group vs. the subscription level/scope. The [below](#powershell) PowerShell example demonstrates deployment at a management group scope.

## Updating an existing Custom Role

If you used this method to initially deploy the Custom Role, the Id of the role is generated using the guid() based on name and assignable scopes. If you run into an issue with updating your custom role through this method, it might be related to changing the assignable scopes since it was used in generating the Custom Role Id.

## Prerequisites

[Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/bicep-tutorial-create-first-bicep?tabs=azure-powershell) - Read through the Bicep tutorial to setup your environment.

<a name="powershell"></a>

## PowerShell Deployment

```powershell
   New-AzManagementGroupDeployment -Location westus -TemplateFile .\customRole.bicep -TemplateParameterFile .\subscriptionOwner-corp.parameters.json -ManagementGroupId {groupId1}
```
