/*
  This is a custom module that deploys a workload identity helm chart.
  https://azure.github.io/azure-workload-identity/docs/installation/mutating-admission-webhook.html
*/


@description('The name of the AKS cluster.')
param aksName string

@description('The region location')
param location string = resourceGroup().location

@description('The Tenant Id.')
param tenantId string = subscription().tenantId

@description('The namespace for the chart.')
param namespace string = 'azure-workload-identity-system'

var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

var unformattedHelmCommands = '''
helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts;
helm repo update;
helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook --namespace {0} --create-namespace --set azureTenantID="{1}";
kubectl get all -n {0};
'''
var formattedHelmCommands = format(unformattedHelmCommands, namespace, tenantId)

module aksRun './aks_run_command.bicep' = {
  name: 'run-command-helm-install-workload-identity'
  params: {
    aksName: aksName
    location: location
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
    commands: [
      formattedHelmCommands
    ]
  }
}

output helmCommand string = formattedHelmCommands
