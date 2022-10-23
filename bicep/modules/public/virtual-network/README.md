# Azure Virtual Network

This module deploys a virtual network.

## Description

{{ Add detailed description for the module. }}

## Parameters

| Name                                    | Type     | Required | Description                                                                                                                                                                                                                                                                                                                      |
| :-------------------------------------- | :------: | :------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                          | `string` | Yes      | Used to name all resources                                                                                                                                                                                                                                                                                                       |
| `location`                              | `string` | No       | Resource Location.                                                                                                                                                                                                                                                                                                               |
| `tags`                                  | `object` | No       | Resource Tags (Optional).                                                                                                                                                                                                                                                                                                        |
| `lock`                                  | `string` | No       | Optional. Specify the type of lock.                                                                                                                                                                                                                                                                                              |
| `virtualNetworkPeerings`                | `array`  | No       | Optional. Virtual Network Peerings configurations                                                                                                                                                                                                                                                                                |
| `diagnosticWorkspaceId`                 | `string` | No       | Optional. Resource ID of the diagnostic log analytics workspace.                                                                                                                                                                                                                                                                 |
| `diagnosticStorageAccountId`            | `string` | No       | Optional. Resource ID of the diagnostic storage account.                                                                                                                                                                                                                                                                         |
| `diagnosticEventHubAuthorizationRuleId` | `string` | No       | Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.                                                                                                                                                                       |
| `diagnosticEventHubName`                | `string` | No       | Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.                                                                                                                                                                         |
| `newOrExistingNSG`                      | `string` | No       | Create a new, use an existing, or provide no default NSG.                                                                                                                                                                                                                                                                        |
| `networkSecurityGroupName`              | `string` | No       | Name of default NSG to use for subnets.                                                                                                                                                                                                                                                                                          |
| `dnsServers`                            | `array`  | No       | Optional. DNS Servers associated to the Virtual Network.                                                                                                                                                                                                                                                                         |
| `ddosProtectionPlanId`                  | `string` | No       | Optional. Resource ID of the DDoS protection plan to assign the VNET to. If it's left blank, DDoS protection will not be configured. If it's provided, the VNET created by this template will be attached to the referenced DDoS protection plan. The DDoS protection plan can exist in the same or in a different subscription. |
| `diagnosticLogsRetentionInDays`         | `int`    | No       | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.                                                                                                                                                                                                                   |
| `logsToEnable`                          | `array`  | No       | Optional. The name of logs that will be streamed.                                                                                                                                                                                                                                                                                |
| `metricsToEnable`                       | `array`  | No       | Optional. The name of metrics that will be streamed.                                                                                                                                                                                                                                                                             |
| `addressPrefixes`                       | `array`  | No       | Virtual Network Address CIDR                                                                                                                                                                                                                                                                                                     |
| `subnets`                               | `array`  | No       | Virtual Network Subnets                                                                                                                                                                                                                                                                                                          |
| `roleAssignments`                       | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep                                                    |

## Outputs

| Name        | Type   | Description                              |
| :---------- | :----: | :--------------------------------------- |
| id          | string | The resource ID of the virtual network   |
| name        | string | The name of the virtual network          |
| subnetNames | array  | The names of the deployed subnets        |
| subnetIds   | array  | The resource IDs of the deployed subnets |

## Examples

### Example 1

```bicep
module vnet 'br:osdubicep.azurecr.io/bicep/modules/public/virtual-network:1.0.1' = {
  name: 'azure_vnet'
  params: {
    resourceName: `vnet-${unique(resourceGroup().name)}'
    location: 'southcentralus'
    addressPrefixes: [
      '192.168.0.0/24'
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '192.168.0.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          '222222-2222-2222-2222-2222222222'
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}
```

### Example 2

```bicep
```