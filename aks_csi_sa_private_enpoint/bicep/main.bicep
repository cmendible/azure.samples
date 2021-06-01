param sa_name string = 'akscsisa'
param aks_name string = 'akscsimsft'

// Create VNET
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'private-network'
  location: 'westeurope'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: 'endpoint'
        properties: {
          addressPrefix: '10.241.0.0/16'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'aks'
        properties: {
          addressPrefix: '10.240.0.0/16'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

// Create the File Storage Account
resource sa 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: sa_name
  location: 'westeurope'
  sku: {
    name: 'Premium_LRS'
    tier: 'Premium'
  }
  kind: 'FileStorage'
  properties: {
    minimumTlsVersion: 'TLS1_0'
    allowBlobPublicAccess: false
    isHnsEnabled: false
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

// Create the private enpoint
resource private_endpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: 'sa-endpoint'
  location: 'westeurope'
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'sa-privateserviceconnection'
        properties: {
          privateLinkServiceId: sa.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnet.id}/subnets/endpoint'
    }
  }
}

// Create the Private DNS Zone
resource dns 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.file.core.windows.net'
  location: 'global'
}

// Link the Private DNS Zone with the VNET
resource vnet_dns_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${dns.name}/test'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Create Private DNS Zone Group 
resource dns_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${private_endpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-core-windows-net'
        properties: {
          privateDnsZoneId: dns.id
        }
      }
    ]
  }
}

// Create AKS cluster
resource aks 'Microsoft.ContainerService/managedClusters@2021-02-01' = {
  name: aks_name
  location: 'westeurope'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.19.9'
    dnsPrefix: aks_name
    agentPoolProfiles: [
      {
        name: 'default'
        count: 1
        vmSize: 'Standard_D2s_v3'
        osDiskSizeGB: 30
        osDiskType: 'Ephemeral'
        vnetSubnetID: '${vnet.id}/subnets/aks'
        type: 'VirtualMachineScaleSets'
        orchestratorVersion: '1.19.9'
        osType: 'Linux'
        mode: 'System'
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      kubeDashboard: {
        enabled: false
      }
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'kubenet'
      networkPolicy: 'calico'
      loadBalancerSku: 'standard'
      podCidr: '10.244.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
  }
}

// Built-in Role Definition IDs
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var contributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

// Set AKS kubelet Identity as SA Contributor
resource aks_kubelet_sa_contributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('${aks_name}_kubelet_sa_contributor')
  scope: sa
  properties: {
    principalId: reference(aks.id, '2021-02-01', 'Full').properties.identityProfile['kubeletidentity'].objectId
    roleDefinitionId: contributor
  }
}
