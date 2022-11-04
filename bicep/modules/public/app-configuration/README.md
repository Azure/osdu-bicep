# Azure App Configuration

This module deploys an App Configuration service.

## Description

{{ Add detailed description for the module. }}

## Parameters

| Name               | Type     | Required | Description                                                                                                                                                                                                                                                                                        |
| :----------------- | :------: | :------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`     | `string` | Yes      | Used to name all resources                                                                                                                                                                                                                                                                         |
| `location`         | `string` | No       | Resource Location.                                                                                                                                                                                                                                                                                 |
| `enableDeleteLock` | `bool`   | No       | Enable lock to prevent accidental deletion                                                                                                                                                                                                                                                         |
| `tags`             | `object` | No       | Tags.                                                                                                                                                                                                                                                                                              |
| `sku`              | `string` | No       | App Configuration SKU.                                                                                                                                                                                                                                                                             |
| `configObjects`    | `object` | No       | Specifies all configuration values {"key":"","value":""} wrapped in an object.                                                                                                                                                                                                                     |
| `contentType`      | `string` | No       | Specifies the content type of the key-value resources. For feature flag, the value should be application/vnd.microsoft.appconfig.ff+json;charset=utf-8. For Key Value reference, the value should be application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8. Otherwise, it's optional. |
| `roleAssignments`  | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep                      |

## Outputs

| Name | Type   | Description                                            |
| :--- | :----: | :----------------------------------------------------- |
| name | string | The name of the azure app configuration service.       |
| id   | string | The resourceId of the azure app configuration service. |

## Examples

### Example 1

```bicep
module configStore 'br:osdubicep.azurecr.io/bicep/modules/public/app-configuration:1.0.2' = {
  name: 'azure_app_config'
  params: {
    resourceName: 'ac${unique(resourceGroup().name)}'
    location: 'southcentralus'
    configObjects: { configs: []}
  }
}
```

### Example 2

```bicep
module configStore 'br:osdubicep.azurecr.io/bicep/modules/public/app-configuration:1.0.2' = {
  name: 'azure_app_config'
  params: {
    resourceName: 'ac${unique(resourceGroup().name)}'
    location: 'southcentralus'
    
    // Add secrets
    configObjects: {
      configs: [
        {
          key: 'Hello'
          value: 'World'
        }
      ]
    }
  }
}
```