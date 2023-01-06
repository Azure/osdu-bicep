/*
  This is the main bicep entry file.

  11.10.22: Common, Partition and Services
--------------------------------
  - Established the three layers.
*/

@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

@description('Optional. Indicates if the application is used in a cross tenant scenario or not.')
param crossTenant bool = false

/////////////////
// Settings Blade 
/////////////////
@description('Specify the AD Application Client Id.')
param applicationClientId string

@description('List of Data Partitions')
param partitions array = [
  {
    name: 'opendes'
  }
]

@allowed([
  'CostOptimised'
  'Standard'
  'HighSpec'
])
@description('The Cluster Sizing')
param clusterSize string = 'CostOptimised'

@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}

@description('Optional. Indicates if software should be installed.')
param enableSoftwareLoad bool = true

@description('Optional: Specify the AD Users and/or Groups that can manage the cluster.')
param clusterAdminIds array = []


/////////////////
// Network Blade 
/////////////////
@description('Name of the Virtual Network')
param virtualNetworkName string = 'osdu-network'

@description('Boolean indicating whether the VNet is new or existing')
param virtualNetworkNewOrExisting string = 'new'

@description('VNet address prefix')
param virtualNetworkAddressPrefix string = '10.1.0.0/16'

@description('Resource group of the VNet')
param virtualNetworkResourceGroup string = 'osdu-network'

@description('New or Existing subnet Name')
param subnetName string = 'clustersubnet'

@description('Subnet address prefix')
param subnetAddressPrefix string = '10.1.0.0/20'

@description('Feature Flag on Private Link')
param enablePrivateLink bool = false

/////////////////////////////////
// Common Resources Configuration 
/////////////////////////////////
var commonLayerConfig = {
  name: 'common'
  displayName: 'Common Resources'
  secrets: {
    tenantId: 'tenant-id'
    subscriptionId: 'subscription-id'
    registryName: 'container-registry'
    applicationId: 'aad-client-id'
    clientId: 'app-dev-sp-username'
    clientSecret: 'app-dev-sp-password'
    applicationPrincipalId: 'app-dev-sp-id'
    stampIdentity: 'osdu-identity-id'
    storageAccountName: 'tbl-storage'
    storageAccountKey: 'tbl-storage-key'
    cosmosConnectionString: 'graph-db-connection'
    cosmosEndpoint: 'graph-db-endpoint'
    cosmosPrimaryKey: 'graph-db-primary-key'
    logAnalyticsId: 'log-workspace-id'
    logAnalyticsKey: 'log-workspace-key'
  }
  logs: {
    sku: 'PerGB2018'
    retention: 30
  }
  registry: {
    sku: 'Premium'
  }
  storage: {
    sku: 'Standard_LRS'
    tables: [
      'PartitionInfo'
    ]
  }
  database: {
    name: 'graph-db'
    throughput: 2000
    backup: 'Continuous'
    graphs: [
      {
        name: 'Entitlements'
        automaticIndexing: true
        partitionKeyPaths: [
          '/dataPartitionId'
        ]
      }
    ]
  }
}

