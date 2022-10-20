targetScope = 'resourceGroup'

@minLength(3)
@maxLength(20)
@description('Used to name all resources')
param resourceName string

@description('User Managed Identity Location.')
param location string = resourceGroup().location

@description('Tags.')
param tags object = {}

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

var name = 'id-${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

// Create User Identities
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: length(name) > 24 ? substring(name, 0, 24) : name
  location: location
  tags: tags
}

// Apply Resource Lock
resource resource_lock 'Microsoft.Authorization/locks@2017-04-01' = if (lock != 'NotSpecified') {
  name: '${managedIdentity.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: managedIdentity
}

@description('The resource ID of the managed identity.')
output id string = managedIdentity.id

@description('The principal id for the managed identity.')
output principalId string = managedIdentity.properties.principalId
