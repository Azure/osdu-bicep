# Azure App Configuration

This module deploys an App Configuration service.

## Description

This module supports the following features

- key-value pairs
- keyValault references (refer to Example 3)

## Parameters

| Name               | Type     | Required | Description                                                                                                                                                                                                                                                                   |
| :----------------- | :------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`     | `string` | Yes      | Used to name all resources                                                                                                                                                                                                                                                    |
| `location`         | `string` | No       | Resource Location.                                                                                                                                                                                                                                                            |
| `enableDeleteLock` | `bool`   | No       | Enable lock to prevent accidental deletion                                                                                                                                                                                                                                    |
| `tags`             | `object` | No       | Tags.                                                                                                                                                                                                                                                                         |
| `sku`              | `string` | No       | App Configuration SKU.                                                                                                                                                                                                                                                        |
| `configObjects`    | `object` | No       | Specifies all configuration values {"key":"","value":""} wrapped in an object.                                                                                                                                                                                                |
| `roleAssignments`  | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep |

## Outputs

| Name | Type   | Description                                            |
| :--- | :----: | :----------------------------------------------------- |
| name | string | The name of the azure app configuration service.       |
| id   | string | The resourceId of the azure app configuration service. |

## Examples

### Example 1

```bicep
module configStore 'br:osdubicep.azurecr.io/public/app-configuration:1.0.2' = {
  name: 'azure_app_config'
  params: {
    resourceName: 'ac${unique(resourceGroup().name)}'
    location: 'southcentralus'
  }
}
```

### Example 2

```bicep
// Feature Flag Sample
var featureFlagKey = 'AFeatureFlag'
var featureFlagDescription = 'This is a sample feature flag'
var featureFlagLabel = 'development'

// Key Vault Secret
@description('Format should be https://{vault-name}.{vault-DNS-suffix}/secrets/{secret-name}/{secret-version}. Secret version is optional.')
var kvSecret = 'https://akeyvault.vault.azure.net/secrets/asecret'
var keyVaultRef = {
  uri: kvSecret
}

//  Module --> Create Resource
module app_config 'br:osdubicep.azurecr.io/public/app-configuration:1.0.2' = {
  name: 'azure_app_config'
  params: {
    resourceName: 'ac${unique(resourceGroup().name)}'
    location: 'southcentralus'
    
    keyValues: [
      // Simple Key Value Pair
      {
        name: 'AValue'
        value: 'Hello World'
        contentType: 'text/plain'
        label: 'development'
        tags: {
          service: 'worker'
        }
      }
      // Key Vault Secret Reference
      {
        name: 'ASecret'
        value: string(keyVaultRef)
        contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
        label: 'development'
        tags: {
          service: 'worker'
        }
      }
      // Feature Flag Sample
      {
        name: '.appconfig.featureflag~2F${featureFlagKey}$${featureFlagLabel}'
        value: string({
        id: featureFlagKey
        description: featureFlagDescription
        enabled: true
      })
        contentType: 'application/vnd.microsoft.appconfig.ff+json;charset=utf-8'
        tags: {
          service: 'worker'
        }
      }
    ]

    // Add Role Assignment
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'App Configuration Data Reader'
        principalIds: [
          identity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Enable Diagnostics
    diagnosticWorkspaceId: logs.outputs.id

    // Hook up the identity to the database
    systemAssignedIdentity: false
    userAssignedIdentities: {
      '${identity.outputs.id}': { }
      '/subscriptions/222222-2222-2222-2222-2222222222/resourcegroups/keep/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aidentity': {}
    }

    // Enable Private Link
    privateLinkSettings:{
      vnetId: network.outputs.id
      subnetId: network.outputs.subnetIds[0]
    }

    // Enable Customer Managed Encryption Key
    cmekConfiguration: {
      kvUrl: 'https://akeyvault.vault.azure.net'
      keyName: 'akey'
      identityId: '222222-2222-2222-2222-2222222222'
    }
  }
}
```

### Example 3

```bicep
module ac 'br:osdubicep.azurecr.io/bicep/modules/public/app-configuration:1.0.2' = {
  name: 'azure_app_configuration'
  params: {
    resourceName: 'ac${unique(resourceGroup().name)}'
    location: 'southcentralus'
    enableDeleteLock: true
    configObjects: {
      configs: [
        {
          key: 'myKey'
          value: 'myValue'
        }
        {
          key: 'keyVaultref'
          value: string(
            {
              uri: 'keyVaultSecretURL'
            }
          )
          contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
        }
      ]
    }
  }
}
```