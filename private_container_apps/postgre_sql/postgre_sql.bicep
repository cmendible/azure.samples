@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Specifies the VNET.')
param vnetId string

@description('Specifies the Subnet.')
param subnetName string

resource postgre_sql 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: 'cfmacadb1306'
  location: location
  sku: {
    name: 'GP_Gen5_2'
  }
  properties: {
    createMode: 'Default'
    administratorLogin: 'cmendible'
    administratorLoginPassword: 'Aca123456.'
    version: '11'
  }
}

resource postgre_private_endpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: 'db-endpoint'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'db-privateserviceconnection'
        properties: {
          privateLinkServiceId: postgre_sql.id
          groupIds: [
            'postgresqlServer'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnetId}/subnets/${subnetName}'
    }
  }
}

// Create the Private DNS Zone
resource postgre_dns 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.postgres.database.azure.com'
  location: 'global'
}

// Link the Private DNS Zone with the VNET
resource vnet_dns_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${postgre_dns.name}/private-network'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Create Private DNS Zone Group 
resource postgre_dns_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${postgre_private_endpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.postgres.database.azure.com'
        properties: {
          privateDnsZoneId: postgre_dns.id
        }
      }
    ]
  }
}
