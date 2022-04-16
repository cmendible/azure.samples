@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Specifies the VNET.')
param vnetId string

@description('Specifies the Subnet.')
param subnetName string

@description('Specifies the user name.')
param user_name string = 'azadmin'

resource vm_nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: 'vm-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfiguration'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnetId}/subnets/${subnetName}'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

resource jumpbox 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'jumpbox'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        osType: 'Windows'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '19H1-ent'
        version: '18362.1198.2011031735'
      }
    }
    osProfile: {
      computerName: 'testcomputer'
      adminUsername: user_name
      adminPassword: 'Aca123456.'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm_nic.id
        }
      ]
    }
  }
}