/////////////////////////////////
// Data Partition Configuration 
/////////////////////////////////
var partitionLayerConfig = {
  name: 'partition'
  displayName: 'Data Partition Resources'
  secrets: {
    storageAccountName: 'storage'
    storageAccountKey: 'key'
    cosmosConnectionString: 'cosmos-connection'
    cosmosEndpoint: 'cosmos-endpoint'
    cosmosPrimaryKey: 'cosmos-primary-key'
  }
  storage: {
    sku: 'Standard_LRS'
    containers: [
      'legal-service-azure-configuration'
      'osdu-wks-mappings'
      'wdms-osdu'
      'file-staging-area'
      'file-persistent-area'
    ]
  }
  database: {
    name: 'osdu-db'
    CostOptimised : {
      throughput: 2000
    }
    Standard: {
      throughput: 4000
    }
    HighSpec: {
      throughput: 12000
    }
    backup: 'Continuous'
    containers: [
      {
        name: 'LegalTag'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'StorageRecord'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'StorageSchema'
        kind: 'Hash'
        paths: [
          '/kind'
        ]
      }
      {
        name: 'TenantInfo'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'UserInfo'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'Authority'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'EntityType'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'SchemaInfo'
        kind: 'Hash'
        paths: [
          '/partitionId'
        ]
      }
      {
        name: 'Source'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'RegisterAction'
        kind: 'Hash'
        paths: [
          '/dataPartitionId'
        ]
      }
      {
        name: 'RegisterDdms'
        kind: 'Hash'
        paths: [
          '/dataPartitionId'
        ]
      }
      {
        name: 'RegisterSubscription'
        kind: 'Hash'
        paths: [
          '/dataPartitionId'
        ]
      }
      {
        name: 'IngestionStrategy'
        kind: 'Hash'
        paths: [
          '/workflowType'
        ]
      }
      {
        name: 'RelationshipStatus'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'MappingInfo'
        kind: 'Hash'
        paths: [
          '/sourceSchemaKind'
        ]
      }
      {
        name: 'FileLocationInfo'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'WorkflowCustomOperatorInfo'
        kind: 'Hash'
        paths: [
          '/operatorId'
        ]
      }
      {
        name: 'WorkflowV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowRunV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowCustomOperatorV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowTasksSharingInfoV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'Status'
        kind: 'Hash'
        paths: [
          '/correlationId'
        ]
      }
      {
        name: 'DataSetDetails'
        kind: 'Hash'
        paths: [
          '/correlationId'
        ]
      }
    ]
  }
}

/////////////////////////////////
// Service Resources Configuration 
/////////////////////////////////
var serviceLayerConfig = {
  name: 'service'
  displayName: 'Service Resources'
  imageNames: [
    'community.opengroup.org:5555/osdu/platform/system/partition/partition-v0-16-0:latest'
    'community.opengroup.org:5555/osdu/platform/security-and-compliance/entitlements/entitlements-v0-16-0:latest'
    'community.opengroup.org:5555/osdu/platform/security-and-compliance/legal/legal-v0-16-0:latest'
    'community.opengroup.org:5555/osdu/platform/system/schema-service/schema-service-release-0-16:latest'
    'community.opengroup.org:5555/osdu/platform/system/storage/storage-v0-16-1:latest'
    'community.opengroup.org:5555/osdu/platform/system/file/file-v0-16-1:latest'
    'community.opengroup.org:5555/osdu/platform/system/indexer-service/indexer-service-v0-16-0:latest'
    'community.opengroup.org:5555/osdu/platform/system/search-service/search-service-v0-16-1:latest'
  ]
  gitops: {
    name: 'flux-system'
    url: 'https://github.com/azure/osdu-bicep'
    branch: 'main'
    components: './stamp/components'
    applications: './stamp/applications'
  }
}


/*
 __   _______   _______ .__   __. .___________. __  .___________.____    ____ 
|  | |       \ |   ____||  \ |  | |           ||  | |           |\   \  /   / 
|  | |  .--.  ||  |__   |   \|  | `---|  |----`|  | `---|  |----` \   \/   /  
|  | |  |  |  ||   __|  |  . `  |     |  |     |  |     |  |       \_    _/   
|  | |  '--'  ||  |____ |  |\   |     |  |     |  |     |  |         |  |     
|__| |_______/ |_______||__| \__|     |__|     |__|     |__|         |__|     
*/

module stampIdentity 'br:osdubicep.azurecr.io/public/user-managed-identity:1.0.2' = {
  name: '${commonLayerConfig.name}-user-managed-identity'
  params: {
    resourceName: commonLayerConfig.name
    location: location

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }
  }
}


/*
.___  ___.   ______   .__   __.  __  .___________.  ______   .______       __  .__   __.   _______ 
|   \/   |  /  __  \  |  \ |  | |  | |           | /  __  \  |   _  \     |  | |  \ |  |  /  _____|
|  \  /  | |  |  |  | |   \|  | |  | `---|  |----`|  |  |  | |  |_)  |    |  | |   \|  | |  |  __  
|  |\/|  | |  |  |  | |  . `  | |  |     |  |     |  |  |  | |      /     |  | |  . `  | |  | |_ | 
|  |  |  | |  `--'  | |  |\   | |  |     |  |     |  `--'  | |  |\  \----.|  | |  |\   | |  |__| | 
|__|  |__|  \______/  |__| \__| |__|     |__|      \______/  | _| `._____||__| |__| \__|  \______|                                                                                                    
*/

