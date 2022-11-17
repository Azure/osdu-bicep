# Azure App Service Module

This module deploys an Azure App Service.

## Description

{{ Add detailed description for the module. }}

## Parameters

| Name                    | Type     | Required | Description                                                                                                                           |
| :---------------------- | :------: | :------: | :------------------------------------------------------------------------------------------------------------------------------------ |
| `resourceName`          | `string` | Yes      | Used to name all resources                                                                                                            |
| `location`              | `string` | No       | Resource Location.                                                                                                                    |
| `sku`                   | `string` | No       | SKU for the App Service Plan                                                                                                          |
| `skuTier`               | `string` | No       | SKU tier for the App Service Plan                                                                                                     |
| `skuCapacity`           | `int`    | No       | Capacity for the App Service Plan                                                                                                     |
| `enableDeleteLock`      | `bool`   | No       | Enable lock to prevent accidental deletion                                                                                            |
| `linuxFxVersion`        | `string` | No       | The Runtime stack of current web app                                                                                                  |
| `clientAffinityEnabled` | `bool`   | No       | Improve performance of your stateless app by turning Affinity Cookie off, stateful apps should keep this setting on for compatibility |

## Outputs

| Name               | Type   | Description                            |
| :----------------- | :----: | :------------------------------------- |
| appServicePlanName | string | The name of the App Service Plan       |
| appServicePlanId   | string | The resourceId of the App Service Plan |
| appServiceName     | string | The name of the App Service            |
| appServiceId       | string | The resourceId of the App Service      |

## Examples

### Example 1

```bicep
```

### Example 2

```bicep
```