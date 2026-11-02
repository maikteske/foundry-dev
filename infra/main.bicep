targetScope = 'resourceGroup'

// Verwaltet Model-Deployments am bestehenden Foundry-Account.
// Der Account selbst bleibt Portal-verwaltet und wird nur referenziert.

@description('Name des bestehenden Foundry-Accounts (Microsoft.CognitiveServices/accounts)')
param accountName string = 'tbit-training-ai-103-pr-resource'

@description('Zu erstellende Model-Deployments. name = Deployment-Name in der API, modelName/version = zugrundeliegendes Modell')
param deployments array = [
  {
    name: 'gpt-5-mini'
    modelName: 'gpt-5-mini'
    modelVersion: '2025-08-07'
    skuName: 'GlobalStandard'
    capacity: 50
  }
]

@description('Verhalten bei neuen Modellversionen: OnceNewDefaultVersionAvailable = automatisches Upgrade, OnceCurrentVersionExpired = Upgrade erst bei Ablauf')
@allowed([
  'OnceCurrentVersionExpired'
  'OnceNewDefaultVersionAvailable'
])
param versionUpgradeOption string = 'OnceNewDefaultVersionAvailable'

resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: accountName
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = [for d in deployments: {
  parent: account
  name: d.name
  sku: {
    name: d.skuName
    capacity: d.capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: d.modelName
      version: d.modelVersion
    }
    versionUpgradeOption: versionUpgradeOption
  }
}]

@description('Endpoint des Foundry-Accounts')
output accountEndpoint string = account.properties.endpoint

@description('IDs der erstellten Deployments')
output deploymentIds array = [for d in deployments: resourceId('Microsoft.CognitiveServices/accounts/deployments', accountName, d.name)]
