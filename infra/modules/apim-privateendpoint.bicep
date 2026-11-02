// Private Endpoint (sub-resource 'Gateway') auf die APIM-Instanz
// + Private DNS Zone privatelink.azure-api.net mit A-Record und VNet-Link.
// Der Public-Hostname <apim>.azure-api.net wird per CNAME auf
// <apim>.privatelink.azure-api.net gefuehrt -> Clients im VNet (Zone gelinkt)
// resolven die PE-IP, alle anderen den oeffentlichen Endpunkt (bzw. nach
// Lockdown: niemand).

@description('Ressourcen-ID der APIM-Instanz')
param apimId string

@description('Name der APIM-Instanz (fuer PE-Verbindungsname)')
param apimName string

@description('Subnet fuer den Private Endpoint')
param subnetId string

@description('VNet-ID fuer den DNS-Zonen-Link')
param vnetId string

@description('Name der Private-DNS-Zone')
param dnsZoneName string = 'privatelink.azure-api.net'

var peName = 'pe-${apimName}-gateway'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: peName
  location: resourceGroup().location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${apimName}-gateway-connection'
        properties: {
          privateLinkServiceId: apimId
          groupIds: [
            'Gateway'
          ]
        }
      }
    ]
  }
}

// Registrierter FQDN ist deterministisch: <apim>.privatelink.azure-api.net,
// also A-Record mit relativen Namen <apim> in der Zone privatelink.azure-api.net
// (Name muss zur Deploy-Zeit berechenbar sein, die PE-IP nicht)
var registeredFqdn = '${apimName}.${dnsZoneName}'
var aRecordName = apimName
var peIp = privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
}

resource aRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: dnsZone
  name: aRecordName
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: peIp
      }
    ]
  }
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZone
  name: '${apimName}-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

output peId string = privateEndpoint.id
output peIp string = peIp
output registeredFqdn string = registeredFqdn
