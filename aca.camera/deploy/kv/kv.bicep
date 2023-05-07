@description('Specifies the location for resources.')
param location string = resourceGroup().location
param mi_objectId string

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: 'kvcfm'
  location: location
  properties: {
    enabledForTemplateDeployment: true
    tenantId: tenant().tenantId
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: mi_objectId
        permissions: {
          secrets: [ 'all' ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

output name string = keyVault.name
