using 'platform.bicep'

// Region der Platform-RG (swedencentral)
param location = 'swedencentral'

// Two-Phase-Lockdown: Erst-Deploy 'Enabled', lockdown-Task ueberschreibt auf 'Disabled'
param apimPublicNetworkAccess = 'Enabled'

// App Gateway erst nach cert:issue/cert:import aktivieren;
// platform:bootstrap-Task startet mit deployAppGw = false
param deployAppGw = true

param appgwHostname = 'api.maikteske.dev'

param deployTestVm = false

// Objekt-ID des Admin-Logins (~/.azure-adm) fuer KV-Zertifikat-Importe:
// adm-mteske@teambusinessit.de (via Activity-Log-Claims verifiziert)
param kvAdminObjectId = '723948da-3488-497b-a477-a5c5a5ae18c0'

param publisherEmail = 'maik.teske@googlemail.com'
param publisherName = 'Maik Teske'
