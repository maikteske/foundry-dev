// Plattform-API-Gateway: APIM Standard v2 + Private Endpoint + App Gateway WAF v2.
// Deploy mit: mise run platform:bootstrap (ohne AppGW, wegen KV-Zertifikat-Reihenfolge)
//         -> mise run cert:issue + cert:import
//         -> mise run platform:deploy (voll)
//         -> mise run platform:lockdown (publicNetworkAccess=Disabled)
targetScope = 'resourceGroup'

@description('Azure-Region')
param location string = 'swedencentral'

@description('Name der APIM-Instanz')
param apimName string = 'tbi-apim-exam-ai-103'

@description('Name des VNets')
param vnetName string = 'tbi-vnet-exam-ai-103-platform'

@description('Name des Key Vaults')
param keyVaultName string = 'tbi-kv-ai103plat'

@description('Name des Application Gateways')
param appGwName string = 'tbi-agw-exam-ai-103'

@description('Name der oeffentlichen App-GW-IP')
param appGwPublicIpName string = 'tbi-pip-agw-exam-ai-103'

@description('DNS-Label der App-GW-Public-IP (CNAME-Ziel)')
param appGwDnsLabel string = 'tbi-agw-exam-ai-103'

@description('Public-Hostname des Gateways (Cloudflare CNAME-Ziel)')
param appgwHostname string = 'api.maikteske.dev'

@description('Enabled beim ersten Deploy, Disabled nach PE (Two-Phase-Lockdown)')
@allowed([
  'Enabled'
  'Disabled'
])
param apimPublicNetworkAccess string = 'Enabled'

@description('App Gateway in diesem Deploy anlegen? (false beim Bootstrap, KV-Zertifikat fehlt dann noch)')
param deployAppGw bool = true

@description('Optional Test-VM in snet-privatelink deployen')
param deployTestVm bool = false

@description('Entra-Objekt-ID des Admin-Kontos fuer KV-Zertifikat-Imports (leer = keine Admin-Politik)')
param kvAdminObjectId string = ''

@description('Publisher-E-Mail der APIM-Instanz')
param publisherEmail string = 'maik.teske@googlemail.com'

@description('Publisher-Name der APIM-Instanz')
param publisherName string = 'Maik Teske'

@description('RG des bestehenden Foundry-Accounts (fuer RBAC)')
param foundryRgName string = 'tbi-rg-exam-ai-103-mte'

@description('Name des bestehenden Foundry-Accounts (fuer RBAC)')
param foundryAccountName string = 'tbit-training-ai-103-pr-resource'


module vnet 'modules/vnet.bicep' = {
  name: 'platform-vnet'
  params: {
    vnetName: vnetName
  }
}

module apim 'modules/apim.bicep' = {
  name: 'platform-apim'
  params: {
    apimName: apimName
    publisherEmail: publisherEmail
    publisherName: publisherName
    apimOutSubnetId: vnet.outputs.apimOutSubnetId
    publicNetworkAccess: apimPublicNetworkAccess
  }
}

module privateEndpoint 'modules/apim-privateendpoint.bicep' = {
  name: 'platform-pe'
  params: {
    apimId: apim.outputs.apimId
    apimName: apimName
    subnetId: vnet.outputs.privatelinkSubnetId
    vnetId: vnet.outputs.vnetId
  }
}

// RBAC: APIM-MI darf am Foundry-Account inferieren (cross-RG scope)
module foundryRbac 'modules/foundry-rbac.bicep' = {
  name: 'platform-foundry-rbac'
  scope: resourceGroup(foundryRgName)
  params: {
    principalId: apim.outputs.apimPrincipalId
    accountName: foundryAccountName
  }
}

module keyVaultCert 'modules/keyvault-appgw-cert.bicep' = {
  name: 'platform-kv-cert'
  params: {
    keyVaultName: keyVaultName
    kvAdminObjectId: kvAdminObjectId
  }
}

module appGw 'modules/appgw.bicep' = if (deployAppGw) {
  name: 'platform-appgw'
  params: {
    appGwName: appGwName
    publicIpName: appGwPublicIpName
    publicIpDnsLabel: appGwDnsLabel
    hostname: appgwHostname
    subnetId: vnet.outputs.appgwSubnetId
    identityId: keyVaultCert.outputs.appGwIdentityId
    certSecretUri: keyVaultCert.outputs.certSecretUri
    backendFqdn: '${apimName}.azure-api.net'
  }
}

module testVm 'modules/testvm.bicep' = if (deployTestVm) {
  name: 'platform-testvm'
  params: {
    deployTestVm: deployTestVm
    subnetId: vnet.outputs.privatelinkSubnetId
  }
}

@description('Gateway-URL der APIM-Instanz')
output apimGatewayUrl string = apim.outputs.apimGatewayUrl

@description('APIM-System-MI Principal-ID (fuer Fabric-Workspace-Membership)')
output apimPrincipalId string = apim.outputs.apimPrincipalId

@description('IP des Private Endpoints')
output peIp string = privateEndpoint.outputs.peIp

@description('Registrierter privatelink-FQDN')
output peFqdn string = privateEndpoint.outputs.registeredFqdn

@description('FQDN der App-GW-Public-IP (Cloudflare-CNAME-Ziel)')
output appGwFqdn string = deployAppGw ? '${appGwDnsLabel}.${location}.cloudapp.azure.com' : ''

@description('Name des Key Vaults')
output keyVaultName string = keyVaultCert.outputs.keyVaultName
