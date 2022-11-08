@description('Conditional. The name of the parent Database Account. Required if the template is used in a standalone deployment.')
param databaseAccountName string

@description('Conditional. The name of the parent SQL Database. Required if the template is used in a standalone deployment.')
param sqlDatabaseName string

@description('Required. Name of the container.')
param name string

@description('Optional. Represents maximum throughput, the resource can scale up to. Cannot be set together with `throughput`. If `throughput` is set to something else than -1, this autoscale setting is ignored.')
param maxThroughput int = 4000

@description('Optional. Request Units per second (for example 10000). Cannot be set together with `maxThroughput`.')
param throughput int = -1

@description('Optional. Tags of the SQL Database resource.')
param tags object = {}

@description('Optional. List of paths using which data within the container can be partitioned.')
param paths array = []

@description('Optional. Indicates the kind of algorithm used for partitioning.')
@allowed([
  'Hash'
  'MultiHash'
  'Range'
])
param kind string = 'Hash'

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

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

  resource sqlDatabase 'sqlDatabases@2022-08-15' existing = {
    name: sqlDatabaseName
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  name: name
  parent: databaseAccount::sqlDatabase
  tags: tags
  properties: {
    resource: {
      id: name
      partitionKey: {
        paths: paths
        kind: kind
      }
    }
    options: contains(databaseAccount.properties.capabilities, { name: 'EnableServerless' }) ? null : {
      throughput: throughput
      maxThroughput: maxThroughput
    }
  }
}

@description('The name of the container.')
output name string = container.name

@description('The resource ID of the container.')
output resourceId string = container.id

@description('The name of the resource group the container was created in.')
output resourceGroupName string = resourceGroup().name
