targetScope = 'resourceGroup'

@minLength(5)
@maxLength(48)
@description('Used to name all resources')
param resourceName string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Enable lock to prevent accidental deletion')
param enableDeleteLock bool = false

@description('Tags.')
param tags object = {}

@description('App Configuration SKU.')
param sku string = 'Standard'

@description('Specifies all configuration values {"key":"","value":""} wrapped in an object.')
param configObjects object = {
  /* example
    configs: [
      {
        key: 'myKey'
        value: 'myValue'
      }
    ]
  */
}

@description('Specifies the content type of the key-value resources. For feature flag, the value should be application/vnd.microsoft.appconfig.ff+json;charset=utf-8. For Key Value reference, the value should be application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8. Otherwise, it\'s optional.')
param contentType string = 'the-content-type'

@description('Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep')
param roleAssignments array = [
  /* example
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          '222222-2222-2222-2222-2222222222'
        ]
        principalType: 'ServicePrincipal'
      }
  */
]

var name = 'ac-${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

resource configStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = {
  name: length(name) > 50 ? substring(name, 0, 50) : name
  location: location
  sku: {
    name: sku
  }
  tags: tags
}

resource configStoreKeyValue 'Microsoft.AppConfiguration/configurationStores/keyValues@2022-05-01' = [for config in configObjects.configs: {
  parent: configStore
  name: config.key
  properties: {
    value: config.value
    contentType: contentType
  }
}]

// Resource Locking
resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (enableDeleteLock) {
  scope: configStore

  name: '${configStore.name}-lock'
  properties: {
    level: 'CanNotDelete'
  }
}

module configStore_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    resourceId: configStore.id
  }
}]

@description('The name of the azure app configuration service.')
output name string = configStore.name

@description('The resourceId of the azure app configuration service.')
output id string = configStore.id
