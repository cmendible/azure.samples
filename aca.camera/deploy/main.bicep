@description('Specifies the location for resources.')
param location string = resourceGroup().location
param mi_name string = 'mi-cae'
param storage_name string = 'st${uniqueString(resourceGroup().id)}'
param evh_name string = 'daprevh'

module mi './mi/mi.bicep' = {
  name: 'mi-module'
  params: {
    location: location
    name: mi_name
  }
}

module vnet './vnet/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    location: location
  }
}

module kv './kv/kv.bicep' = {
  name: 'kv-module'
  params: {
    location: location
    mi_objectId: mi.outputs.object_id
  }
}

module firewall './firewall/firewall.bicep' = {
  name: 'firewall-module'
  params: {
    location: location
    keyVaultName: kv.outputs.name
    virtualNetworkName: vnet.outputs.name
  }
}

module bastion './bastion/bastion.bicep' = {
  name: 'bastion-module'
  params: {
    location: location
    vnetName: vnet.outputs.name
    subnetName: 'AzureBastionSubnet'
  }
}

module vm './vm/vm.bicep' = {
  name: 'vm-module'
  params: {
    location: location
    vnetName: vnet.outputs.name
    subnetName: 'jumpbox'
  }
}

module storage './storage/storage.bicep' = {
  name: 'storage-module'
  params: {
    location: location
    storageName: storage_name
    keyVaultName: kv.outputs.name
  }
}

module evh './evh/evh.bicep' = {
  name: 'evh-module'
  params: {
    location: location
    evhName: evh_name
    keyVaultName: kv.outputs.name
  }
}

module cosmos './cosmosdb/cosmosdb.bicep' = {
  name: 'cosmosdb-module'
  params: {
    location: location
    keyVaultName: kv.outputs.name
  }
}

module aca_environment './aca/aca_environment.bicep' = {
  name: 'aca_environment-module'
  params: {
    location: location
    keyVaultName: kv.outputs.name
    mi_client_id: mi.outputs.client_id
    vnetName: vnet.outputs.name
    vnetId: vnet.outputs.id
    accountName: storage.outputs.name
    cosmosDbName: cosmos.outputs.name
  }
  dependsOn: [
    firewall
  ]
}

resource camera_control 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: 'camera-control'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', mi_name)}': {}
    }
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
    workloadProfileName: 'Consumption'
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

resource notification 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: 'notification-service'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', mi_name)}': {}
    }
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
    workloadProfileName: 'Consumption'
    template: {
      containers: [
        {
          image: 'cmendibl3/aca-camera-notification'
          name: 'notification-service'
          env: [
            {
              name: 'EventHub'
              value: evh.outputs.evh_connection_string
            }
            {
              name: 'AzureWebJobsStorage'
              value: 'DefaultEndpointsProtocol=https;AccountName=${storage.outputs.name};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storage_name), '2021-08-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
            }
          ]
          resources: {
            cpu: '0.5'
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        rules: [
          {
            name: 'evh-based-scaling'
            custom: {
              type: 'azure-eventhub'
              metadata: {
                connectionFromEnv: 'EventHub'
                storageConnectionFromEnv: 'AzureWebJobsStorage'
                consumerGroup: 'notification-service'
                unprocessedEventThreshold: '2'
                blobContainer: 'subscribers'
                checkpointStrategy: 'dapr'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    storage
  ]
}

resource camera 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: 'camera-service'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', mi_name)}': {}
    }
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
    workloadProfileName: 'Consumption'
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

resource camera_simulator 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: 'camera-simulator'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', mi_name)}': {}
    }
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
    workloadProfileName: 'Consumption'
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
