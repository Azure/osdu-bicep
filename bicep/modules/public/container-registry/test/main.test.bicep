targetScope = 'resourceGroup'

@minLength(3)
@maxLength(10)
@description('Used to name all resources')
param resourceName string

@description('Registry Location.')
param location string = resourceGroup().location


//  Module --> Create Container Registry
module acr '../main.bicep' = {
  name: 'container_registry'
  params: {
    resourceName: resourceName
    location: location
    sku: 'Standard'
  }
}
