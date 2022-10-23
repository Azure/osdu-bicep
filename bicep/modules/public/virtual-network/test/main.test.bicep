targetScope = 'resourceGroup'

@description('Hub Network Location.')
param hubLocation string = resourceGroup().location

@description('Spoke Network Location.')
param spokeLocation string = resourceGroup().location


//  Module --> Create Virtual Network
module vnet '../main.bicep' = {
  name: 'azure_vnet_hub'
  params: {
    resourceName: 'hub'
    location: hubLocation
    newOrExistingNSG: 'none'
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.0.0/26'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.0.64/27'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.0.128/26'
      }
    ]
  }
}

module spoke_vnet '../main.bicep' = {
  name: 'azure_vnet_spoke'
  params: {
    resourceName: 'spoke'
    location: spokeLocation
    addressPrefixes: [
      '10.1.0.0/16'
    ]
    subnets: [
      {
        name: 'workloads'
        addressPrefix: '10.1.0.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        serviceEndpoints: [
          {
            service: 'Microsoft.Storage'
          }
        ]
      }
    ]
    newOrExistingNSG: 'new'
    virtualNetworkPeerings: [
      {
        remoteVirtualNetworkId: vnet.outputs.id
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        useRemoteGateways: false
        remotePeeringEnabled: true
        remotePeeringName: 'spoke1'
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
      }
    ]
  }
}

