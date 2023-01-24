@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Specifies the VNET.')
param vnetId string

@description('Storage Account Name')
param accountName string = 'dapracastorage'

@description('Storage Account Key')
@secure()
param storageaccountkey string

@description('EventHubs Connection String')
param evhConnectionString string

@description('CosmosDB Name')
param cosmosDbName string

resource logs 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: 'container-apps-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'container-apps-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logs.id
  }
}

// https://github.com/Azure/azure-rest-api-specs/blob/cca8e03063c627f256fe0b3761db82450b25fdbb/specification/app/resource-manager/Microsoft.App/preview/2022-01-01-preview/ManagedEnvironments.json#L660
resource app_environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: 'container-apps-env'
  location: location
  properties: {
    daprAIInstrumentationKey: insights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logs.properties.customerId
        sharedKey: logs.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: '${vnetId}/subnets/apps'
    }
  }
}

module aca_environment_dns './aca_environment_dns.bicep' = {
  name: 'aca_environment_dns-module'
  params: {
    fqdn: app_environment.properties.defaultDomain
    vnetId: vnetId
    staticIP: app_environment.properties.staticIp
  }
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' existing = {
  name: cosmosDbName
}

resource dapr_state_store 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'statestore'
  parent: app_environment
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    secrets: [
      {
        name: 'masterkey'
        value: cosmos.listKeys().primaryMasterKey
      }
    ]
    metadata: [
      {
        name: 'url'
        value: cosmos.properties.documentEndpoint
      }
      {
        name: 'database'
        value: 'runners'
      }
      {
        name: 'collection'
        value: 'state'
      }
      {
        name: 'masterKey'
        secretRef: 'masterkey'
      }
      {
        name: 'actorStateStore'
        value: 'true'
      }
    ]
    scopes: []
  }
}

resource dapr_pub_sub 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'pubsub'
  parent: app_environment
  properties: {
    componentType: 'pubsub.azure.eventhubs'
    version: 'v1'
    secrets: [
      {
        name: 'evhconnectionstring'
        value: evhConnectionString
      }
      {
        name: 'storageaccountkey'
        value: storageaccountkey
      }
    ]
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'evhconnectionstring'
      }
      {
        name: 'enableEntityManagement'
        value: 'false'
      }
      {
        name: 'storageAccountName'
        value: accountName
      }
      {
        name: 'storageContainerName'
        value: 'subscribers'
      }
      {
        name: 'storageAccountKey'
        secretRef: 'storageaccountkey'
      }
    ]
    scopes: [
      'race-control'
      'check-point'
      'race-simulator'
    ]
  }
}

output id string = app_environment.id
