# Azure Storage Module

This module deploys an Azure Storage Account.

## Description

This module supports the following features.

- serviceResourceId(for example, existing storageAccount)
- Private Link (Secure network)
- privateDnsZone(existing privateDnsZone(s))

## Parameters

| Name                                  | Type     | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                     |
| :------------------------------------ | :------: | :------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                        | `string` | Yes      | Required. Name of the private endpoint resource to create.                                                                                                                                                                                                                                                                                                                                                      |
| `subnetResourceId`                    | `string` | Yes      | Required. Resource ID of the subnet where the endpoint needs to be created.                                                                                                                                                                                                                                                                                                                                     |
| `serviceResourceId`                   | `string` | Yes      | Required. Resource ID of the resource that needs to be connected to the network.                                                                                                                                                                                                                                                                                                                                |
| `groupIds`                            | `array`  | Yes      | Required. Subtype(s) of the connection to be created. The allowed values depend on the type serviceResourceId refers to.                                                                                                                                                                                                                                                                                        |
| `applicationSecurityGroups`           | `array`  | No       | Optional. Application security groups in which the private endpoint IP configuration is included.                                                                                                                                                                                                                                                                                                               |
| `customNetworkInterfaceName`          | `string` | No       | Optional. The custom name of the network interface attached to the private endpoint.                                                                                                                                                                                                                                                                                                                            |
| `ipConfigurations`                    | `array`  | No       | Optional. A list of IP configurations of the private endpoint. This will be used to map to the First Party Service endpoints.                                                                                                                                                                                                                                                                                   |
| `privateDnsZoneGroup`                 | `object` | No       | Optional. The private DNS zone group configuration used to associate the private endpoint with one or multiple private DNS zones. A DNS zone group can support up to 5 DNS zones.                                                                                                                                                                                                                               |
| `location`                            | `string` | No       | Optional. Location for all Resources.                                                                                                                                                                                                                                                                                                                                                                           |
| `roleAssignments`                     | `array`  | No       | Optional. Array of role assignment objects that contain the 'roleDefinitionIdOrName' and 'principalId' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: '/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11'. |
| `tags`                                | `object` | No       | Tags.                                                                                                                                                                                                                                                                                                                                                                                                           |
| `lock`                                | `string` | No       | Optional. Specify the type of lock.                                                                                                                                                                                                                                                                                                                                                                             |
| `customDnsConfigs`                    | `array`  | No       | Optional. Custom DNS configurations.                                                                                                                                                                                                                                                                                                                                                                            |
| `manualPrivateLinkServiceConnections` | `array`  | No       | Optional. Manual PrivateLink Service Connections.                                                                                                                                                                                                                                                                                                                                                               |

## Outputs

| Name              | Type   | Description                                                |
| :---------------- | :----: | :--------------------------------------------------------- |
| resourceGroupName | string | The resource group the private endpoint was deployed into. |
| resourceId        | string | The resource ID of the private endpoint.                   |
| name              | string | The name of the private endpoint.                          |
| location          | string | The location the resource was deployed into.               |

## Examples

### Example 1

```bicep
module privateEndpoint 'br:osdubicep.azurecr.io/public/privateEndpoints:1.0.4' = {
  name: 'private-endpoint'
  params: {
    resourceName: privateEndpointName
    subnetResourceId: network.outputs.subnetIds[0]
    serviceResourceId: storage.outputs.resourceIds
    groupIds: ["blobs"]
  }
}
```