module logAnalytics 'br:osdubicep.azurecr.io/public/log-analytics:1.0.4' = {
  name: '${commonLayerConfig.name}-log-analytics'
  params: {
    resourceName: commonLayerConfig.name
    location: location

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    // Configure Service
    sku: commonLayerConfig.logs.sku
    retentionInDays: commonLayerConfig.logs.retention
    solutions: [
      {
        name: 'ContainerInsights'
        product: 'OMSGallery/ContainerInsights'
        publisher: 'Microsoft'
        promotionCode: ''
      }  
    ]
  }
  // This dependency is only added to attempt to solve a timing issue.
  // Identities sometimes list as completed but can't be used yet.
  dependsOn: [
    stampIdentity
  ]
}

/*
.__   __.  _______ .___________.____    __    ____  ______   .______       __  ___ 
|  \ |  | |   ____||           |\   \  /  \  /   / /  __  \  |   _  \     |  |/  / 
|   \|  | |  |__   `---|  |----` \   \/    \/   / |  |  |  | |  |_)  |    |  '  /  
|  . `  | |   __|      |  |       \            /  |  |  |  | |      /     |    <   
|  |\   | |  |____     |  |        \    /\    /   |  `--'  | |  |\  \----.|  .  \  
|__| \__| |_______|    |__|         \__/  \__/     \______/  | _| `._____||__|\__\ 
*/

var vnetId = {
  new: virtualNetworkNewOrExisting == 'new' ? network.outputs.id : null
  existing: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
}

var subnetId = '${vnetId[virtualNetworkNewOrExisting]}/subnets/${subnetName}'
  
