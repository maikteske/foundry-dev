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

// Objekt-ID des Admin-Logins (~/.azure-adm) fuer KV-Zertifikat-Importe.
// Ermittlung: az ad signed-in-user show --query id -o tsv (mit AZURE_CONFIG_DIR=~/.azure-adm)
param kvAdminObjectId = ''

param publisherEmail = 'maik.teske@googlemail.com'
param publisherName = 'Maik Teske'
