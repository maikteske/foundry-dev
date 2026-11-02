// APIM Standard v2 mit outbound VNet-Integration.
// Wichtig: Standard v2 unterstuetzt KEINE VNet-Injection (internal/external),
// sondern nur: inbound Private Endpoint (separates Modul) + outbound Integration.
// publicNetworkAccess wird per Parameter gesteuert (Two-Phase-Lockdown).

@description('Name der APIM-Instanz')
param apimName string

@description('Publisher-E-Mail (Pflichtfeld von APIM)')
param publisherEmail string

@description('Publisher-Name (Pflichtfeld von APIM)')
param publisherName string

@description('Subnet fuer outbound VNet-Integration (delegiert an Microsoft.Web/serverFarms)')
param apimOutSubnetId string

@description('Enabled beim ersten Deploy, Disabled nach PE-Anlage (Two-Phase-Lockdown)')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

resource apim 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: apimName
  location: resourceGroup().location
  sku: {
    name: 'StandardV2'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    publicNetworkAccess: publicNetworkAccess
    // Pflicht, sobald virtualNetworkConfiguration gesetzt ist. StandardV2
    // unterstuetzt nur 'External' (nicht Internal); Subnet ist delegiert an
    // Microsoft.Web/serverFarms (vgl. Azure-Samples/AI-Gateway foundry-e2e-private)
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: apimOutSubnetId
    }
    developerPortalStatus: 'Disabled'
    legacyPortalStatus: 'Disabled'
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
    }
  }
}

output apimId string = apim.id
output apimName string = apim.name
output apimPrincipalId string = apim.identity.principalId
output apimGatewayUrl string = apim.properties.gatewayUrl
