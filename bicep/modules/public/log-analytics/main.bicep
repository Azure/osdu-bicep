targetScope = 'resourceGroup'

@minLength(3)
@maxLength(63)
@description('Used to name all resources')
param resourceName string

@description('Workspace Location.')
param location string = resourceGroup().location

@description('Sku of the workspace')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
param sku string

@description('The workspace data retention in days, between 30 and 730')
@minValue(30)
@maxValue(730)
param retentionInDays int

@description('Solutions to add to workspace')
param solutions array = [
  {
    name: 'ContainerInsights'
    product: 'OMSGallery/ContainerInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
]

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Name of automation account to link to workspace')
param automationAccountName string = ''

@description('Datasources to add to workspace')
param dataSources array = [
  {
    name: 'LinuxPerfCollection'
    kind: 'LinuxPerformanceCollection'
    properties: {
      state: 'Enabled'
    }
  }
]

@description('Enable diagnostic logs')
param enableDiagnostics bool = false

@description('Storage account name. Only required if enableDiagnostics is set to true.')
param diagnosticStorageAccountName string = ''

@description('Storage account resource group. Only required if enableDiagnostics is set to true.')
param diagnosticStorageAccountResourceGroup string = ''

// Define Variables
var diagnosticsName = '${logAnalyticsWorkspace.name}-dgs'
var name = 'log-${uniqueString(resourceGroup().id, resourceName)}'

// Create a Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: length(name) > 63 ? substring(name, 0, 63) : name
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: 30
    }
  }
}

// Create Log Analytics Solutions
resource logAnalyticsSolutions 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [for solution in solutions: {
  name: '${solution.name}(${logAnalyticsWorkspace.name})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: '${solution.name}(${logAnalyticsWorkspace.name})'
    product: solution.product
    publisher: solution.publisher
    promotionCode: solution.promotionCode
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}]

// Hook up an Automation Account if provided
resource logAnalyticsAutomation 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = if (!empty(automationAccountName)) {
  parent: logAnalyticsWorkspace
  name: 'Automation'
  properties: {
    resourceId: resourceId('Microsoft.Automation/automationAccounts', automationAccountName)
  }
}

// Create Log Analytics Data Sources
resource logAnalyticsDataSource 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = [for dataSource in dataSources: {
  parent: logAnalyticsWorkspace
  name: dataSource.name
  kind: dataSource.kind
  properties: dataSource.properties
}]

resource resource_lock 'Microsoft.Authorization/locks@2017-04-01' = if (lock != 'NotSpecified') {
  name: '${logAnalyticsWorkspace.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: logAnalyticsWorkspace
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: diagnosticsName
  scope: logAnalyticsWorkspace
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    storageAccountId: resourceId(diagnosticStorageAccountResourceGroup, 'Microsoft.Storage/storageAccounts', diagnosticStorageAccountName)
    logs: [
      {
        category: 'Audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The resource ID of the workspace.')
output id string = logAnalyticsWorkspace.id
