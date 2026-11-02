// RBAC: Managed-Identity der APIM-Instanz darf am bestehenden Foundry-Account
// inferieren (Cognitive Services OpenAI User). Wird mit module scope auf die
// Foundry-RG deployed, damit die Assignment auf den Account-Scope gehen kann.

targetScope = 'resourceGroup'

@description('Principal-ID der APIM-System-MI')
param principalId string

@description('Name des bestehenden Foundry-Accounts')
param accountName string = 'tbit-training-ai-103-pr-resource'

@description('Rollendefinition-GUID: Cognitive Services OpenAI User')
param openAiUserRoleId string = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: accountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(account.id, 'apim-openai-user')
  scope: account
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', openAiUserRoleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = roleAssignment.id
