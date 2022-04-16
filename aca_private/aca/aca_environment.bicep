@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Specifies the VNET.')
param vnetId string

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

// https://github.com/Azure/azure-rest-api-specs/blob/cca8e03063c627f256fe0b3761db82450b25fdbb/specification/app/resource-manager/Microsoft.App/preview/2022-01-01-preview/ManagedEnvironments.json#L660
resource app_environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: 'container-apps-env'
  location: location
  properties: {
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

module aca_environment './aca_environment_dns.bicep' = {
  name: 'aca_environment_dns-module'
  params: {
    fqdn: app_environment.properties.defaultDomain
    vnetId: vnetId
    staticIP: app_environment.properties.staticIp
  }
}

output id string = app_environment.id
