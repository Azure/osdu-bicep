# Azure Container Registry Module

This module deploys an Azure Container registry.

## Description

This module deploys either a simple Container Registry or one with diagnostics enabled, and Private IP Link capability.

## Parameters

| Name                                    | Type     | Required | Description                                                                                                                                                                                                                                                                   |
| :-------------------------------------- | :------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                          | `string` | Yes      | Used to name all resources                                                                                                                                                                                                                                                    |
| `location`                              | `string` | No       | Registry Location.                                                                                                                                                                                                                                                            |
| `enableDeleteLock`                      | `bool`   | No       | Enable lock to prevent accidental deletion                                                                                                                                                                                                                                    |
| `tags`                                  | `object` | No       | Tags.                                                                                                                                                                                                                                                                         |
| `acrAdminUserEnabled`                   | `bool`   | No       | Enable an admin user that has push/pull permission to the registry.                                                                                                                                                                                                           |
| `sku`                                   | `string` | No       | Tier of your Azure Container Registry.                                                                                                                                                                                                                                        |
| `roleAssignments`                       | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep |
| `diagnosticWorkspaceId`                 | `string` | No       | Optional. Resource ID of the diagnostic log analytics workspace.                                                                                                                                                                                                              |
| `diagnosticStorageAccountId`            | `string` | No       | Optional. Resource ID of the diagnostic storage account.                                                                                                                                                                                                                      |
| `diagnosticEventHubAuthorizationRuleId` | `string` | No       | Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.                                                                                                                    |
| `diagnosticEventHubName`                | `string` | No       | Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.                                                                                                                      |
| `diagnosticLogsRetentionInDays`         | `int`    | No       | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.                                                                                                                                                                |
| `logsToEnable`                          | `array`  | No       | Optional. The name of logs that will be streamed.                                                                                                                                                                                                                             |
| `metricsToEnable`                       | `array`  | No       | Optional. The name of metrics that will be streamed.                                                                                                                                                                                                                          |
| `privateLinkSettings`                   | `object` | No       | Settings Required to Enable Private Link                                                                                                                                                                                                                                      |
| `privateEndpointName`                   | `string` | No       | Specifies the name of the private link to the Azure Container Registry.                                                                                                                                                                                                       |

## Outputs

| Name        | Type   | Description                                                         |
| :---------- | :----: | :------------------------------------------------------------------ |
| name        | string | The name of the container registry.                                 |
| loginServer | string | Specifies the name of the fully qualified name of the login server. |

## Examples

### Example 1

```bicep
module acr 'br:osdubicep.azurecr.io/bicep/modules/public/container-registry:1.0.1' = {
  name: 'container_registry'
  params: {
    resourceName: `acr${unique(resourceGroup().name)}'
    location: 'southcentralus'
    sku: 'Standard'
  }
}
```

### Example 2

```bicep
module acr 'br:osdubicep.azurecr.io/bicep/modules/public/container-registry:1.0.1' = {
  name: 'container_registry'
  params: {
    resourceName: `acr${unique(resourceGroup().name)}'
    location: 'southcentralus'
    sku: 'Premium'

    roleAssignments: [
      {
        roleDefinitionIdOrName: 'ACR Pull'
        principalIds: [
          identity.outputs.principalId
        ]
        principalType: '222222-2222-2222-2222-2222222222'
      }
    ]

    privateLinkSettings:{
      vnetId: '/subscriptions/222222-2222-2222-2222-2222222222/resourceGroups/osdu-resource-group/providers/Microsoft.Network/virtualNetworks/osdu-vnet'
      subnetId: '/subscriptions/222222-2222-2222-2222-2222222222/resourceGroups/osdu-resource-group/providers/Microsoft.Network/virtualNetworks/osdu-vnet/subnets/default'
    }

    diagnosticWorkspaceId: '/subscriptions/222222-2222-2222-2222-2222222222/resourceGroups/osdu-resource-group/providers/Microsoft.OperationalInsights/workspaces/osdu-logs'
  }
}
```