@description('Specifies the location for resources.')
param location string = resourceGroup().location

// Create VNET
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'container-apps-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: 'controlplane'
        properties: {
          addressPrefix: '10.240.0.0/16'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'apps'
        properties: {
          addressPrefix: '10.241.0.0/16'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'endpoints'
        properties: {
          addressPrefix: '10.242.0.0/16'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'jumpbox'
        properties: {
          addressPrefix: '10.243.0.0/16'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

output id string = vnet.id
