/*
  This is the main bicep entry file.

  10.20.22: Updated
--------------------------------
  - Establishing the Pipelines
  - Added an Identity
*/

@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

@description('Specify the AD Application Object Id.')
param applicationId string

@description('Specify the AD Application Client Id.')
param applicationClientId string

@description('Specify the AD Application Client Secret.')
@secure()
param applicationClientSecret string

@description('Used to name all resources')
var controlPlane  = 'ctlplane'

@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}


/*
 __   _______   _______ .__   __. .___________. __  .___________.____    ____ 
|  | |       \ |   ____||  \ |  | |           ||  | |           |\   \  /   / 
|  | |  .--.  ||  |__   |   \|  | `---|  |----`|  | `---|  |----` \   \/   /  
|  | |  |  |  ||   __|  |  . `  |     |  |     |  |     |  |       \_    _/   
|  | |  '--'  ||  |____ |  |\   |     |  |     |  |     |  |         |  |     
|__| |_______/ |_______||__| \__|     |__|     |__|     |__|         |__|     
*/

// Create a Managed User Identity for the Cluster
module clusterIdentity 'br:osdubicep.azurecr.io/public/user-managed-identity:1.0.1' = {
  name: '${controlPlane}-user-managed-identity'
  params: {
    resourceName: controlPlane
    location: location

    // Assign Tags
    tags: {
      layer: 'Control Plane'
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
  name: '${controlPlane}-log-analytics'
  params: {
    resourceName: controlPlane
    location: location

    // Assign Tags
    tags: {
      layer: 'Control Plane'
    }

    // Configure Service
    sku: 'PerGB2018'
    retentionInDays: 30
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
    clusterIdentity
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

module keyvault './modules/public/azure-keyvault/main.bicep' = {
  name: '${controlPlane}-azure-keyvault'
  params: {
    resourceName: controlPlane
    location: location
    
    // Assign Tags
    tags: {
      layer: 'Control Plane'
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Access
    accessPolicies: [
      {
        principalId: clusterIdentity.outputs.principalId
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
        secretName: 'tenant-id'
        secretValue: subscription().tenantId
      }
      {
        secretName: 'subscription-id'
        secretValue: subscription().subscriptionId
      }
      // Registry Secrets
      {
        secretName: 'container-registry'
        secretValue: registry.outputs.name
      }
      // Azure AD Secrets
      {
        secretName: 'aad-client-id'
        secretValue: applicationId
      }
      {
        secretName: 'app-dev-sp-username'
        secretValue: applicationClientId
      }
      {
        secretName: 'app-dev-sp-password'
        secretValue: applicationClientSecret
      }
      {
        secretName: 'app-dev-sp-id'
        secretValue: applicationClientId
      }
      // Managed Identity
      {
        secretName: 'osdu-identity-id'
        secretValue: clusterIdentity.outputs.principalId
      }
    ]}

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          clusterIdentity.outputs.principalId
          applicationClientId
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Hookup Private Links
    privateLinkSettings: privateLinkSettings
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
  


// Create Virtual Network (If Not BYO)
module network 'br:osdubicep.azurecr.io/public/virtual-network:1.0.4' = if (virtualNetworkNewOrExisting == 'new') {
  name: '${controlPlane}-virtual-network'
  params: {
    resourceName: virtualNetworkName
    location: location

    // Assign Tags
    tags: {
      layer: 'Control Plane'
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
          clusterIdentity.outputs.principalId
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
  name: '${controlPlane}-container-registry'
  params: {
    resourceName: controlPlane
    location: location

    // Assign Tags
    tags: {
      layer: 'Control Plane'
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Service
    sku: 'Premium'

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'ACR Pull'
        principalIds: [
          clusterIdentity.outputs.principalId
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
var storageAccountType = 'Standard_LRS'

// Create Storage Account
module configStorage 'br:osdubicep.azurecr.io/public/storage-account:1.0.5' = {
  name: '${controlPlane}-azure-storage'
  params: {
    resourceName: controlPlane
    location: location

    // Assign Tags
    tags: {
      layer: 'Control Plane'
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Service
    sku: storageAccountType
    tables: [
      'PartitionInfo'
    ]

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalIds: [
          clusterIdentity.outputs.principalId
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
    storageAccountSecretName: 'tbl-storage'
    storageAccountKeySecretName: 'tbl-storage-key'
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

module database 'br:osdubicep.azurecr.io/public/cosmos-db:1.0.4' = {
  name: '${controlPlane}-cosmos-db'
  params: {
    resourceName: controlPlane
    resourceLocation: location

    // Assign Tags
    tags: {
      layer: 'Control Plane'
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.id

    // Configure Service
    capabilitiesToAdd: [
      'EnableGremlin'
    ]
    gremlinDatabases: [
      {
        name: 'osdu-graph'
        graphs: [
          {
            automaticIndexing: true
            name: 'Entitlements'
            partitionKeyPaths: [
              '/dataPartitionId'
            ]
          }
        ]
      }
    ]

    // Hook up Multiple Region Write (can't be used with Continous Backup)
    backupPolicyType: 'Continuous'

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalIds: [
          clusterIdentity.outputs.principalId
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
      '${clusterIdentity.outputs.id}': {}
      '${cmekConfiguration.identityId}': {}
    } : {
      '${clusterIdentity.outputs.id}': {}
    }
    defaultIdentity: !empty(cmekConfiguration.identityId) ? cmekConfiguration.identityId : ''
    kvKeyUri: !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) ? '${cmekConfiguration.kvUrl}/${cmekConfiguration.keyName}' : ''

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    databaseEndpointSecretName: 'graph-db-endpoint'
    databasePrimaryKeySecretName: 'graph-db-primary-key'
    databaseConnectionStringSecretName: 'graph-db-connection'
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
