targetScope = 'resourceGroup'

@minLength(3)
@maxLength(22)
@description('Used to name all resources')
param resourceName string

@description('Resource Location.')
param location string = resourceGroup().location

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Tags.')
param tags object = {}

@description('Specifies the storage account sku type.')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'Standard_GRS'
])
param sku string = 'Standard_LRS'

@description('Specifies the storage account access tier.')
@allowed([
  'Cool'
  'Hot'
])
param accessTier string = 'Hot'


@description('Optional. Array of Storage Containers to be created.')
param containers array = [
  /* example
  'one'
  'two'
  */
]

@description('Optional. Array of Storage Tables to be created.')
param tables array = [
  /* example
  'one'
  'two'
  */
]

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

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'StorageRead'
  'StorageWrite'
  'StorageDelete'
])
param logsToEnable array = [
  'StorageRead'
  'StorageWrite'
  'StorageDelete'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}

@description('Amount of days the soft deleted data is stored and available for recovery. 0 is off.')
@minValue(0)
@maxValue(365)
param deleteRetention int = 0

var enableCMEK = !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) && !empty(cmekConfiguration.identityId) ? true : false

var name = 'sa${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

var diagnosticsLogs = [for log in logsToEnable: {
  category: log
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in metricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]



// Create Storage Account
resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: length(name) > 24 ? substring(name, 0, 24) : name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'

  identity: enableCMEK ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${cmekConfiguration.identityId}': {}
    }
  } : json('null')

  properties: {
    accessTier: accessTier
    minimumTlsVersion: 'TLS1_2'

    encryption: enableCMEK ? {
      identity: {
        userAssignedIdentity: cmekConfiguration.identityId
      }
      services: {
         blob: {
           enabled: true
         }
         table: {
            enabled: true
         }
         file: {
            enabled: true
         }
      }
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyname: cmekConfiguration.keyName
        keyvaulturi: cmekConfiguration.kvUrl
      }
    } : {
      services: {
         blob: {
           enabled: true
         }
         table: {
            enabled: true
         }
         file: {
            enabled: true
         }
      }
      keySource: 'Microsoft.Storage'
    }

    networkAcls: enablePrivateLink ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    } : {}
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storage
  name: 'default'
  properties: deleteRetention > 0 ? {
    changeFeed: {
      enabled: true
    }
    restorePolicy: {
      enabled: true
      days: 6
    }
    isVersioningEnabled: true
    deleteRetentionPolicy: {
      enabled: true
      days: deleteRetention
    }
  } : {
    deleteRetentionPolicy: {
      enabled: false
      allowPermanentDelete: false
    }
  }
}

resource storage_containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = [for item in containers: {
  name: '${storage.name}/default/${item}'
  properties: {
    defaultEncryptionScope:      '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess:                'None'
  }
}]

resource storage_tables 'Microsoft.Storage/storageAccounts/tableServices/tables@2022-05-01' = [for item in tables: {
  name: '${storage.name}/default/${item}'
}]

// Apply Resource Lock
resource resource_lock 'Microsoft.Authorization/locks@2017-04-01' = if (lock != 'NotSpecified') {
  name: '${storage.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: storage
}

module storage_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    resourceId: storage.id
  }
}]



// Hook up Diagnostics
resource storage_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: 'storage-diagnostics'
  scope: blobServices
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  dependsOn: [
    storage
  ]
}


////////////////
// Private Link
////////////////

@description('Settings Required to Enable Private Link')
param privateLinkSettings object = {
  subnetId: '1' // Specify the Subnet for Private Endpoint
  vnetId: '1'  // Specify the Virtual Network for Virtual Network Link
}

var enablePrivateLink = privateLinkSettings.vnetId != '1' && privateLinkSettings.subnetId != '1'


@description('Specifies the name of the private link to the Resource.')
var privateEndpointName = '${name}-PrivateEndpoint'

var publicDNSZoneForwarder = 'blob.${environment().suffixes.storage}'
var privateDnsZoneName = 'privatelink.${publicDNSZoneForwarder}'

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = if (enablePrivateLink) {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSettings.subnetId
    }
  }
  dependsOn: [
    storage
  ]
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = if (enablePrivateLink) {
  name: '${privateEndpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: privateDNSZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateDNSZone
  ]
}

#disable-next-line BCP081
resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateLink) {
  parent: privateDNSZone
  name: 'link_to_vnet'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: privateLinkSettings.vnetId
    }
  }
  dependsOn: [
    privateDNSZone
  ]
}

@description('The resource ID.')
output id string = storage.id

@description('The name of the resource.')
output name string = storage.name
