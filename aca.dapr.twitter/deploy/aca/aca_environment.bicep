@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Specifies the VNET.')
param vnetId string

@description('Container Name')
param containerName string = 'tweets'

@description('Storage Account Name')
param accountName string = 'daprtwitterstorage'

@description('Storage Account Key')
param storageaccountkey string

@description('EventHubs Connection String')
param evhConnectionString string

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
      infrastructureSubnetId: '${vnetId}/subnets/controlplane'
      runtimeSubnetId: '${vnetId}/subnets/apps'
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

resource dapr_state_store 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'statestore'
  parent: app_environment
  properties: {
    componentType: 'state.azure.blobstorage'
    version: 'v1'
    secrets: [
      {
        name: 'storageaccountkey'
        value: storageaccountkey
      }
    ]
    metadata: [
      {
        name: 'accountName'
        value: accountName
      }
      {
        name: 'containerName'
        value: containerName
      }
      {
        name: 'accountKey'
        secretRef: 'storageaccountkey'
      }
    ]
    scopes: [
      'read-twitter'
    ]
  }
}

resource dapr_twitter_binding 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'tweets'
  parent: app_environment
  properties: {
    componentType: 'bindings.twitter'
    version: 'v1'
    secrets: [
      {
        name: 'consumerkey'
        value: '<consumer key>'
      }
      {
        name: 'consumersecret'
        value: '<consumer secret>'
      }
      {
        name: 'accesstoken'
        value: '<access token>'
      }
      {
        name: 'accesssecret'
        value: '<access secret>'
      }
    ]
    metadata: [
      {
        name: 'consumerKey'
        secretRef: 'consumerkey'
      }
      {
        name: 'consumerSecret'
        secretRef: 'consumersecret'
      }
      {
        name: 'accessToken'
        secretRef: 'accesstoken'
      }
      {
        name: 'accessSecret'
        secretRef: 'accesssecret'
      }
      {
        name: 'query'
        value: 'covid19'
      }
    ]
    scopes: [
      'read-twitter'
    ]
  }
}

resource dapr_message_bus 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: 'messagebus'
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
  }
}

output id string = app_environment.id
