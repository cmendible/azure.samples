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

module postgreSQL './postgre_sql/postgre_sql.bicep' = {
  name: 'postgreSQL-module'
  params: {
    location: location
    vnetId: vnet.outputs.id
    subnetName: 'endpoints'
  }
}

module aca_environment './aca/aca_environment.bicep' = {
  name: 'aca_environment-module'
  params: {
    location: location
    vnetId: vnet.outputs.id
  }
}

// https://github.com/Azure/azure-rest-api-specs/blob/09c4eba6c2d24c5f18226f36948d7987f3b50055/specification/app/resource-manager/Microsoft.App/preview/2022-01-01-preview/ContainerApps.json#L455
resource angular_app 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'angular-app'
  location: location
  identity: {
    //type: 'SystemAssigned'
    type: 'None'
  }
  properties: {
    managedEnvironmentId: aca_environment.outputs.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'acme101/angular-hello-world:develop'
          name: 'angular-hello-world'
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      dapr: {
        enabled: false
      }
    }
  }
}

resource java_front_app 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'java-front-app'
  location: location
  identity: {
    //type: 'SystemAssigned'
    type: 'None'
  }
  properties: {
    managedEnvironmentId: aca_environment.outputs.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: 'java-hello-world'
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
      dapr: {
        enabled: false
      }
    }
  }
}

resource java_back_app 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'java-back-app'
  location: location
  identity: {
    //type: 'SystemAssigned'
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
          name: 'your-super-secret'
          value: 'xyz'
        }
      ]
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: 'java-hello-world'
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
      dapr: {
        enabled: false
      }
    }
  }
}