module network 'br:osdubicep.azurecr.io/public/virtual-network:1.0.5' = if (virtualNetworkNewOrExisting == 'new') {
  name: '${commonLayerConfig.name}-virtual-network'
  params: {
    resourceName: virtualNetworkName
    location: location

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Service
    addressPrefixes: [
      virtualNetworkAddressPrefix
    ]
    subnets: [
      {
        name: subnetName
        addressPrefix: subnetAddressPrefix
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        serviceEndpoints: [
          {
            service: 'Microsoft.Storage'
          }
          {
            service: 'Microsoft.KeyVault'
          }
          {
            service: 'Microsoft.ContainerRegistry'
          }
        ]
      }
    ]

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalIds: [
          stampIdentity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}


/*
 __  ___  ___________    ____ ____    ____  ___      __    __   __      .___________.
|  |/  / |   ____\   \  /   / \   \  /   / /   \    |  |  |  | |  |     |           |
|  '  /  |  |__   \   \/   /   \   \/   / /  ^  \   |  |  |  | |  |     `---|  |----`
|    <   |   __|   \_    _/     \      / /  /_\  \  |  |  |  | |  |         |  |     
|  .  \  |  |____    |  |        \    / /  _____  \ |  `--'  | |  `----.    |  |     
|__|\__\ |_______|   |__|         \__/ /__/     \__\ \______/  |_______|    |__|                                                                     
*/

module keyvault 'br:osdubicep.azurecr.io/public/azure-keyvault:1.0.3' = {
  name: '${commonLayerConfig.name}-azure-keyvault'
  params: {
    resourceName: commonLayerConfig.name
    location: location
    
    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Access
    accessPolicies: [
      {
        principalId: stampIdentity.outputs.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]

    // Configure Secrets
    secretsObject: { secrets: [
      // Misc Secrets
      {
        secretName: commonLayerConfig.secrets.tenantId
        secretValue: subscription().tenantId
      }
      {
        secretName: commonLayerConfig.secrets.subscriptionId
        secretValue: subscription().subscriptionId
      }
      // Registry Secrets
      {
        secretName: commonLayerConfig.secrets.registryName
        secretValue: registry.outputs.name
      }
      // Azure AD Secrets
      {
        secretName: commonLayerConfig.secrets.clientId
        secretValue: applicationClientId
      }
      {
        secretName: commonLayerConfig.secrets.applicationPrincipalId
        secretValue: applicationClientId
      }
      // Managed Identity
      {
        secretName: commonLayerConfig.secrets.stampIdentity
        secretValue: stampIdentity.outputs.principalId
      }
    ]}

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          stampIdentity.outputs.principalId
          applicationClientId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module keyvaultSecrets './modules_private/keyvault_secrets.bicep' = {
  name: '${commonLayerConfig.name}-log-analytics-secrets'
  params: {
    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    workspaceName: logAnalytics.outputs.name
    workspaceIdName: commonLayerConfig.secrets.logAnalyticsId
    workspaceKeySecretName: commonLayerConfig.secrets.logAnalyticsKey
  }
}


var vaultDNSZoneName = 'privatelink.vaultcore.azure.net'

resource vaultDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: vaultDNSZoneName
  location: 'global'
  properties: {}
}

module vaultEndpoint 'br:osdubicep.azurecr.io/public/private-endpoint:1.0.1' = if (enablePrivateLink) {
  name: '${commonLayerConfig.name}-azure-keyvault-endpoint'
  params: {
    resourceName: keyvault.outputs.name
    subnetResourceId: network.outputs.subnetIds[0]
    serviceResourceId: keyvault.outputs.id
    groupIds: [ 'vault']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [vaultDNSZone.id]
    }
  }
}




/*
.______       _______   _______  __       _______.___________..______     ____    ____ 
|   _  \     |   ____| /  _____||  |     /       |           ||   _  \    \   \  /   / 
|  |_)  |    |  |__   |  |  __  |  |    |   (----`---|  |----`|  |_)  |    \   \/   /  
|      /     |   __|  |  | |_ | |  |     \   \       |  |     |      /      \_    _/   
|  |\  \----.|  |____ |  |__| | |  | .----)   |      |  |     |  |\  \----.   |  |     
| _| `._____||_______| \______| |__| |_______/       |__|     | _| `._____|   |__|                                                                                                                              
*/

module registry 'br:osdubicep.azurecr.io/public/container-registry:1.0.2' = {
  name: '${commonLayerConfig.name}-container-registry'
  params: {
    resourceName: commonLayerConfig.name
    location: location

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Service
    sku: commonLayerConfig.registry.sku

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'ACR Pull'
        principalIds: [
          stampIdentity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Import Images
module acrImport 'modules_private/acr_import.bicep' = if (!empty(serviceLayerConfig.imageNames)) {
  name: 'imageImport'
  params: {
    acrName: registry.outputs.name
    location: location
    images: serviceLayerConfig.imageNames
  }
}

/*
     _______.___________.  ______   .______          ___       _______  _______ 
    /       |           | /  __  \  |   _  \        /   \     /  _____||   ____|
   |   (----`---|  |----`|  |  |  | |  |_)  |      /  ^  \   |  |  __  |  |__   
    \   \       |  |     |  |  |  | |      /      /  /_\  \  |  | |_ | |   __|  
.----)   |      |  |     |  `--'  | |  |\  \----./  _____  \ |  |__| | |  |____ 
|_______/       |__|      \______/  | _| `._____/__/     \__\ \______| |_______|                                                                 
*/

module configStorage 'br:osdubicep.azurecr.io/public/storage-account:1.0.5' = {
  name: '${commonLayerConfig.name}-azure-storage'
  params: {
    resourceName: commonLayerConfig.name
    location: location

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Service
    sku: commonLayerConfig.storage.sku
    tables: commonLayerConfig.storage.tables

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalIds: [
          stampIdentity.outputs.principalId
          applicationClientId
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Hookup Customer Managed Encryption Key
    cmekConfiguration: cmekConfiguration

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    storageAccountSecretName: commonLayerConfig.secrets.storageAccountName
    storageAccountKeySecretName: commonLayerConfig.secrets.storageAccountKey
  }
}

var storageDNSZoneForwarder = 'blob.${environment().suffixes.storage}'
var storageDnsZoneName = 'privatelink.${storageDNSZoneForwarder}'

resource storageDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: storageDnsZoneName
  location: 'global'
  properties: {}
}

module storageEndpoint 'br:osdubicep.azurecr.io/public/private-endpoint:1.0.1' = if (enablePrivateLink) {
  name: '${commonLayerConfig.name}-azure-storage-endpoint'
  params: {
    resourceName: configStorage.outputs.name
    subnetResourceId: network.outputs.subnetIds[0]
    serviceResourceId: configStorage.outputs.id
    groupIds: [ 'blob']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [storageDNSZone.id]
    }
  }
}


/*
  _______ .______          ___      .______    __    __  
 /  _____||   _  \        /   \     |   _  \  |  |  |  | 
|  |  __  |  |_)  |      /  ^  \    |  |_)  | |  |__|  | 
|  | |_ | |      /      /  /_\  \   |   ___/  |   __   | 
|  |__| | |  |\  \----./  _____  \  |  |      |  |  |  | 
 \______| | _| `._____/__/     \__\ | _|      |__|  |__| 
*/

module database 'br:osdubicep.azurecr.io/public/cosmos-db:1.0.15' = {
  name: '${commonLayerConfig.name}-cosmos-db'
  params: {
    resourceName: commonLayerConfig.name
    resourceLocation: location

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Service
    capabilitiesToAdd: [
      'EnableGremlin'
    ]
    gremlinDatabases: [
      {
        name: commonLayerConfig.database.name
        graphs: commonLayerConfig.database.graphs
      }
    ]
    throughput: commonLayerConfig.database.throughput
    backupPolicyType: commonLayerConfig.database.backup

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalIds: [
          stampIdentity.outputs.principalId
          applicationClientId
        ]
        principalType: 'ServicePrincipal'
        delegatedManagedIdentityResourceId: stampIdentity.outputs.id
      }
    ]

    // Hookup Customer Managed Encryption Key
    systemAssignedIdentity: false
    userAssignedIdentities: !empty(cmekConfiguration.identityId) ? {
      '${stampIdentity.outputs.id}': {}
      '${cmekConfiguration.identityId}': {}
    } : {
      '${stampIdentity.outputs.id}': {}
    }
    defaultIdentity: !empty(cmekConfiguration.identityId) ? cmekConfiguration.identityId : ''
    kvKeyUri: !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) ? '${cmekConfiguration.kvUrl}/keys/${cmekConfiguration.keyName}' : ''

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    databaseEndpointSecretName: commonLayerConfig.secrets.cosmosEndpoint
    databasePrimaryKeySecretName: commonLayerConfig.secrets.cosmosPrimaryKey
    databaseConnectionStringSecretName: commonLayerConfig.secrets.cosmosConnectionString

    // Cross Tenant
    crossTenant: crossTenant
  }
}

var cosmosDnsZoneName = 'privatelink.documents.azure.com'

resource cosmosDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: cosmosDnsZoneName
  location: 'global'
  properties: {}
}

module graphEndpoint 'br:osdubicep.azurecr.io/public/private-endpoint:1.0.1' = if (enablePrivateLink) {
  name: '${commonLayerConfig.name}-cosmos-db-endpoint'
  params: {
    resourceName: database.outputs.name
    subnetResourceId: network.outputs.subnetIds[0]
    serviceResourceId: database.outputs.id
    groupIds: [ 'sql']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [cosmosDNSZone.id]
    }
  }
}


