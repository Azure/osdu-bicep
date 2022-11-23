/*
  This is a flux GitOps Configuration for a multi-tenancy assigned responsibility.
  https://learn.microsoft.com/en-gb/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2
  https://github.com/fluxcd/flux2-multi-tenancy
  https://github.com/Azure/gitops-flux2-kustomize-helm-mt
*/


@description('The name of the AKS cluster.')
param aksName string

@description('The namespace for flux.')
param aksFluxAddOnReleaseNamespace string = 'flux-system'

resource aks 'Microsoft.ContainerService/managedClusters@2022-03-02-preview' existing = {
  name: aksName
}



@description('The Git Repository URL where your flux configuration is homed')
param fluxConfigRepo string = 'https://github.com/Azure/gitops-flux2-kustomize-helm-mt' //'https://github.com/Azure/gitops-flux2-kustomize-helm-mt' //'https://github.com/fluxcd/flux2-kustomize-helm-example'

@description('The Git Repository Branch where your flux configuration is homed')
param fluxConfigRepoBranch string = 'main'

@description('The name of the flux configuration to apply')
param fluxConfigName string = 'fluxsetup'
var cleanFluxConfigName = toLower(fluxConfigName)

@secure()
@description('For private Repos, provide the username')
param fluxRepoUsername string = ''
var fluxRepoUsernameB64 = base64(fluxRepoUsername)

@secure()
@description('For private Repos, provide the password')
param fluxRepoPassword string = ''
var fluxRepoPasswordB64 = base64(fluxRepoPassword)

@description('The Git Repository path for infrastructure')
param fluxRepoInfraPath string = './infrastructure'

@description('The Git Repository path for apps')
param fluxRepoAppsPath string = './apps/staging'

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2022-03-01' = {
  scope: aks
  name: cleanFluxConfigName
  properties: {
    scope: 'cluster'
    namespace: aksFluxAddOnReleaseNamespace
    sourceKind: 'GitRepository'
    gitRepository: {
      url: fluxConfigRepo
      timeoutInSeconds: 180
      syncIntervalInSeconds: 300
      repositoryRef: {
        branch: fluxConfigRepoBranch
      }
    }
    configurationProtectedSettings: !empty(fluxRepoUsernameB64) && !empty(fluxRepoPasswordB64) ? {
      username: fluxRepoUsernameB64
      password: fluxRepoPasswordB64
    } : {}
    kustomizations: {
      infra: {
        path: fluxRepoInfraPath
        timeoutInSeconds: 300
        syncIntervalInSeconds: 300
        retryIntervalInSeconds: 300
        prune: true
      }
      apps: {
        path: fluxRepoAppsPath
        dependsOn: [
          'infra'
        ]
        timeoutInSeconds: 300
        syncIntervalInSeconds: 300
        retryIntervalInSeconds: 300
        prune: true
      }
    }
  }
}
