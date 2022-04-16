@description('Specifies the location for resources.')
param location string = resourceGroup().location

resource cognitive 'Microsoft.CognitiveServices/accounts@2022-03-01' = {
  name: 'daprAnalytics'
  kind: 'CognitiveServices'
  location: location
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    restore: false
  }
}

output key string = cognitive.listKeys().key1
