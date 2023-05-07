@description('Specifies the location for resources.')
param location string = resourceGroup().location
@description('Key Vault Name')
param keyVaultName string

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' = {
  name: 'dapr-aca-cosmosdb'
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Strong'
    }
    locations: [
      {
        isZoneRedundant: false
        locationName: location
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
  }
}

resource cosmos_databaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-01-15' = {
  parent: cosmos
  name: 'cameras'
  properties: {
    resource: {
      id: 'cameras'
    }
  }
}

resource cosmos_containerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-01-15' = {
  parent: cosmos_databaseName
  name: 'state'
  properties: {
    resource: {
      id: 'state'
      partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

resource cosmosdb_master_key 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'cosmosdb-master-key'
  properties: {
    value: cosmos.listKeys().primaryMasterKey
  }
}

output name string = cosmos.name
