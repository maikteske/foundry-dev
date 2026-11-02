// VNet für das API-Gateway-Plattform-Skelett.
// Subnets: snet-appgw (Application Gateway v2, min /26),
//          snet-apim-out (APIM Standard v2 outbound VNet-Integration, min /27,
//                         Delegation Microsoft.Web/serverFarms - NICHT ApiManagement!),
//          snet-privatelink (Private Endpoint + optionaler Test-VM).

@description('Name des VNets')
param vnetName string

@description('AdresseSpace des VNets')
param addressPrefix string = '10.70.0.0/16'

@description('Prefix des Application-Gateway-Subnets')
param appgwSubnetPrefix string = '10.70.0.0/26'

@description('Prefix des APIM-outbound-Subnets')
param apimOutSubnetPrefix string = '10.70.0.64/27'

@description('Prefix des Private-Endpoint-Subnets')
param privatelinkSubnetPrefix string = '10.70.0.128/26'

var apimNsgName = '${vnetName}-snet-apim-out-nsg'

// NSG fuer das APIM-Subnet (Pflicht laut MS-Doku fuer VNet-Integration).
// Explizite Outbound-Erlaubnis fuer Azure Key Vault (APIM-Abhaengigkeit).
resource apimNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: apimNsgName
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'Allow-AzureKeyVault-Out'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [
      {
        name: 'snet-appgw'
        properties: {
          addressPrefix: appgwSubnetPrefix
        }
      }
      {
        name: 'snet-apim-out'
        properties: {
          addressPrefix: apimOutSubnetPrefix
          networkSecurityGroup: {
            id: apimNsg.id
          }
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'snet-privatelink'
        properties: {
          addressPrefix: privatelinkSubnetPrefix
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output appgwSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'snet-appgw')
output apimOutSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'snet-apim-out')
output privatelinkSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'snet-privatelink')
