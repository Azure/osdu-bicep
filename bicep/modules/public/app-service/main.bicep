targetScope = 'resourceGroup'

@minLength(3)
@maxLength(20)
@description('Used to name all resources')
param resourceName string 

@description('Resource Location.')
param location string = resourceGroup().location

@description('SKU for the App Service Plan')
param sku string = 'S1'

@description('SKU tier for the App Service Plan')
param skuTier string = 'Standard'

@minValue(2)
@description('Capacity for the App Service Plan')
param skuCapacity int = 2

@description('Enable lock to prevent accidental deletion')
param enableDeleteLock bool = false

@description('The Runtime stack of current web app')
param linuxFxVersion string = 'NODE|10.15'

@description('Improve performance of your stateless app by turning Affinity Cookie off, stateful apps should keep this setting on for compatibility')
param clientAffinityEnabled bool = false

var appServicePlanName = 'plan-${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'
var appServiceName = 'web-${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
    tier: skuTier
    capacity: skuCapacity
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: location
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      alwaysOn: true
      http20Enabled: true
    }
    clientAffinityEnabled: clientAffinityEnabled
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource appServicePlanLock 'Microsoft.Authorization/locks@2017-04-01' = if (enableDeleteLock) {
  scope: appServicePlan

  name: '${appServicePlan.name}-lock'
  properties: {
    level: 'CanNotDelete'
  }
}

resource appServiceLock 'Microsoft.Authorization/locks@2017-04-01' = if (enableDeleteLock) {
  scope: appService

  name: '${appService.name}-lock'
  properties: {
    level: 'CanNotDelete'
  }
}

@description('The name of the App Service Plan')
output appServicePlanName string = appServicePlan.name

@description('The resourceId of the App Service Plan')
output appServicePlanId string = appServicePlan.id

@description('The name of the App Service')
output appServiceName string = appService.name

@description('The resourceId of the App Service')
output appServiceId string = appService.id