// /*
// .______      ___      .______     .___________. __  .___________. __    ______   .__   __.      _______.
// |   _  \    /   \     |   _  \    |           ||  | |           ||  |  /  __  \  |  \ |  |     /       |
// |  |_)  |  /  ^  \    |  |_)  |   `---|  |----`|  | `---|  |----`|  | |  |  |  | |   \|  |    |   (----`
// |   ___/  /  /_\  \   |      /        |  |     |  |     |  |     |  | |  |  |  | |  . `  |     \   \    
// |  |     /  _____  \  |  |\  \----.   |  |     |  |     |  |     |  | |  `--'  | |  |\   | .----)   |   
// | _|    /__/     \__\ | _| `._____|   |__|     |__|     |__|     |__|  \______/  |__| \__| |_______/                                 
// */

module partitionStorage 'br:osdubicep.azurecr.io/public/storage-account:1.0.5' = [for (partition, index) in partitions: {
  name: '${partitionLayerConfig.name}-azure-storage-${index}'
  params: {
    resourceName: 'data${index}${uniqueString(partition.name)}'
    location: location

    // Assign Tags
    tags: {
      layer: partitionLayerConfig.displayName
      partition: partition.name
      purpose: 'data'
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Service
    sku: partitionLayerConfig.storage.sku
    containers: concat(partitionLayerConfig.storage.containers, [partition.name])

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalIds: [
          stampIdentity.outputs.principalId
          applicationClientId
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Hookup Customer Managed Encryption Key
    cmekConfiguration: cmekConfiguration

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    storageAccountSecretName: '${partition.name}-${partitionLayerConfig.secrets.storageAccountName}'
    storageAccountKeySecretName: '${partition.name}-${partitionLayerConfig.secrets.storageAccountKey}'
  }
}]

module partitionStorageEndpoint 'br:osdubicep.azurecr.io/public/private-endpoint:1.0.1' = [for (partition, index) in partitions: if (enablePrivateLink) {
  name: '${partitionLayerConfig.name}-azure-storage-endpoint-${index}'
  params: {
    resourceName: partitionStorage[index].outputs.name
    subnetResourceId: network.outputs.subnetIds[0]
    serviceResourceId: partitionStorage[index].outputs.id
    groupIds: [ 'blob']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [storageDNSZone.id]
    }
  }
}]

module partitionDb 'br:osdubicep.azurecr.io/public/cosmos-db:1.0.15' = [for (partition, index) in partitions: {
  name: '${partitionLayerConfig.name}-cosmos-db-${index}'
  params: {
    resourceName: 'data${index}${substring(uniqueString(partition.name), 0, 6)}'
    resourceLocation: location

    // Assign Tags
    tags: {
      layer: partitionLayerConfig.displayName
      partition: partition.name
      purpose: 'data'
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Service
    sqlDatabases: [
      {
        name: partitionLayerConfig.database.name
        containers: partitionLayerConfig.database.containers
      }
    ]
    maxThroughput: partitionLayerConfig.database[clusterSize].throughput
    backupPolicyType: partitionLayerConfig.database.backup

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalIds: [
          stampIdentity.outputs.principalId
          applicationClientId
        ]
        principalType: 'ServicePrincipal'
        delegatedManagedIdentityResourceId: stampIdentity.outputs.id
      }
    ]

    // Hookup Customer Managed Encryption Key
    systemAssignedIdentity: false
    userAssignedIdentities: !empty(cmekConfiguration.identityId) ? {
      '${stampIdentity.outputs.id}': {}
      '${cmekConfiguration.identityId}': {}
    } : {
      '${stampIdentity.outputs.id}': {}
    }
    defaultIdentity: !empty(cmekConfiguration.identityId) ? cmekConfiguration.identityId : ''
    kvKeyUri: !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) ? '${cmekConfiguration.kvUrl}/keys/${cmekConfiguration.keyName}' : ''

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    databaseEndpointSecretName: '${partition.name}-${partitionLayerConfig.secrets.cosmosEndpoint}'
    databasePrimaryKeySecretName: '${partition.name}-${partitionLayerConfig.secrets.cosmosPrimaryKey}'
    databaseConnectionStringSecretName: '${partition.name}-${partitionLayerConfig.secrets.cosmosConnectionString}'

    // Cross Tenant
    crossTenant: crossTenant
  }
}]

