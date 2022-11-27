/*
  This is a custom module that deploys a jetstack cert-manager helm chart.
  https://cert-manager.io/docs/installation/helm/
*/


@description('The name of the AKS cluster.')
param aksName string

@description('The region location')
param location string = resourceGroup().location

@description('The namespace for the chart.')
param namespace string = 'cert-manager'

var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

var unformattedHelmCommands = '''
helm repo add jetstack https://charts.jetstack.io;
helm repo update;
helm install cert-manager jetstack/cert-manager --namespace {0} --create-namespace --version v1.10.1 --set installCRDs=true
kubectl get all -n {0};
'''
var formattedHelmCommands = format(unformattedHelmCommands, namespace)

module aksRun './aks_run_command.bicep' = {
  name: 'run-command-helm-install-cert-manager'
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
