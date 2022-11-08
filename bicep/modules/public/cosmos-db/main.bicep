targetScope = 'resourceGroup'

@minLength(3)
@maxLength(20)
@description('Used to name all resources')
param resourceName string

@description('Optional: Resource Location.')
param resourceLocation string = resourceGroup().location

@description('Tags.')
param tags object = {}

@description('Enable lock to prevent accidental deletion')
param enableDeleteLock bool = false

@description('Optional. Locations enabled for the Cosmos DB account.')
param multiwriteRegions array = [
  /* example
    {
      failoverPriority: 0
      isZoneRedundant: false
      locationName: 'South Central US'
    }
  */
]



@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. The default identity to be used.')
param defaultIdentity string = ''

@description('Optional. The offer type for the Cosmos DB database account.')
@allowed([
  'Standard'
])
param databaseAccountOfferType string = 'Standard'

@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
@description('Optional. The default consistency level of the Cosmos DB account.')
param defaultConsistencyLevel string = 'Session'

@description('Optional. Enable automatic failover for regions.')
param automaticFailover bool = true

@minValue(10)
@maxValue(2147483647)
@description('Optional. Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.')
param maxStalenessPrefix int = 100000

@minValue(5)
@maxValue(86400)
@description('Optional. Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
param maxIntervalInSeconds int = 300

@description('Optional. Specifies the MongoDB server version to use.')
@allowed([
  '3.2'
  '3.6'
  '4.0'
  '4.2'
])
param serverVersion string = '4.2'

@description('Optional. SQL Databases configurations.')
param sqlDatabases array = []

@description('Optional. Gremlin Databases configurations.')
param gremlinDatabases array = []

@description('Optional. MongoDB Databases configurations.')
param mongodbDatabases array = []

@allowed([
  'EnableCassandra'
  'EnableTable'
  'EnableGremlin'
  'EnableMongo'
  'DisableRateLimitingResponses'
  'EnableServerless'
])
@description('Optional. List of Cosmos DB capabilities for the account.')
param capabilitiesToAdd array = []

@allowed([
  'Periodic'
  'Continuous'
])
@description('Optional. Describes the mode of backups.')
param backupPolicyType string = 'Periodic'

@allowed([
  'Continuous30Days'
  'Continuous7Days'
])
@description('Optional. Configuration values for continuous mode backup.')
param backupPolicyContinuousTier string = 'Continuous30Days'

@minValue(60)
@maxValue(1440)
@description('Optional. An integer representing the interval in minutes between two backups. Only applies to periodic backup type.')
param backupIntervalInMinutes int = 240

@minValue(2)
@maxValue(720)
@description('Optional. An integer representing the time (in hours) that each backup is retained. Only applies to periodic backup type.')
param backupRetentionIntervalInHours int = 8

@allowed([
  'Geo'
  'Local'
  'Zone'
])
@description('Optional. Enum to indicate type of backup residency. Only applies to periodic backup type.')
param backupStorageRedundancy string = 'Local'


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
  'DataPlaneRequests'
  'MongoRequests'
  'QueryRuntimeStatistics'
  'PartitionKeyStatistics'
  'PartitionKeyRUConsumption'
  'ControlPlaneRequests'
  'CassandraRequests'
  'GremlinRequests'
  'TableApiRequests'
])
param logsToEnable array = [
  'DataPlaneRequests'
  'MongoRequests'
  'QueryRuntimeStatistics'
  'PartitionKeyStatistics'
  'PartitionKeyRUConsumption'
  'ControlPlaneRequests'
  'CassandraRequests'
  'GremlinRequests'
  'TableApiRequests'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'Requests'
])
param metricsToEnable array = [
  'Requests'
]

@description('Optional. Customer Managed Encryption Key.')
param kvKeyUri string = ''

var name = 'dba-${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'


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

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}

var databaseAccount_locations = [for location in multiwriteRegions: {
  failoverPriority: location.failoverPriority
  isZoneRedundant: location.isZoneRedundant
  locationName: location.locationName
}]

var kind = !empty(sqlDatabases) || !empty(gremlinDatabases) ? 'GlobalDocumentDB' : (!empty(mongodbDatabases) ? 'MongoDB' : 'Parse')

var enableReferencedModulesTelemetry = false

var capabilities = [for capability in capabilitiesToAdd: {
  name: capability
}]

var backupPolicy = backupPolicyType == 'Continuous' ? {
  type: backupPolicyType
  continuousModeProperties: {
    tier: backupPolicyContinuousTier
  }
} : {
  type: backupPolicyType
  periodicModeProperties: {
    backupIntervalInMinutes: backupIntervalInMinutes
    backupRetentionIntervalInHours: backupRetentionIntervalInHours
    backupStorageRedundancy: backupStorageRedundancy
  }
}

