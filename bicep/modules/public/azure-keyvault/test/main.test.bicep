targetScope = 'resourceGroup'

@minLength(3)
@maxLength(10)
@description('Used to name all resources')
param resourceName string

@description('Registry Location.')
param location string = resourceGroup().location

//  Module --> Create Resource
module kv '../main.bicep' = {
  name: 'azure_keyvault'
  params: {
    resourceName: resourceName
    location: location
    secretsObject: { secrets: [] }
  }
}
