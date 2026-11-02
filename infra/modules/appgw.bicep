// Application Gateway v2 mit WAF (OWASP CRS) vor der APIM-Instanz.
// TLS-Terminierung mit dem LE-Zertifikat aus Key Vault (User-MI mit get).
// Backend = APIM-Gateway-FQDN; die Auflösung läuft über den CNAME auf
// <apim>.privatelink.azure-api.net -> A-Record (PE-IP) in der privaten Zone,
// die an das VNet gelinkt ist (AppGW v2 nutzt VNet-gelinkte private Zonen).

@description('Name des Application Gateways')
param appGwName string

@description('Name der oeffentlichen IP')
param publicIpName string

@description('DNS-Label der oeffentlichen IP (CNAME-Ziel: <label>.<region>.cloudapp.azure.com)')
param publicIpDnsLabel string

@description('Hostname des HTTPS-Listeners (z. B. api.maikteske.dev)')
param hostname string

@description('Subnet-ID fuer das App Gateway (nur AppGW, min /26)')
param subnetId string

@description('Ressourcen-ID der User-Managed-Identity (liest KV-Zertifikat)')
param identityId string

@description('Versionless Secret-URI des KV-Zertifikats (https://<kv>.vault.azure.net/secrets/<name>)')
param certSecretUri string

@description('FQDN des APIM-Gateways als Backend (z. B. <apim>.azure-api.net)')
param backendFqdn string

@description('Name des KV-Zertifikats (fuer Ressourcenverweise)')
param certName string = 'appgw-tls'

@description('Health-Probe-Pfad der APIM-Instanz')
param probePath string = '/status-0123456789abcdef'

var backendPoolName = 'pool-${backendFqdn}'
var backendHttpSettingsName = 'https-to-apim'
var httpListenerName = 'https-${hostname}'
var probeName = 'probe-apim-status'
var frontendPortName = 'port-443'
var ruleName = 'route-to-apim'

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: publicIpDnsLabel
    }
  }
}

resource appGw 'Microsoft.Network/applicationGateways@2024-05-01' = {
  name: appGwName
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'gwipconfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontend-public'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPortName
        properties: {
          port: 443
        }
      }
    ]
    sslCertificates: [
      {
        name: certName
        properties: {
          keyVaultSecretId: certSecretUri
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: backendFqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendHttpSettingsName
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 120
          // Host-Header + SNI aus dem Backend-FQDN (<apim>.azure-api.net)
          pickHostNameFromBackendAddress: true
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwName, probeName)
          }
        }
      }
    ]
    probes: [
      {
        name: probeName
        properties: {
          protocol: 'Https'
          host: backendFqdn
          path: probePath
          interval: 30
          timeout: 15
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
        }
      }
    ]
    httpListeners: [
      {
        name: httpListenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'frontend-public')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, frontendPortName)
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwName, certName)
          }
          hostName: hostname
        }
      }
    ]
    requestRoutingRules: [
      {
        name: ruleName
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, httpListenerName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, backendPoolName)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwName, backendHttpSettingsName)
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
    }
  }
}

output publicIpFqdn string = publicIp.properties.dnsSettings.fqdn
output publicIp string = publicIp.properties.ipAddress
output appGwId string = appGw.id
