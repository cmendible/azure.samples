@description('Specifies the location for resources.')
param location string = resourceGroup().location
param firewall_private_ip string = '10.240.0.4'

resource udr 'Microsoft.Network/routeTables@2022-07-01' = {
  name: 'egress'
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: firewall_private_ip
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

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
        name: 'AzureFirewallSubnet'
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
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: udr.id
          }
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
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.24.0.0/27'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

output id string = vnet.id
output name string = vnet.name
