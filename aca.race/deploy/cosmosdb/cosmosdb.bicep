@description('Specifies the location for resources.')
param location string = resourceGroup().location

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' = {
  name: 'dapr-aca-cosmosdb'
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Strong'
    }
    locations: []
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
  }
}

resource cosmos_databaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-01-15' = {
  parent: cosmos
  name: 'runners'
  properties: {
    resource: {
      id: 'runners'
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

output name string = cosmos.name
