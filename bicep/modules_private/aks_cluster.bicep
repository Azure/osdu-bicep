/*
  This is a custom module that configures Azure Kubernetes Service.

  ** Eventually this might move to Managed-Platform-Modules. **
*/

targetScope = 'resourceGroup'

/*______      ___      .______          ___      .___  ___.  _______ .___________. _______ .______          _______.
|   _  \    /   \     |   _  \        /   \     |   \/   | |   ____||           ||   ____||   _  \        /       |
|  |_)  |  /  ^  \    |  |_)  |      /  ^  \    |  \  /  | |  |__   `---|  |----`|  |__   |  |_)  |      |   (----`
|   ___/  /  /_\  \   |      /      /  /_\  \   |  |\/|  | |   __|      |  |     |   __|  |      /        \   \    
|  |     /  _____  \  |  |\  \----./  _____  \  |  |  |  | |  |____     |  |     |  |____ |  |\  \----.----)   |   
| _|    /__/     \__\ | _| `._____/__/     \__\ |__|  |__| |_______|    |__|     |_______|| _| `._____|_______/    
*/
                                                                                                                   
////////////////////
// Basic Details
////////////////////
@minLength(1)
@maxLength(63)
@description('Used to name all resources')
param resourceName string

@description('Specify the location of the AKS cluster.')
param location string = resourceGroup().location

@description('Tags.')
param tags object = {}

@description('The ID of the Azure AD tenant')
param aad_tenant_id string = ''

@description('Specifies the tier of a managed cluster SKU: Paid or Free')
@allowed([
  'Paid'
  'Free'
])
param skuTier string = 'Free'

@description('Specifies the version of Kubernetes specified when creating the managed cluster.')
param version string = '1.24.3'

@description('Specifies the upgrade channel for auto upgrade. Allowed values include rapid, stable, patch, node-image, none.')
@allowed([
  'rapid'
  'stable'
  'patch'
  'node-image'
  'none'
])
param aksUpgradeChannel string = 'stable'


////////////////////
// Compute Configuration
////////////////////
@allowed([
  'CostOptimised'
  'Standard'
  'HighSpec'
  'Custom'
])
@description('The System Pool Preset sizing')
param ClusterSize string = 'CostOptimised'


@description('The System Pool Preset sizing')
param AutoscaleProfile object = {
  'balance-similar-node-groups': 'true'
  expander: 'random'
  'max-empty-bulk-delete': '10'
  'max-graceful-termination-sec': '600'
  'max-node-provision-time': '15m'
  'max-total-unready-percentage': '45'
  'new-pod-scale-up-delay': '0s'
  'ok-total-unready-count': '3'
  'scale-down-delay-after-add': '10m'
  'scale-down-delay-after-delete': '20s'
  'scale-down-delay-after-failure': '3m'
  'scale-down-unneeded-time': '10m'
  'scale-down-unready-time': '20m'
  'scale-down-utilization-threshold': '0.5'
  'scan-interval': '10s'
  'skip-nodes-with-local-storage': 'true'
  'skip-nodes-with-system-pods': 'true'
}


////////////////////
// Required Items to link to other resources
////////////////////

@description('Specify the Log Analytics Workspace Id to use for monitoring.')
param workspaceId string

@description('Specify the User Managed Identity Resource Id.')
param identityId string

@description('Specify the cluster nodes subnet.')
param subnetId string


////////////////////
// Network Configuration
////////////////////

@allowed([
  'azure'
  'kubenet'
])
@description('The network plugin type')
param networkPlugin string = 'azure'

@allowed([
  ''
  'Overlay'
])
@description('The network plugin type')
param networkPluginMode string = ''

@allowed([
  ''
  'azure'
  'calico'
])
@description('The network policy to use.')
param networkPolicy string = ''

@minLength(9)
@maxLength(18)
@description('The address range to use for pods')
param podCidr string = '10.240.100.0/22'

@description('Allocate pod ips dynamically')
param cniDynamicIpAllocation bool = false

@minLength(9)
@maxLength(18)
@description('The address range to use for services')
param serviceCidr string = '172.10.0.0/16'

@minLength(7)
@maxLength(15)
@description('The IP address to reserve for DNS')
param dnsServiceIP string = '172.10.0.10'

@minLength(9)
@maxLength(18)
@description('The address range to use for the docker bridge')
param dockerBridgeCidr string = '172.17.0.1/16'

@allowed([
  'loadBalancer'
  'managedNATGateway'
  'userAssignedNATGateway'
])
@description('Outbound traffic type for the egress traffic of your cluster')
param aksOutboundTrafficType string = 'loadBalancer'

@description('Specifies the DNS prefix specified when creating the managed cluster.')
param dnsPrefix string = 'aks-${resourceGroup().name}'


