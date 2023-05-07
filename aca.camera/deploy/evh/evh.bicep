@description('Specifies the location for resources.')
param location string = resourceGroup().location
@description('Key Vault Name')
param keyVaultName string
param evhName string

resource evh_namespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: evhName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    zoneRedundant: false
  }
}

resource evh 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  name: 'camera-control'
  parent: evh_namespace
  properties: {
    partitionCount: 2
    messageRetentionInDays: 1
  }
}

resource camera_control_consumer 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-11-01' = {
  name: 'camera-control'
  parent: evh
}

resource notification_consumer 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-11-01' = {
  name: 'notification-service'
  parent: evh
}

resource auth_evh 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-11-01' = {
  name: 'DaprListenSend'
  parent: evh
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

resource evh_connection_string_secret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'evh-connection-string'
  properties: {
    value: auth_evh.listKeys().primaryConnectionString
  }
}

output evh_connection_string string = auth_evh.listKeys().primaryConnectionString
