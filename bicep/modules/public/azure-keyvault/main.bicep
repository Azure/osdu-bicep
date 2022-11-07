targetScope = 'resourceGroup'

@minLength(3)
@maxLength(20)
@description('Used to name all resources')
param resourceName string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Tags.')
param tags object = {}

@description('Enable lock to prevent accidental deletion')
param enableDeleteLock bool = false

@description('Key Vault SKU.')
param sku string = 'Standard'

@description('Specify Access Policies to Enable (Optional).')
param accessPolicies array = [
  /* example
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
  */
]

@description('Key Vault Retention Days.')
@minValue(7)
@maxValue(14)
param softDeleteRetentionInDays int = 7

@description('Specifies all secrets {"secretName":"","secretValue":""} wrapped in a secure object.')
@secure()
param secretsObject object = {
  /* example
    secrets: [
      {
        secretName: 'mySecret'
        secretValue: 'myValue'
      }
    ]
  */
}

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
  'AuditEvent'
  'AzurePolicyEvaluationDetails'
])
param logsToEnable array = [
  'AuditEvent'
  'AzurePolicyEvaluationDetails'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

var name = 'kv-${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

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

var enableSecrets = contains(secretsObject, 'secrets') && length(secretsObject.secrets) > 0


// Create Azure Key Vault
resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: length(name) > 24 ? substring(name, 0, 24) : name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: sku
    }

    accessPolicies: [for access in accessPolicies: {
      objectId: access.principalId
      tenantId: subscription().tenantId
      permissions: access.permissions
    }]

    softDeleteRetentionInDays: softDeleteRetentionInDays
    enabledForDeployment: false
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    networkAcls: enablePrivateLink ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    } : {}
    publicNetworkAccess: enablePrivateLink ? 'Disabled' : 'Enabled'
  }
}

// Secret Management
resource kv_secrets 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = [for secret in secretsObject.secrets: if (enableSecrets) {
  name: secret.secretName
  parent: keyvault
  properties: {
    value: secret.secretValue
  }
}]

// Resource Locking
resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (enableDeleteLock) {
  scope: keyvault

  name: '${keyvault.name}-lock'
  properties: {
    level: 'CanNotDelete'
  }
}

// Role Assignments
module keyvault_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    resourceId: keyvault.id
  }
}]

// Hook up Diagnostics
resource keyvault_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: 'keyvault-diagnostics'
  scope: keyvault
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  dependsOn: [
    keyvault
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

@description('Specifies the name of the private link to the Azure Container Registry.')
var privateEndpointName = '${name}-PrivateEndpoint'

var privateDNSZoneName = 'privatelink.vaultcore.azure.net'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if (enablePrivateLink) {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateLinkSettings.subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: keyvault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    customDnsConfigs: [
      {
        fqdn: privateDNSZoneName
      }
    ]
  }
  dependsOn: [
    keyvault
  ]
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateLink) {
  name: '${privateDNSZone.name}/${privateDNSZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: privateLinkSettings.vnetId
    }
  }
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: privateDNSZoneName
  location: 'global'
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = if (enablePrivateLink) {
  name: '${privateEndpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDNSZone.id
        }
      }
    ]
  }
}

@description('The name of the azure keyvault.')
output name string = keyvault.name

@description('The resourceId of the azure keyvault.')
output id string = keyvault.id