module partitionDbEndpoint 'br:osdubicep.azurecr.io/public/private-endpoint:1.0.1' = [for (partition, index) in partitions: if (enablePrivateLink) {
  name: '${partitionLayerConfig.name}-cosmos-db-endpoint-${index}'
  params: {
    resourceName: partitionDb[index].outputs.name
    subnetResourceId: network.outputs.subnetIds[0]
    serviceResourceId: partitionDb[index].outputs.id
    groupIds: [ 'sql']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [cosmosDNSZone.id]
    }
  }
}]



/*
 __  ___  __    __  .______    _______ .______      .__   __.  _______ .___________. _______     _______.
|  |/  / |  |  |  | |   _  \  |   ____||   _  \     |  \ |  | |   ____||           ||   ____|   /       |
|  '  /  |  |  |  | |  |_)  | |  |__   |  |_)  |    |   \|  | |  |__   `---|  |----`|  |__     |   (----`
|    <   |  |  |  | |   _  <  |   __|  |      /     |  . `  | |   __|      |  |     |   __|     \   \    
|  .  \  |  `--'  | |  |_)  | |  |____ |  |\  \----.|  |\   | |  |____     |  |     |  |____.----)   |   
|__|\__\  \______/  |______/  |_______|| _| `._____||__| \__| |_______|    |__|     |_______|_______/    
*/

