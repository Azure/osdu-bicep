# Azure Storage Module

This module deploys an Azure Storage Account.

## Description

This module supports the following features.

- Containers
- Tables
- Role Assignments
- Diagnostics
- Private Link (Secure network)
- Customer Managed Encryption Keys
- Point in Time Restore

## Parameters

| Name                                    | Type     | Required | Description                                                                                                                                                                                                                                                                   |
| :-------------------------------------- | :------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                          | `string` | Yes      | Used to name all resources                                                                                                                                                                                                                                                    |
| `location`                              | `string` | No       | Resource Location.                                                                                                                                                                                                                                                            |
| `lock`                                  | `string` | No       | Optional. Specify the type of lock.                                                                                                                                                                                                                                           |
| `tags`                                  | `object` | No       | Tags.                                                                                                                                                                                                                                                                         |
| `sku`                                   | `string` | No       | Specifies the storage account sku type.                                                                                                                                                                                                                                       |
| `accessTier`                            | `string` | No       | Specifies the storage account access tier.                                                                                                                                                                                                                                    |
| `containers`                            | `array`  | No       | Optional. Array of Storage Containers to be created.                                                                                                                                                                                                                          |
| `tables`                                | `array`  | No       | Optional. Array of Storage Tables to be created.                                                                                                                                                                                                                              |
| `roleAssignments`                       | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep |
| `diagnosticWorkspaceId`                 | `string` | No       | Optional. Resource ID of the diagnostic log analytics workspace.                                                                                                                                                                                                              |
| `diagnosticStorageAccountId`            | `string` | No       | Optional. Resource ID of the diagnostic storage account.                                                                                                                                                                                                                      |
| `diagnosticEventHubAuthorizationRuleId` | `string` | No       | Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.                                                                                                                    |
| `diagnosticEventHubName`                | `string` | No       | Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.                                                                                                                      |
| `diagnosticLogsRetentionInDays`         | `int`    | No       | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.                                                                                                                                                                |
| `logsToEnable`                          | `array`  | No       | Optional. The name of logs that will be streamed.                                                                                                                                                                                                                             |
| `metricsToEnable`                       | `array`  | No       | Optional. The name of metrics that will be streamed.                                                                                                                                                                                                                          |
| `cmekConfiguration`                     | `object` | No       | Optional. Customer Managed Encryption Key.                                                                                                                                                                                                                                    |
| `deleteRetention`                       | `int`    | No       | Amount of days the soft deleted data is stored and available for recovery. 0 is off.                                                                                                                                                                                          |
| `privateLinkSettings`                   | `object` | No       | Settings Required to Enable Private Link                                                                                                                                                                                                                                      |

## Outputs

| Name | Type   | Description               |
| :--- | :----: | :------------------------ |
| id   | string | The resource ID.          |
| name | string | The name of the resource. |

## Examples

### Example 1

```bicep
```

### Example 2

```bicep
```