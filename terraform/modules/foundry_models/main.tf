# Model-Deployments am bestehenden Foundry-Account (vgl. infra/main.bicep).
# Der Account selbst bleibt Portal-verwaltet und wird nur referenziert
# (Root: data.azurerm_cognitive_account).
#
# Import-Matching (live verifiziert 2026-11-09):
#   - rai_policy_name: live "Microsoft.DefaultV2". Der API-Default wäre
#     "Microsoft.Default" → explizit setzen, sonst Perma-Diff.
#   - version_upgrade_option: live OnceNewDefaultVersionAvailable (= azurerm-Default).

resource "azurerm_cognitive_deployment" "this" {
  for_each = var.deployments

  name                 = each.key
  cognitive_account_id = var.account_id

  rai_policy_name        = var.rai_policy_name
  version_upgrade_option = var.version_upgrade_option

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }
}
