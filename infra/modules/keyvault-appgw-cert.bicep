// Key Vault fuer das App-Gateway-TLS-Zertifikat (Let's Encrypt).
// Das Modul legt NUR Vault + User-MI + Zugriffspolitik an; das Zertifikat
// selbst wird extern per `mise run cert:issue` (DNS-01 via Cloudflare)
// erzeugt und mit `az keyvault certificate import` hochgeladen.
// Bewusst KEIN Cloudflare-Origin-CA-Zertifikat hier - nur ein kurzlebiges,
// oeffentlich vertrauenswuerdiges LE-Zertifikat.

@description('Name des Key Vaults')
param keyVaultName string

@description('Name der User-Manged-Identity fuer das App Gateway')
param appGwIdentityName string = 'tbi-mi-agw-exam-ai-103'

@description('Entra-Objekt-ID des Admin-Kontos, das Zertifikate importieren darf (leer = keine Admin-Politik)')
param kvAdminObjectId string = ''

@description('Prefix fuer das App-Gateway-Zertifikat im KV')
param certName string = 'appgw-tls'

resource appGwIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: appGwIdentityName
  location: resourceGroup().location
}

// Access-Policy-Modell (kein RBAC-Modell) - einfach fuer eine Identity.
// App-GW-MI: nur secrets/get (Pflicht fuer KV-Zertifikat-Integration).
var policies = [
  {
    tenantId: subscription().tenantId
    objectId: appGwIdentity.properties.principalId
    permissions: {
      secrets: [
        'get'
      ]
    }
  }
]

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: empty(kvAdminObjectId) ? policies : union(policies, [
      {
        tenantId: subscription().tenantId
        objectId: kvAdminObjectId
        permissions: {
          certificates: [
            'get'
            'list'
            'create'
            'import'
            'delete'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
          ]
        }
      }
    ])
  }
}

output appGwIdentityId string = appGwIdentity.id
output appGwIdentityClientId string = appGwIdentity.properties.clientId
output keyVaultName string = keyVault.name
output certSecretUri string = '${keyVault.properties.vaultUri}secrets/${certName}'
