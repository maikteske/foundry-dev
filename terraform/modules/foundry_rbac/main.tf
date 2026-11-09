# RBAC: Managed-Identity der APIM-Instanz darf am bestehenden Foundry-Account
# inferieren (Cognitive Services OpenAI User, vgl. infra/modules/foundry-rbac.bicep).
#
# Import-Matching:
#   - role_assignment_name = fixe GUID von Bicep guid(account.id,'apim-openai-user')
#     → importierbar und ForceNew-sicher (ohne Name würde TF eine Zufalls-GUID
#       erzeugen und beim Plan ein Replace wollen).
#   - principal_type = "ServicePrincipal" (live so zurückgegeben).

resource "azurerm_role_assignment" "apim_openai_user" {
  name               = var.role_assignment_name
  scope              = var.account_id
  role_definition_id = var.role_definition_id
  principal_id       = var.principal_id
  principal_type     = "ServicePrincipal"
}
