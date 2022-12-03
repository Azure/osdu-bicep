targetScope = 'resourceGroup'

@minLength(2)
@maxLength(59)
@description('Used to name all resources')
param resourceName string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Resource Tags (Optional).')
param tags object = {}

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Optional. Virtual Network Peerings configurations')
param virtualNetworkPeerings array = []

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@allowed([ 'new', 'existing', 'none' ])
@description('Create a new, use an existing, or provide no default NSG.')
param newOrExistingNSG string = 'new'

@description('Name of default NSG to use for subnets.')
param networkSecurityGroupName string = ''

@description('Optional. DNS Servers associated to the Virtual Network.')
param dnsServers array = []

@description('Optional. Resource ID of the DDoS protection plan to assign the VNET to. If it\'s left blank, DDoS protection will not be configured. If it\'s provided, the VNET created by this template will be attached to the referenced DDoS protection plan. The DDoS protection plan can exist in the same or in a different subscription.')
param ddosProtectionPlanId string = ''

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'VMProtectionAlerts'
])
param logsToEnable array = [
  'VMProtectionAlerts'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

@description('Virtual Network Address CIDR')
param addressPrefixes array = [
  '192.168.0.0/24'
]

@description('Virtual Network Subnets')
param subnets array = [
  {
    name: 'default'
    addressPrefix: '192.168.0.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
  }
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

var name = 'vnet-${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

var networkSecurityGroupId = { id: newOrExistingNSG == 'new' ? networkSecurityGroup.id : existingNetworkSecurityGroup.id }

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

var dnsServers_obj = {
  dnsServers: array(dnsServers)
}
var ddosProtectionPlan = {
  id: ddosProtectionPlanId
}


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-08-01' = if( newOrExistingNSG == 'new' ) {
  name:  empty(networkSecurityGroupName) ? '${name}-nsg' : networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'deny-hop-outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '3389'
            '22'
          ]
          access: 'Deny'
          priority: 200
          direction: 'Outbound'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource existingNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-08-01' existing = if( newOrExistingNSG == 'existing' ) {
  name: networkSecurityGroupName
}


// Create a Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: length(name) > 63 ? substring(name, 0, 64) : name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    ddosProtectionPlan: !empty(ddosProtectionPlanId) ? ddosProtectionPlan : null
    dhcpOptions: !empty(dnsServers) ? dnsServers_obj : null
    enableDdosProtection: !empty(ddosProtectionPlanId)
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        addressPrefixes: contains(subnet, 'addressPrefixes') ? subnet.addressPrefixes : []
        applicationGatewayIpConfigurations: contains(subnet, 'applicationGatewayIpConfigurations') ? subnet.applicationGatewayIpConfigurations : []
        delegations: contains(subnet, 'delegations') ? subnet.delegations : []
        ipAllocations: contains(subnet, 'ipAllocations') ? subnet.ipAllocations : []
        natGateway: contains(subnet, 'natGatewayId') ? { id: subnet.natGatewayId } : json('null')
        networkSecurityGroup: contains(subnet, 'networkSecurityGroupId') ? { id: subnet.networkSecurityGroupId } : ( newOrExistingNSG != 'none' ? networkSecurityGroupId : json('null'))
        privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies') ? subnet.privateEndpointNetworkPolicies : null
        privateLinkServiceNetworkPolicies: contains(subnet, 'privateLinkServiceNetworkPolicies') ? subnet.privateLinkServiceNetworkPolicies : null
        routeTable: contains(subnet, 'routeTableId') ? { id: subnet.routeTableId } : json('null')
        serviceEndpoints: contains(subnet, 'serviceEndpoints') ? subnet.serviceEndpoints : []
        serviceEndpointPolicies: contains(subnet, 'serviceEndpointPolicies') ? subnet.serviceEndpointPolicies : []
      }
    }]
  }
}

// Apply Resource Lock
resource virtualNetwork_lock 'Microsoft.Authorization/locks@2017-04-01' = if (lock != 'NotSpecified') {
  name: '${vnet.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: vnet
}


// Hook up Vnet Diagnostics
resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: 'vnet-diagnostics'
  scope: vnet
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  dependsOn: [
    vnet
  ]
}

module virtualNetwork_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    resourceId: vnet.id
  }
}]


// Local to Remote peering
module virtualNetwork_peering_local '.bicep/peering.bicep' = [for (peering, index) in virtualNetworkPeerings: {
  name: '${deployment().name}-peering-local-${index}'
  params: {
    localVnetName: vnet.name
    remoteVirtualNetworkId: peering.remoteVirtualNetworkId
    name: contains(peering, 'name') ? peering.name : '${name}-${last(split(peering.remoteVirtualNetworkId, '/'))}'
    allowForwardedTraffic: contains(peering, 'allowForwardedTraffic') ? peering.allowForwardedTraffic : true
    allowGatewayTransit: contains(peering, 'allowGatewayTransit') ? peering.allowGatewayTransit : false
    allowVirtualNetworkAccess: contains(peering, 'allowVirtualNetworkAccess') ? peering.allowVirtualNetworkAccess : true
    doNotVerifyRemoteGateways: contains(peering, 'doNotVerifyRemoteGateways') ? peering.doNotVerifyRemoteGateways : true
    useRemoteGateways: contains(peering, 'useRemoteGateways') ? peering.useRemoteGateways : false
  }
}]

// Remote to local peering (reverse)
module virtualNetwork_peering_remote '.bicep/peering.bicep' = [for (peering, index) in virtualNetworkPeerings: if (contains(peering, 'remotePeeringEnabled') ? peering.remotePeeringEnabled == true : false) {
  name: '${deployment().name}-peering-remote-${index}'
  scope: resourceGroup(split(peering.remoteVirtualNetworkId, '/')[2], split(peering.remoteVirtualNetworkId, '/')[4])
  params: {
    localVnetName: last(split(peering.remoteVirtualNetworkId, '/'))
    remoteVirtualNetworkId: vnet.id
    name: contains(peering, 'remotePeeringName') ? peering.remotePeeringName : '${last(split(peering.remoteVirtualNetworkId, '/'))}-${name}'
    allowForwardedTraffic: contains(peering, 'remotePeeringAllowForwardedTraffic') ? peering.remotePeeringAllowForwardedTraffic : true
    allowGatewayTransit: contains(peering, 'remotePeeringAllowGatewayTransit') ? peering.remotePeeringAllowGatewayTransit : false
    allowVirtualNetworkAccess: contains(peering, 'remotePeeringAllowVirtualNetworkAccess') ? peering.remotePeeringAllowVirtualNetworkAccess : true
    doNotVerifyRemoteGateways: contains(peering, 'remotePeeringDoNotVerifyRemoteGateways') ? peering.remotePeeringDoNotVerifyRemoteGateways : true
    useRemoteGateways: contains(peering, 'remotePeeringUseRemoteGateways') ? peering.remotePeeringUseRemoteGateways : false
  }
}]

@description('The resource ID of the virtual network')
output id string = vnet.id

@description('The name of the virtual network')
output name string = vnet.name

@description('The names of the deployed subnets')
output subnetNames array = [for subnet in subnets: subnet.name]

@description('The resource IDs of the deployed subnets')
output subnetIds array = [for subnet in subnets: az.resourceId('Microsoft.Network/virtualNetworks/subnets', name, subnet.name)]

@description('The network security group id')
output nsgName string = newOrExistingNSG != 'none' ? networkSecurityGroup.name : ''
