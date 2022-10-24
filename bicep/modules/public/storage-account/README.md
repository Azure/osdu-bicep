# Azure Storage Module

This module deploys an Azure Storage Account.

## Description

{{ Add detailed description for the module. }}

## Parameters

| Name                                    | Type     | Required | Description                                                                                                                                                                                                                                                                   |
| :-------------------------------------- | :------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                          | `string` | Yes      | Used to name all resources                                                                                                                                                                                                                                                    |
| `location`                              | `string` | No       | Resource Location.                                                                                                                                                                                                                                                            |
| `lock`                                  | `string` | No       | Optional. Specify the type of lock.                                                                                                                                                                                                                                           |
| `tags`                                  | `object` | No       | Tags.                                                                                                                                                                                                                                                                         |
| `sku`                                   | `string` | No       | Specifies the storage account sku type.                                                                                                                                                                                                                                       |
| `accessTier`                            | `string` | No       | Specifies the storage account access tier.                                                                                                                                                                                                                                    |
| `roleAssignments`                       | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep |
| `diagnosticWorkspaceId`                 | `string` | No       | Optional. Resource ID of the diagnostic log analytics workspace.                                                                                                                                                                                                              |
| `diagnosticStorageAccountId`            | `string` | No       | Optional. Resource ID of the diagnostic storage account.                                                                                                                                                                                                                      |
| `diagnosticEventHubAuthorizationRuleId` | `string` | No       | Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.                                                                                                                    |
| `diagnosticEventHubName`                | `string` | No       | Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.                                                                                                                      |
| `diagnosticLogsRetentionInDays`         | `int`    | No       | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.                                                                                                                                                                |
| `logsToEnable`                          | `array`  | No       | Optional. The name of logs that will be streamed.                                                                                                                                                                                                                             |
| `metricsToEnable`                       | `array`  | No       | Optional. The name of metrics that will be streamed.                                                                                                                                                                                                                          |
| `privateLinkSettings`                   | `object` | No       | Settings Required to Enable Private Link                                                                                                                                                                                                                                      |
| `privateEndpointName`                   | `string` | No       | Specifies the name of the private link to the Resource.                                                                                                                                                                                                                       |

## Outputs

| Name | Type   | Description               |
| :--- | :----: | :------------------------ |
| id   | string | The resource ID.          |
| name | string | The name of the resource. |

## Examples

### Example 1

A simple standard storage account.

```bicep
module storage '../main.bicep' = {
  name: 'storage_account'
  params: {
    resourceName: 'osdu'
    location: 'southcentralus'
    sku: 'Standard_LRS'
  }
}
```

### Example 2

A storage account with Private IP Links enabled, diagnostics enabled with a role assignment.

```bicep
module storage '../main.bicep' = {
  name: 'storage_account'
  params: {
    resourceName: 'osdu'
    location: 'southcentralus'
    sku: 'Standard_LRS'
    privateLinkSettings:{
      vnetId: '/subscriptions/222222-2222-2222-2222-2222222222/resourceGroups/osdu-resource-group/providers/Microsoft.Network/virtualNetworks/osdu-vnet'
      subnetId: '/subscriptions/222222-2222-2222-2222-2222222222/resourceGroups/osdu-resource-group/providers/Microsoft.Network/virtualNetworks/osdu-vnet/subnets/default'
    }
    diagnosticWorkspaceId: '/subscriptions/222222-2222-2222-2222-2222222222/resourceGroups/osdu-resource-group/providers/Microsoft.OperationalInsights/workspaces/osdu-logs'
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
        principalIds: [
          '222222-2222-2222-2222-2222222222'
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}
```