/*
  This is the main bicep entry file.

  10.20.22: Updated
--------------------------------
  - Establishing the Pipelines
  - Added an Identity
*/

@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

/*
 __   _______   _______ .__   __. .___________. __  .___________.____    ____ 
|  | |       \ |   ____||  \ |  | |           ||  | |           |\   \  /   / 
|  | |  .--.  ||  |__   |   \|  | `---|  |----`|  | `---|  |----` \   \/   /  
|  | |  |  |  ||   __|  |  . `  |     |  |     |  |     |  |       \_    _/   
|  | |  '--'  ||  |____ |  |\   |     |  |     |  |     |  |         |  |     
|__| |_______/ |_______||__| \__|     |__|     |__|     |__|         |__|     
*/

// Create a Managed User Identity for the Cluster
module clusterIdentity 'br:osdubicep.azurecr.io/public/user-managed-identity:1.0.1' = {
  name: 'user_identity_cluster'
  params: {
    resourceName: 'id-aks-${uniqueString(resourceGroup().id)}'
    location: location
  }
}
