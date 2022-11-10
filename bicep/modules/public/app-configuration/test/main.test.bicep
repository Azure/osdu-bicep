targetScope = 'resourceGroup'

@minLength(3)
@maxLength(10)
@description('Used to name all resources')
param resourceName string

@description('Registry Location.')
param location string = resourceGroup().location

//  Module --> Create Resource
module ac '../main.bicep' = {
  name: 'azure_app_configuration'
  params: {
    resourceName: resourceName
    location: location
    enableDeleteLock: true
    configObjects: {
      configs: [
        {
          key: 'myKey'
          value: 'myValue'
        }
        {
          key: 'keyVaultref'
          value: string(
            {
              uri: 'keyVaultSecretURL'
            }
          )
          contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
        }
      ]
    }
  }
}


