@description('Specifies the location for resources.')
param location string = resourceGroup().location

// @description('Specifies the VNET.')
// param vnetId string

// @description('Specifies the Subnet.')
// param subnetName string

resource storage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: 'daprtwitterstorage'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storage.name}/default/tweets'
  properties: {}
}

resource subscribers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storage.name}/default/subscribers'
  properties: {}
}

output key string = storage.listKeys().keys[0].value
output blobConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