var databaseAccount_properties = union({
    databaseAccountOfferType: databaseAccountOfferType
  }, ((!empty(sqlDatabases) || !empty(mongodbDatabases) || !empty(gremlinDatabases)) ? {
    // Common properties
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    enableMultipleWriteLocations: empty(multiwriteRegions) ? false : true
    locations: empty(multiwriteRegions) ? [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: resourceLocation
      }
    ] : databaseAccount_locations

    capabilities: capabilities
    backupPolicy: backupPolicy
  } : {}), (!empty(sqlDatabases) ? {
    // SQLDB properties
    enableAutomaticFailover: automaticFailover
    AnalyticalStorageConfiguration: {
      schemaType: 'WellDefined'
    }
    defaultIdentity: !empty(defaultIdentity) ? 'UserAssignedIdentity=${defaultIdentity}': 'FirstPartyIdentity'
    enablePartitionKeyMonitor: true
    enablePartitionMerge: false
    keyVaultKeyUri:  !empty(kvKeyUri) ? kvKeyUri : json('null')
  } : {}), (!empty(mongodbDatabases) ? {
    // MongoDb properties
    apiProperties: {
      serverVersion: serverVersion
    }
  } : {
    EnabledApiTypes: [
      'Sql'
    ]
  }))




// Create Database Account
resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: length(name) > 44 ? substring(name, 0, 44) : name
  location: resourceLocation
  tags: tags
  identity: {
    type: identityType
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : {}
  }
  kind: kind
  properties: databaseAccount_properties
}

module databaseAccount_sqlDatabases '.bicep/sql_database.bicep' = [for sqlDatabase in sqlDatabases: {
  name: '${deployment().name}-${sqlDatabase.name}'
  params: {
    databaseAccountName: databaseAccount.name
    name: sqlDatabase.name
    containers: contains(sqlDatabase, 'containers') ? sqlDatabase.containers : []
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}]

module databaseAccount_gremlinDatabases './.bicep/gremlin_database.bicep' = [for gremlinDatabase in gremlinDatabases: {
  name: '${deployment().name}-${gremlinDatabase.name}'
  params: {
    databaseAccountName: databaseAccount.name
    name: gremlinDatabase.name
    graphs: contains(gremlinDatabase, 'graphs') ? gremlinDatabase.graphs : []
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}]


// Resource Locking
resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (enableDeleteLock) {
  scope: databaseAccount

  name: '${databaseAccount.name}-lock'
  properties: {
    level: 'CanNotDelete'
  }
}

// Hook up Diagnostics
resource storage_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: 'storage-diagnostics'
  scope: databaseAccount
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
    logAnalyticsDestinationType: 'AzureDiagnostics'
  }
  dependsOn: [
    databaseAccount
  ]
}

// Role Assignments
module databaseaccount_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    resourceId: databaseAccount.id
  }
}]


@description('The name of the database account.')
output name string = databaseAccount.name

@description('The resource ID of the database account.')
output id string = databaseAccount.id

@description('The name of the resource group the database account was created in.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(databaseAccount.identity, 'principalId') ? databaseAccount.identity.principalId : ''

@description('The location the resource was deployed into.')
output location string = databaseAccount.location


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

var privateDNSZoneName = 'privatelink.documents.azure.com'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if (enablePrivateLink) {
  name: privateEndpointName
  location: resourceLocation
  properties: {
    subnet: {
      id: privateLinkSettings.subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: databaseAccount.id
          groupIds: [
            'Sql'
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
    databaseAccount
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


////////////////
// Secrets
////////////////

@description('Optional: Key Vault Name to store secrets into')
param keyVaultName string = ''

@description('Optional: To save storage account name into vault set the secret hame.')
param databaseEndpointSecretName string = ''

@description('Optional: To save storage account key into vault set the secret hame.')
param databasePrimaryKeySecretName string = ''

@description('Optional: To save storage account connectionstring into vault set the secret hame.')
param databaseConnectionStringSecretName string = ''

module secretDatabaseEndpoint  '.bicep/keyvault_secrets.bicep' = if (!empty(keyVaultName) && !empty(databaseEndpointSecretName)) {
  name: '${deployment().name}-secret-name'
  params: {
    keyVaultName: keyVaultName
    name: databaseEndpointSecretName
    value: databaseAccount.properties.documentEndpoint
  }
}

module secretDatabasePrimaryKey '.bicep/keyvault_secrets.bicep' =  if (!empty(keyVaultName) && !empty(databasePrimaryKeySecretName)) {
  name: '${deployment().name}-secret-key'
  params: {
    keyVaultName: keyVaultName
    name: databasePrimaryKeySecretName
    value: databaseAccount.listKeys().primaryMasterKey
  }
}

module secretDatabaseConnectionString '.bicep/keyvault_secrets.bicep' =  if (!empty(keyVaultName) && !empty(databaseConnectionStringSecretName)) {
  name: '${deployment().name}-secret-accountName'
  params: {
    keyVaultName: keyVaultName
    name: databaseConnectionStringSecretName
    value: databaseAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}
