@description('Specifies the location for resources.')
param location string = resourceGroup().location
@description('Azure Firewall name')
param firewallName string = 'fw${uniqueString(resourceGroup().id)}'
param firewallPolicyName string = '${firewallName}-firewallPolicy'
param virtualNetworkName string
@description('Key Vault Name')
param keyVaultName string

var azureFirewallSubnetName = 'AzureFirewallSubnet'
var azureFirewallSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, azureFirewallSubnetName)
var azurepublicIpname = 'pip-fw'

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: azurepublicIpname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-01-01' = {
  name: firewallPolicyName
  location: location
  properties: {
    threatIntelMode: 'Alert'
    dnsSettings: {
      enableProxy: true
    }
  }
}

resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'cae-netowork-rules'
        priority: 1250
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'to-dns'
            ipProtocols: [
              'TCP'
            ]
            // destinationFqdns: [
            //   'MicrosoftContainerRegistry'
            //   'AzureFrontDoor.FirstParty'
            //   'AzureContainerRegistry'
            //   'AzureKeyVault'
            //   'AzureActiveDirectory'
            //   'AzureCloud.WestEurope'
            //   'AzureMonitor'
            // ]
            sourceAddresses: [
              '*'
            ]
            destinationPorts: [
              '53'
            ]
            destinationAddresses: [
              '*'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'to-internet'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationPorts: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-03-01' = {
  name: firewallName
  location: location
  zones: null
  dependsOn: [
    networkRuleCollectionGroup
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'AzureFirewallIpConfiguration'
        properties: {
          subnet: {
            id: azureFirewallSubnetId
          }
          publicIPAddress: {
            id: publicIpAddress.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

output private_ip string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
