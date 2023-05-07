@description('Specifies the VNET.')
param vnetId string

@description('Specifies the Azure Container App FQDN.')
param fqdn string

@description('Specifies the Azure Container App Load Balancer IP.')
param staticIP string

// Create the Private DNS Zone
resource aca_dns 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: fqdn
  location: 'global'
}

// Create A record pointing all subdomains to the Azure Container App Static IP
resource a_record 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '*'
  parent: aca_dns
  properties: {
    aRecords: [
      {
        ipv4Address: staticIP
      }
    ]
    ttl: 3600
  }
}

// Link the Private DNS Zone with the VNET
resource vnet_dns_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: aca_dns
  name: 'private-network'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}
