targetScope = 'resourceGroup'

@description('PrivateDNSZone name.')
param resourceName string


// Dependency: Storage
module storage '../../storage-account/main.bicep' = {
  name: 'storage_account'
  params: {
    resourceName: resourceName
    sku: 'Standard_LRS'
  }
}


// Dependency: Private DNS Zone
var publicDNSZoneForwarder = 'blob.${environment().suffixes.storage}'
var privateDnsZoneName = 'privatelink.${publicDNSZoneForwarder}'

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

// Dependency: Network
module network '../../virtual-network/main.bicep' = {
  name: 'azure_vnet'
  params: {
    resourceName: resourceName
    addressPrefixes: [
      '192.168.0.0/24'
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '192.168.0.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
  }
}

//  Module --> Create a Private DNS zone
module endpoint '../main.bicep' = {
  name: 'privateDnsZoneModule'
  params: {

    resourceName: resourceName

    groupIds: [
      'blob'
    ]

    privateDnsZoneGroup: {
      privateDNSResourceIds: [
        privateDNSZone.id
      ]
    }

    serviceResourceId: storage.outputs.id
    subnetResourceId: network.outputs.subnetIds[0]
  }
}
