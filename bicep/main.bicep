/*
  This is the main bicep entry file.

  11.8.22: Common Resources
--------------------------------
  - Established the Common Resources
*/

@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

/////////////////
// Identity Blade 
/////////////////
@description('Specify the AD Application Object Id.')
param applicationId string

@description('Specify the AD Application Client Id.')
param applicationClientId string

@description('Specify the AD Application Client Secret.')
@secure()
param applicationClientSecret string


/////////////////
// Network Blade 
/////////////////
@description('Name of the Virtual Network')
param virtualNetworkName string = 'ctlplane'

@description('Boolean indicating whether the VNet is new or existing')
param virtualNetworkNewOrExisting string = 'new'

@description('VNet address prefix')
param virtualNetworkAddressPrefix string = '10.1.0.0/16'

@description('Resource group of the VNet')
param virtualNetworkResourceGroup string = ''

@description('New or Existing subnet Name')
param subnetName string = 'NodeSubnet'

@description('Subnet address prefix')
param subnetAddressPrefix string = '10.1.0.0/24'

@description('Feature Flag on Private Link')
param enablePrivateLink bool = false


/////////////////
// Security Blade 
/////////////////
@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}


/////////////////////////////////
// Common Resources Configuration 
/////////////////////////////////
var commonLayerConfig = {
  name: 'commonresources'
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
      {
        principalId: applicationId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
            'update'
            'import'
          ]
          keys: [
            'get'
            'encrypt'
            'decrypt'
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
        secretName: commonLayerConfig.secrets.applicationId
        secretValue: applicationId
      }
      {
        secretName: commonLayerConfig.secrets.clientId
        secretValue: applicationClientId
      }
      {
        secretName: commonLayerConfig.secrets.clientSecret
        secretValue: applicationClientSecret
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

    // Hookup Private Links
    privateLinkSettings: privateLinkSettings
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


/*
.__   __.  _______ .___________.____    __    ____  ______   .______       __  ___ 
|  \ |  | |   ____||           |\   \  /  \  /   / /  __  \  |   _  \     |  |/  / 
|   \|  | |  |__   `---|  |----` \   \/    \/   / |  |  |  | |  |_)  |    |  '  /  
|  . `  | |   __|      |  |       \            /  |  |  |  | |      /     |    <   
|  |\   | |  |____     |  |        \    /\    /   |  `--'  | |  |\  \----.|  .  \  
|__| \__| |_______|    |__|         \__/  \__/     \______/  | _| `._____||__|\__\ 
*/

var vnetId = {
  new: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
  existing: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
}

var subnetId = '${vnetId[virtualNetworkNewOrExisting]}/subnets/${subnetName}'

var privateLinkSettings = enablePrivateLink ? {
  vnetId: vnetId
  subnetId: subnetId
} : {
  subnetId: '1' // 1 is don't use.
  vnetId: '1'  // 1 is don't use.
}
  
module network 'br:osdubicep.azurecr.io/public/virtual-network:1.0.4' = if (virtualNetworkNewOrExisting == 'new') {
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

    // Hook up Private Links
    privateLinkSettings: privateLinkSettings
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

// Create Storage Account
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

    // Hookup Private Links
    privateLinkSettings: privateLinkSettings

    // Hookup Customer Managed Encryption Key
    cmekConfiguration: cmekConfiguration

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    storageAccountSecretName: commonLayerConfig.secrets.storageAccountName
    storageAccountKeySecretName: commonLayerConfig.secrets.storageAccountKey
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

module database 'br:osdubicep.azurecr.io/public/cosmos-db:1.0.5' = {
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
      }
    ]

    // Hookup Private Links
    privateLinkSettings: privateLinkSettings

    // Hookup Customer Managed Encryption Key
    systemAssignedIdentity: false
    userAssignedIdentities: !empty(cmekConfiguration.identityId) ? {
      '${stampIdentity.outputs.id}': {}
      '${cmekConfiguration.identityId}': {}
    } : {
      '${stampIdentity.outputs.id}': {}
    }
    defaultIdentity: !empty(cmekConfiguration.identityId) ? cmekConfiguration.identityId : ''
    kvKeyUri: !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) ? '${cmekConfiguration.kvUrl}/${cmekConfiguration.keyName}' : ''

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    databaseEndpointSecretName: commonLayerConfig.secrets.cosmosEndpoint
    databasePrimaryKeySecretName: commonLayerConfig.secrets.cosmosPrimaryKey
    databaseConnectionStringSecretName: commonLayerConfig.secrets.cosmosConnectionString
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
