@description('Specifies the location for resources.')
param location string = resourceGroup().location
@description('Key Vault Name')
param keyVaultName string
param storageName string

resource storage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
  }
}

resource subscribers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storage.name}/default/subscribers'
  properties: {}
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

resource storage_ccount_key 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'storage-account-key'
  properties: {
    value: storage.listKeys().keys[0].value
  }
}

output name string = storage.name
