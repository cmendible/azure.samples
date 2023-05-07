@description('Specifies the location for resources.')
param location string = resourceGroup().location
@description('Managed Identity Name')
param name string = resourceGroup().location

resource mi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: {}
}

output name string = mi.name
output id string = mi.id
output client_id string = mi.properties.clientId
output object_id string = mi.properties.principalId