module cluster 'modules_private/aks_cluster.bicep' = {
  name: '${serviceLayerConfig.name}-cluster'
  params: {
    // Basic Details
    resourceName: serviceLayerConfig.name
    location: location

    // Assign Tags
    tags: {
      layer: serviceLayerConfig.displayName
    }

    aad_tenant_id: subscription().tenantId

    // Configure Linking Items
    subnetId: virtualNetworkNewOrExisting != 'new' ? subnetId : subnetId 
    identityId: stampIdentity.outputs.id
    workspaceId: logAnalytics.outputs.id

    // Configure NodePools
    ClusterSize: clusterSize

    // Configure Add Ons
    enable_aad: empty(clusterAdminIds) == true ? false : true
    admin_ids: clusterAdminIds
    workloadIdentityEnabled: true
    keyvaultEnabled: true
    fluxGitOpsAddon:true
  }
}

@description('Elastic User Pool presets')
var elasticPoolPresets = {
  // 2 vCPU, 4 GiB RAM, 8 GiB Temp Disk, (1600) IOPS, 128 GB Managed OS Disk
  CostOptimised : {
    vmSize: 'Standard_DS3_v2'
  }
  // 2 vCPU, 8 GiB RAM, 16GiB Temp Disk (4000) IOPS, 128 GB Managed OS Disk
  Standard : {
    vmSize: 'Standard_DS3_v2'
  }
  // 4 vCPU, 16 GiB RAM, 32 GiB SSD, (8000) IOPS, 128 GB Managed OS Disk
  HighSpec : {
    vmSize: 'Standard_DS3_v2'
  }
}

module espool1 'modules_private/aks_agent_pool.bicep' = {
  name: '${serviceLayerConfig.name}-espool1'
  params: {
    AksName: cluster.outputs.aksClusterName
    PoolName: 'espoolz1'
    agentVMSize: elasticPoolPresets[clusterSize].vmSize
    agentCount: 2
    agentCountMax: 4
    availabilityZones: [
      '1'
    ]
    subnetId: ''
    nodeTaints: ['app=elasticsearch:NoSchedule']
    nodeLabels: {
      app: 'elasticsearch'
    }
  }
}

module espool2 'modules_private/aks_agent_pool.bicep' = {
  name: '${serviceLayerConfig.name}-espool2'
  params: {
    AksName: cluster.outputs.aksClusterName
    PoolName: 'espoolz2'
    agentVMSize: elasticPoolPresets[clusterSize].vmSize
    agentCount: 2
    agentCountMax: 4
    availabilityZones: [
      '2'
    ]
    subnetId: ''
    nodeTaints: ['app=elasticsearch:NoSchedule']
    nodeLabels: {
      app: 'elasticsearch'
    }
  }
}

module espool3 'modules_private/aks_agent_pool.bicep' = {
  name: '${serviceLayerConfig.name}-espool3'
  params: {
    AksName: cluster.outputs.aksClusterName
    PoolName: 'espoolz3'
    agentVMSize: elasticPoolPresets[clusterSize].vmSize
    agentCount: 2
    agentCountMax: 4
    availabilityZones: [
      '3'
    ]
    subnetId: ''
    nodeTaints: ['app=elasticsearch:NoSchedule']
    nodeLabels: {
      app: 'elasticsearch'
    }
  }
}


//--------------Flux Config---------------
module flux 'modules_private/flux_config.bicep' = if (enableSoftwareLoad) {
  name: '${serviceLayerConfig.name}-cluster-gitops'
  params: {
    aksName: cluster.outputs.name
    aksFluxAddOnReleaseNamespace: cluster.outputs.fluxReleaseNamespace
    fluxConfigName: serviceLayerConfig.gitops.name
    fluxConfigRepo: serviceLayerConfig.gitops.url
    fluxRepoComponentsPath: serviceLayerConfig.gitops.components
    fluxRepoApplicationssPath: serviceLayerConfig.gitops.applications
    fluxConfigRepoBranch: serviceLayerConfig.gitops.branch
  }
  dependsOn: [
    cluster
    espool1
    espool2
    espool3
  ]
}