////////////////////
// Security Settings
////////////////////
@description('Enable private cluster')
param enablePrivateCluster bool = false

@allowed([
  'system'
  'none'
  'privateDnsZone'
])
@description('Private cluster dns advertisment method, leverages the dnsApiPrivateZoneId parameter')
param privateClusterDnsMethod string = 'system'

@description('The full Azure resource ID of the privatelink DNS zone to use for the AKS cluster API Server')
param dnsApiPrivateZoneId string = ''

@description('The IP addresses that are allowed to access the API server')
param authorizedIPRanges array = []

@allowed([
  ''
  'audit'
  'deny'
])
@description('Enable the Azure Policy addon')
param azurepolicy string = ''


////////////////////
// Add Ons
////////////////////
@description('Enables Kubernetes Event-driven Autoscaling (KEDA)')
param kedaEnabled bool = false

@description('Enables Open Service Mesh')
param openServiceMeshEnabled bool = false

@description('Configures the cluster as an OIDC issuer for use with Workload Identity')
param workloadIdentityEnabled bool = false

@description('Configures the cluster to use Azure Defender')
param defenderEnabled bool = false

@description('Installs the AKS KV CSI provider')
param keyvaultEnabled bool = false

@description('Rotation poll interval for the AKS KV CSI provider')
param keyVaultAksCSIPollInterval string = '2m'

@description('Enable Azure AD integration on AKS')
param enable_aad bool = false

@description('Enable RBAC using AAD')
param enableAzureRBAC bool = false




/*__    ____  ___      .______       __       ___      .______    __       _______     _______.
\   \  /   / /   \     |   _  \     |  |     /   \     |   _  \  |  |     |   ____|   /       |
 \   \/   / /  ^  \    |  |_)  |    |  |    /  ^  \    |  |_)  | |  |     |  |__     |   (----`
  \      / /  /_\  \   |      /     |  |   /  /_\  \   |   _  <  |  |     |   __|     \   \    
   \    / /  _____  \  |  |\  \----.|  |  /  _____  \  |  |_)  | |  `----.|  |____.----)   |   
    \__/ /__/     \__\ | _| `._____||__| /__/     \__\ |______/  |_______||_______|_______/    
*/
                                                                                               
@description('The name of the AKS cluster.')
var name = 'aks-${uniqueString(resourceGroup().id, resourceName)}'

@description('Sets the private dns zone id if provided')
var aksPrivateDnsZone = privateClusterDnsMethod=='privateDnsZone' ? (!empty(dnsApiPrivateZoneId) ? dnsApiPrivateZoneId : 'system') : privateClusterDnsMethod
output aksPrivateDnsZone string = aksPrivateDnsZone

