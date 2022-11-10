@description('Conditional. The name of the parent Database Account. Required if the template is used in a standalone deployment.')
param databaseAccountName string

@description('Required. Name of the SQL database .')
param name string

@description('Optional. Array of containers to deploy in the SQL database.')
param containers array = []

@description('Optional. Represents maximum throughput, the resource can scale up to. Cannot be set together with `throughput`. If `throughput` is set to something else than -1, this autoscale setting is ignored.')
param maxThroughput int = 400

@description('Optional. Request Units per second (for example 10000). Cannot be set together with `maxThroughput`.')
param throughput int = -1

@description('Optional. Tags of the SQL database resource.')
param tags object = {}

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

var enableReferencedModulesTelemetry = false

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: databaseAccountName
}

var databaseOptions = contains(databaseAccount.properties.capabilities, { name: 'EnableServerless' }) ? {} : {
  autoscaleSettings: throughput == -1 ? {
    maxThroughput: maxThroughput
  } : null
  throughput: throughput != -1 ? throughput : null
}


resource sqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-08-15' = {
  name: name
  parent: databaseAccount
  tags: tags
  properties: {
    options: databaseOptions
    resource: {
      id: name
    }
  }
}

module container 'sql_container.bicep' = [for (container, index) in containers: {
  name: '${deployment().name}-${sqlDatabase.name}-sql-${index}'
  params: {
    databaseAccountName: databaseAccountName
    sqlDatabaseName: name
    name: container.name
    paths: container.paths
    kind: container.kind
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}]

@description('The name of the SQL database.')
output name string = sqlDatabase.name

@description('The resource ID of the SQL database.')
output resourceId string = sqlDatabase.id

@description('The name of the resource group the SQL database was created in.')
output resourceGroupName string = resourceGroup().name
