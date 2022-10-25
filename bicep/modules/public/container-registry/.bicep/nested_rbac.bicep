param description string = ''
param principalIds array
param principalType string = ''
param roleDefinitionIdOrName string
param resourceId string

var builtInRoleNames = {
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'ACR Delete': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c2f4ef07-c644-48eb-af81-4b1b4947fb11')
  'ACR Image Signer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '6cef56e8-d556-48e5-a04f-b8e64114680f')
  'ACR Pull': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  'ACR Push': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')
  'ACR Quarantine Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'cdda3590-29a3-44f6-95f2-9f980659eb04')
  'ACR Quarantine Write': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c8d4ff99-41c3-41a8-9f60-21dfdad59608')
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: last(split(resourceId, '/'))
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in principalIds: {
  name: guid(acr.name, principalId, roleDefinitionIdOrName)
  properties: {
    description: description
    roleDefinitionId: contains(builtInRoleNames, roleDefinitionIdOrName) ? builtInRoleNames[roleDefinitionIdOrName] : roleDefinitionIdOrName
    principalId: principalId
    principalType: !empty(principalType) ? principalType : null
  }
  scope: acr
}]