@description('System Pool presets are derived from the recommended system pool specs')
var systemPoolPresets = {
  // 4 vCPU, 16 GiB RAM, 32 GiB Temp Disk, (3600) IOPS, 128 GB Managed OS Disk
  CostOptimised : {
    vmSize: 'Standard_B4ms'
    minCount: 1
    maxCount: 3
    availabilityZones: []
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 2 vCPU, 7 GiB RAM, 14 GiB SSD, (8000) IOPS, 128 GB Managed OS Disk
  Standard : {
    vmSize: 'Standard_DS2_v2'
    minCount: 3
    maxCount: 5
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 4 vCPU, 16 GiB RAM, 32 GiB SSD, (8000) IOPS, 128 GB Managed OS Disk
  HighSpec : {
    vmSize: 'Standard_D4s_v3'
    minCount: 3
    maxCount: 10
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
}

var systemPoolProfile = {
  name: 'default'
  mode: 'System'
  osType: 'Linux'
  type: 'VirtualMachineScaleSets'
  osDiskType: systemPoolPresets[ClusterSize].osDiskType
  osDiskSizeGB: systemPoolPresets[ClusterSize].osDiskSize
  vmSize: systemPoolPresets[ClusterSize].vmSize
  count: systemPoolPresets[ClusterSize].minCount
  minCount: systemPoolPresets[ClusterSize].minCount
  maxCount: systemPoolPresets[ClusterSize].maxCount
  availabilityZones: systemPoolPresets[ClusterSize].availabilityZones
  enableAutoScaling: true
  maxPods: systemPoolPresets[ClusterSize].maxPods
  vnetSubnetID: !empty(subnetId) ? subnetId : json('null')
  upgradeSettings: {
    maxSurge: '33%'
  }
  nodeTaints: [
    'CriticalAddonsOnly=true:NoSchedule'
  ]
}


@description('First User Pool presets')
var userPoolPresets = {
  // 4 vCPU, 16 GiB RAM, 32 GiB Temp Disk, (3600) IOPS, 128 GB Managed OS Disk
  CostOptimised : {
    vmSize: 'Standard_B4ms'
    minCount: 1
    maxCount: 3
    availabilityZones: []
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 4 vCPU, 32 GiB RAM, 64 GiB SSD, (8000) IOPS, 128 GB Managed OS Disk
  Standard : {
    vmSize: 'Standard_E4s_v3'
    minCount: 3
    maxCount: 15
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 8 vCPU, 32 GiB RAM, 300 GiB Temp Disk, (77000) IOPS, Ephermial Disk
  HighSpec : {
    vmSize: 'Standard_D8ds_v4'
    minCount: 8
    maxCount: 20
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Ephemeral'
    osDiskSize: 0
    maxPods: 30
  }
}


var userPoolProfile = {
  name: 'internal'
  mode: 'User'
  osType: 'Linux'
  type: 'VirtualMachineScaleSets'
  osDiskType: userPoolPresets[ClusterSize].osDiskType
  osDiskSizeGB: userPoolPresets[ClusterSize].osDiskSize
  vmSize: userPoolPresets[ClusterSize].vmSize
  count: userPoolPresets[ClusterSize].minCount
  minCount: userPoolPresets[ClusterSize].minCount
  maxCount: userPoolPresets[ClusterSize].maxCount
  availabilityZones: userPoolPresets[ClusterSize].availabilityZones
  enableAutoScaling: true
  maxPods: userPoolPresets[ClusterSize].maxPods
  vnetSubnetID: !empty(subnetId) ? subnetId : json('null')
  upgradeSettings: {
    maxSurge: '33%'
  }
}


@description('Second User Pool presets')
var secondPoolPresets = {
  // 2 vCPU, 4 GiB RAM, 8 GiB Temp Disk, (1600) IOPS, 128 GB Managed OS Disk
  CostOptimised : {
    vmSize: 'Standard_B2s'
    minCount: 1
    maxCount: 3
    availabilityZones: []
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 2 vCPU, 8 GiB RAM, 16GiB Temp Disk (4000) IOPS, 128 GB Managed OS Disk
  Standard : {
    vmSize: 'Standard_D2s_v3'
    minCount: 8
    maxCount: 16
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 4 vCPU, 16 GiB RAM, 32 GiB SSD, (8000) IOPS, 128 GB Managed OS Disk
  HighSpec : {
    vmSize: 'Standard_D4s_v3'
    minCount: 3
    maxCount: 5
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 50
  }
}

var secondPoolProfile = {
  name: 'espool'
  mode: 'User'
  osType: 'Linux'
  type: 'VirtualMachineScaleSets'
  osDiskType: secondPoolPresets[ClusterSize].osDiskType
  osDiskSizeGB: secondPoolPresets[ClusterSize].osDiskSize
  vmSize: secondPoolPresets[ClusterSize].vmSize
  count: secondPoolPresets[ClusterSize].minCount
  minCount: secondPoolPresets[ClusterSize].minCount
  maxCount: secondPoolPresets[ClusterSize].maxCount
  availabilityZones: secondPoolPresets[ClusterSize].availabilityZones
  enableAutoScaling: true
  maxPods: secondPoolPresets[ClusterSize].maxPods
  vnetSubnetID: !empty(subnetId) ? subnetId : json('null')
  upgradeSettings: {
    maxSurge: '33%'
  }
}


var agentPoolProfiles = concat(array(systemPoolProfile), array(userPoolProfile), array(secondPoolProfile))

var aks_addons = union({
  azurepolicy: {
    config: {
      version: !empty(azurepolicy) ? 'v2' : json('null')
    }
    enabled: !empty(azurepolicy)
  }
  azureKeyvaultSecretsProvider: {
    config: {
      enableSecretRotation: 'true'
      rotationPollInterval: keyVaultAksCSIPollInterval
    }
    enabled: keyvaultEnabled
  }
  openServiceMesh: {
    enabled: openServiceMeshEnabled
    config: {}
  }
}, !(empty(workspaceId)) ? {
  omsagent: {
    enabled: !(empty(workspaceId))
    config: {
      logAnalyticsWorkspaceResourceID: !(empty(workspaceId)) ? workspaceId : json('null')
    }
  }} : {})



/*
.______       _______     _______.  ______    __    __  .______        ______  _______     _______.
|   _  \     |   ____|   /       | /  __  \  |  |  |  | |   _  \      /      ||   ____|   /       |
|  |_)  |    |  |__     |   (----`|  |  |  | |  |  |  | |  |_)  |    |  ,----'|  |__     |   (----`
|      /     |   __|     \   \    |  |  |  | |  |  |  | |      /     |  |     |   __|     \   \    
|  |\  \----.|  |____.----)   |   |  `--'  | |  `--'  | |  |\  \----.|  `----.|  |____.----)   |   
| _| `._____||_______|_______/     \______/   \______/  | _| `._____| \______||_______|_______/    
*/
resource aks 'Microsoft.ContainerService/managedClusters@2022-08-03-preview' = {
  name: length(name) > 63 ? substring(name, 0, 63) : name
  location: location
  tags: tags

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }

  sku: {
    name: 'Basic'
    tier: skuTier
  }

  properties: {
    kubernetesVersion: version
    nodeResourceGroup: 'MC_${resourceGroup().name}_${name}'
    dnsPrefix: dnsPrefix

    agentPoolProfiles: agentPoolProfiles
    addonProfiles:  aks_addons

    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: networkPlugin
      #disable-next-line BCP036 //Disabling validation of this parameter to cope with empty string to indicate no Network Policy required.
      networkPolicy: networkPolicy
      networkPluginMode: networkPlugin=='azure' ? networkPluginMode : ''
      podCidr: networkPlugin=='kubenet' || cniDynamicIpAllocation ? podCidr : json('null')
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
      outboundType: aksOutboundTrafficType
    }

    enableRBAC: true
    aadProfile: enable_aad ? {
    managed: true
    enableAzureRBAC: enableAzureRBAC
    tenantID: aad_tenant_id
  } : null

    autoUpgradeProfile: {
      upgradeChannel: aksUpgradeChannel
    }

    autoScalerProfile: AutoscaleProfile

    apiServerAccessProfile: !empty(authorizedIPRanges) ? {
    authorizedIPRanges: authorizedIPRanges
    } : {
      enablePrivateCluster: enablePrivateCluster
      privateDNSZone: enablePrivateCluster ? aksPrivateDnsZone : ''
      enablePrivateClusterPublicFQDN: enablePrivateCluster && privateClusterDnsMethod=='none'
    }

    workloadAutoScalerProfile: {
      keda: {
          enabled: kedaEnabled
      }
    }
    oidcIssuerProfile: {
      enabled: workloadIdentityEnabled
    }
    securityProfile: {
      defender: {
        logAnalyticsWorkspaceResourceId: defenderEnabled ? workspaceId : null
        securityMonitoring: {
          enabled: defenderEnabled
        }
      }
    }
    storageProfile: {
      diskCSIDriver: {
        enabled: true
      }
      fileCSIDriver: {
        enabled: true
      }
      snapshotController: {
        enabled: true
      }
    }
  }
}


/*
  ______    __    __  .___________..______    __    __  .___________.
 /  __  \  |  |  |  | |           ||   _  \  |  |  |  | |           |
|  |  |  | |  |  |  | `---|  |----`|  |_)  | |  |  |  | `---|  |----`
|  |  |  | |  |  |  |     |  |     |   ___/  |  |  |  |     |  |     
|  `--'  | |  `--'  |     |  |     |  |      |  `--'  |     |  |     
 \______/   \______/      |__|     | _|       \______/      |__|     
*/
@description('Specifies the name of the AKS cluster.')
output name string = aks.name

@description('Specifies the OIDC Issuer URL.')
output aksOidcIssuerUrl string = workloadIdentityEnabled ? aks.properties.oidcIssuerProfile.issuerURL : ''

@description('This output can be directly leveraged when creating a ManagedId Federated Identity')
output aksOidcFedIdentityProperties object = {
  issuer: workloadIdentityEnabled ? aks.properties.oidcIssuerProfile.issuerURL : ''
  audiences: ['api://AzureADTokenExchange']
  subject: 'system:serviceaccount:ns:svcaccount'
}

@description('Specifies the name of the AKS Managed Resource Group.')
output aksNodeResourceGroup string = aks.properties.nodeResourceGroup


/*
 _______  __       __    __  ___   ___ 
|   ____||  |     |  |  |  | \  \ /  / 
|  |__   |  |     |  |  |  |  \  V  /  
|   __|  |  |     |  |  |  |   >   <   
|  |     |  `----.|  `--'  |  /  .  \  
|__|     |_______| \______/  /__/ \__\ 
*/
@description('Enable the Flux GitOps Operator')
param fluxGitOpsAddon bool = false

resource fluxAddon 'Microsoft.KubernetesConfiguration/extensions@2022-04-02-preview' = if(fluxGitOpsAddon) {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
    configurationProtectedSettings: {}
  }
  dependsOn: [aks]
}
@description('Flux Release Namespace')
output fluxReleaseNamespace string = fluxGitOpsAddon ? fluxAddon.properties.scope.cluster.releaseNamespace : ''
