# Azure Key Vault

This module deploys a key vault.

## Description

{{ Add detailed description for the module. }}

## Parameters

| Name                                    | Type           | Required | Description                                                                                                                                                                                                                                                                   |
| :-------------------------------------- | :------------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                          | `string`       | Yes      | Used to name all resources                                                                                                                                                                                                                                                    |
| `location`                              | `string`       | No       | Resource Location.                                                                                                                                                                                                                                                            |
| `enableDeleteLock`                      | `bool`         | No       | Enable lock to prevent accidental deletion                                                                                                                                                                                                                                    |
| `tags`                                  | `object`       | No       | Tags.                                                                                                                                                                                                                                                                         |
| `sku`                                   | `string`       | No       | Key Vault SKU.                                                                                                                                                                                                                                                                |
| `accessPolicies`                        | `array`        | No       | Specify Access Policies to Enable (Optional).                                                                                                                                                                                                                                 |
| `softDeleteRetentionInDays`             | `int`          | No       | Key Vault Retention Days.                                                                                                                                                                                                                                                     |
| `secretsObject`                         | `secureObject` | No       | Specifies all secrets {"secretName":"","secretValue":""} wrapped in a secure object.                                                                                                                                                                                          |
| `roleAssignments`                       | `array`        | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep |
| `diagnosticWorkspaceId`                 | `string`       | No       | Optional. Resource ID of the diagnostic log analytics workspace.                                                                                                                                                                                                              |
| `diagnosticStorageAccountId`            | `string`       | No       | Optional. Resource ID of the diagnostic storage account.                                                                                                                                                                                                                      |
| `diagnosticEventHubAuthorizationRuleId` | `string`       | No       | Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.                                                                                                                    |
| `diagnosticEventHubName`                | `string`       | No       | Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.                                                                                                                      |
| `diagnosticLogsRetentionInDays`         | `int`          | No       | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.                                                                                                                                                                |
| `logsToEnable`                          | `array`        | No       | Optional. The name of logs that will be streamed.                                                                                                                                                                                                                             |
| `metricsToEnable`                       | `array`        | No       | Optional. The name of metrics that will be streamed.                                                                                                                                                                                                                          |
| `privateLinkSettings`                   | `object`       | No       | Settings Required to Enable Private Link                                                                                                                                                                                                                                      |

## Outputs

| Name | Type   | Description                           |
| :--- | :----: | :------------------------------------ |
| name | string | The name of the azure keyvault.       |
| id   | string | The resourceId of the azure keyvault. |

## Examples

### Example 1

```bicep
module kv 'br:osdubicep.azurecr.io/bicep/modules/public/keyvault:1.0.2' = {
  name: 'azure_keyvault'
  params: {
    resourceName: 'acr${unique(resourceGroup().name)}'
    location: 'southcentralus'
    secretsObject: { secrets: []}
  }
}
```

### Example 2

```bicep
module kv 'br:osdubicep.azurecr.io/bicep/modules/public/keyvault:1.0.2' = {
  name: 'azure_keyvault'
  params: {
    resourceName: 'acr${unique(resourceGroup().name)}'
    location: 'southcentralus'
    
    // Add secrets
    secretsObject: {
      secrets: [
        {
          secretName: 'Hello'
          secretValue: 'World'
        }
      ]
    }

    // Hook up Access Policy
    accessPolicies: [
      {
        principalId: '222222-2222-2222-2222-2222222222'
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          keys: [
            'create'
            'get'
            'list'
            'unwrapKey'
            'wrapKey'
            'get'
          ]
        }
      }
    ]

    // Hook up Diagnostics
    diagnosticWorkspaceId: '/subscriptions/222222-2222-2222-2222-2222222222/resourceGroups/osdu-resource-group/providers/Microsoft.OperationalInsights/workspaces/osdu-logs'

    // Hook up Private Link
    privateLinkSettings:{
      vnetId: '/subscriptions/222222-2222-2222-2222-2222222222/resourceGroups/osdu-resource-group/providers/Microsoft.Network/virtualNetworks/osdu-vnet'
      subnetId: '/subscriptions/222222-2222-2222-2222-2222222222/resourceGroups/osdu-resource-group/providers/Microsoft.Network/virtualNetworks/osdu-vnet/subnets/default'
    }
  }
}
```