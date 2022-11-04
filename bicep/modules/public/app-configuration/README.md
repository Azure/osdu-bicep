# Azure App Configuration

This module deploys an App Configuration service.

## Description

{{ Add detailed description for the module. }}

## Parameters

| Name                                    | Type           | Required | Description                                                                                                                                                                                                                                                                   |
| :-------------------------------------- | :------------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                          | `string`       | Yes      | Used to name all resources                                                                                                                                                                                                                                                    |
| `location`                              | `string`       | No       | Resource Location.                                                                                                                                                                                                                                                            |
| `enableDeleteLock`                      | `bool`         | No       | Enable lock to prevent accidental deletion                                                                                                                                                                                                                                    |
| `tags`                                  | `object`       | No       | Tags.                                                                                                                                                                                                                                                                         |
| `sku`                                   | `string`       | No       | App Configuration SKU.                                                                                                                                                                                                                                                                |
| `configObject`                         | `object` | No       | Specifies all key/value pairs {"key":"","value":""} wrapped in a secure object.                                                                                                                                                                                          |

## Outputs

| Name | Type   | Description                           |
| :--- | :----: | :------------------------------------ |
| name | string | The name of the azure app configuration service.       |
| id   | string | The resourceId of the azure app configuration service. |

## Examples

### Example 1

```bicep
module kv 'br:osdubicep.azurecr.io/bicep/modules/public/app-configuration:1.0.2' = {
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
module kv 'br:osdubicep.azurecr.io/bicep/modules/public/app-configuration:1.0.2' = {
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