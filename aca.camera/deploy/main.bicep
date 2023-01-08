@description('Specifies the location for resources.')
param location string = resourceGroup().location

module vnet './vnet/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    location: location
  }
}

module bastion './bastion/bastion.bicep' = {
  name: 'bastion-module'
  params: {
    location: location
    vnetId: vnet.outputs.id
    subnetName: 'AzureBastionSubnet'
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

module cosmos './cosmosdb/cosmosdb.bicep' = {
  name: 'cosmosdb-module'
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
    cosmosDbName: cosmos.outputs.name
  }
}

resource camera_control 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'camera-control'
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
        appId: 'camera-control'
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/aca-camera-control'
          name: 'camera-control'
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

resource notification 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'notification-service'
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
        appId: 'notification-service'
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/aca-camera-notification'
          name: 'notification-service'
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

resource camera 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'camera-service'
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
        appId: 'camera-service'
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/aca-camera-service'
          name: 'camera-service'
          env: []
          resources: {
            cpu: '0.5'
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '5'
              }
            }
          }
        ]
      }
    }
  }
}

resource camera_simulator 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'camera-simulator'
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: aca_environment.outputs.id
    configuration: {
      secrets: []
      dapr: {
        enabled: true
        appId: 'camera-simulator'
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/aca-camera-simulator'
          name: 'camera-simulator'
          env: []
          resources: {
            cpu: '1'
            memory: '2Gi'
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
