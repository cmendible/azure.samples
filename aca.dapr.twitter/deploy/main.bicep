@description('Specifies the location for resources.')
param location string = resourceGroup().location

module vnet './vnet/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    location: location
  }
}

module vm './vm/vm.bicep' = {
  name: 'vm-module'
  params: {
    location: location
    vnetId: vnet.outputs.id
    subnetName: 'jumpbox'
  }
}

module storage './storage/storage.bicep' = {
  name: 'storage-module'
  params: {
    location: location
    // vnetId: vnet.outputs.id
    // subnetName: 'endpoints'
  }
}

module evh './evh/evh.bicep' = {
  name: 'evh-module'
  params: {
    location: location
  }
}

module cognitive './cognitive/cognitive.bicep' = {
  name: 'cognitive-module'
  params: {
    location: location
  }
}

module aca_environment './aca/aca_environment.bicep' = {
  name: 'aca_environment-module'
  params: {
    location: location
    vnetId: vnet.outputs.id
    storageaccountkey: storage.outputs.key
    evhConnectionString: evh.outputs.connectionString
  }
}

resource reader_app 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'read-twitter'
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: aca_environment.outputs.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      secrets: []
      dapr: {
        enabled: true
        appId: 'read-twitter'
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/dapr-read-twitter'
          name: 'read-twitter'
          env: []
          resources: {
            cpu: '0.5'
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

resource analyze_app 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'analyze-tweet'
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: aca_environment.outputs.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      secrets: [
        {
          name: 'cognitive-service-key'
          value: cognitive.outputs.key
        }
      ]
      dapr: {
        enabled: true
        appId: 'analyze-tweet'
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/dapr-analyze-tweet'
          name: 'analyze-tweet'
          env: [
            {
              name: 'COGNITIVE_SERVICE_KEY'
              secretRef: 'cognitive-service-key'
            }
          ]
          resources: {
            cpu: '0.5'
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
