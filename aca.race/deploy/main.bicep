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

resource race_control 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'race-control'
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
        appId: 'race-control'
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/aca-race-control'
          name: 'race-control'
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

resource check_point 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'check-point'
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
        appId: 'check-point'
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/aca-check-point'
          name: 'check-point'
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

resource runner 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'runner-service'
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
        appId: 'runner-service'
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/aca-runner-service'
          name: 'runner-service'
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

resource race_simulator 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'race-simulator'
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
        appId: 'race-simulator'
      }
    }
    template: {
      containers: [
        {
          image: 'cmendibl3/aca-race-simulator'
          name: 'race-simulator'
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
