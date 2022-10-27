/*
  This is the main bicep entry file.

  10.20.22: Updated
--------------------------------
  - Establishing the Pipelines
  - Added an Identity
*/

@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

@description('Used to name all resources')
var controlPlane  = 'ctlplane'


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

module logAnalytics 'br:osdubicep.azurecr.io/public/log-analytics:1.0.2' = {
  name: '${controlPlane}-log-analytics'
  params: {
    resourceName: controlPlane
    location: location
    // tags: {
    //   layer: 'Control Plane'
    // }
    sku: 'PerGB2018'
    retentionInDays: 30
  }
  // This dependency is only added to attempt to solve a timing issue.
  // Identities sometimes list as completed but can't be used yet.
  dependsOn: [
    clusterIdentity
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

var vnetId = {
  new: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
  existing: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
}

var subnetId = '${vnetId[virtualNetworkNewOrExisting]}/subnets/${subnetName}'

// Create Virtual Network (If Not BYO)
module network 'br:osdubicep.azurecr.io/public/virtual-network:1.0.4' = if (virtualNetworkNewOrExisting == 'new') {
  name: '${controlPlane}-virtual-network'
  params: {
    resourceName: virtualNetworkName
    location: location
    tags: {
      layer: 'Control Plane'
    }
    diagnosticWorkspaceId: logAnalytics.outputs.id
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
  dependsOn: [
    clusterIdentity
    logAnalytics
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

module keyvault 'br:osdubicep.azurecr.io/public/azure-keyvault:1.0.2' = {
  name: '${controlPlane}-azure-keyvault'
  params: {
    resourceName: controlPlane
    location: location
    tags: {
      layer: 'Control Plane'
    }
    secretsObject: { secrets: []}
    diagnosticWorkspaceId: logAnalytics.outputs.id
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
    ]
    privateLinkSettings:{
      vnetId: network.outputs.id
      subnetId: network.outputs.subnetIds[0]
    }
  }
  dependsOn: [
    clusterIdentity
    logAnalytics
    network
  ]
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
    tags: {
      layer: 'Control Plane'
    }
    sku: 'Premium'
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'ACR Pull'
        principalIds: [
          clusterIdentity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
    privateLinkSettings:{
      vnetId: network.outputs.id
      subnetId: network.outputs.subnetIds[0]
    }
  }
  dependsOn: [
    clusterIdentity
    logAnalytics
    network
  ]
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
module stgModule 'br:osdubicep.azurecr.io/public/storage-account:1.0.2' = {
  name: 'azure_storage'
  params: {
    resourceName: controlPlane
    location: location
    tags: {
      layer: 'Control Plane'
    }
    sku: storageAccountType
    tables: [
      'config'
    ]
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Storage Table Data Reader'
        principalIds: [
          clusterIdentity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
    diagnosticWorkspaceId: logAnalytics.outputs.id
    privateLinkSettings:{
      vnetId: network.outputs.id
      subnetId: network.outputs.subnetIds[0]
    }
  }
}
