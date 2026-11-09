# Key Vault für das App-Gateway-TLS-Zertifikat (vgl. infra/modules/keyvault-appgw-cert.bicep).
# Das Modul legt NUR Vault + User-MI + Zugriffspolitik an; das Zertifikat
# selbst wird extern per `mise run cert:issue` (DNS-01 via Cloudflare)
# erzeugt und mit `az keyvault certificate import` hochgeladen.
# Bewusst KEIN Cloudflare-Origin-CA-Zertifikat hier — nur ein kurzlebiges,
# öffentlich vertrauenswürdiges LE-Zertifikat.
#
# Import-Matching (live verifiziert 2026-11-09): Soft-Delete 90d, keine
# Purge-Protection, kein RBAC-Modell, Public Network Access Enabled —
# alles azurerm-Defaults.

resource "azurerm_user_assigned_identity" "appgw" {
  name                = var.appgw_identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Access-Policy-Modell (kein RBAC-Modell).
# 1) App-GW-MI: nur secrets/get (Pflicht für KV-Zertifikat-Integration).
# 2) Admin (kv_admin_object_id): Zertifikat-Importe + Secret-Liste.
resource "azurerm_key_vault" "this" {
  name                = var.keyvault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = azurerm_user_assigned_identity.appgw.principal_id

    secret_permissions = ["Get"]
  }

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.kv_admin_object_id

    certificate_permissions = ["Get", "List", "Create", "Import", "Delete"]
    secret_permissions      = ["Get", "List", "Set", "Delete"]
  }
}
