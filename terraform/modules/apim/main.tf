# APIM Standard v2 mit outbound VNet-Integration (vgl. infra/modules/apim.bicep).
# Wichtig: Standard v2 unterstützt KEINE VNet-Injection (internal), sondern nur
# inbound Private Endpoint (separates Modul) + outbound Integration ("External").
#
# Import-Matching (live verifiziert 2026-11-09):
#   - notification_sender_email: APIM-Default "apimgmt-noreply@mail.windowsazure.com"
#     wird von der API zurückgegeben → im Config setzen, sonst Perma-Diff.
#   - security-Block: alle Frontend/Backend-TLS/SSL30 + TripleDes168 = False
#     (Bicep-Custom-Properties + Plattform-Defaults deckungsgleich).
#   - protocols.enable_http2 = false deckt Custom-Property
#     "...Gateway.Protocols.Server.Http2" = "False" ab.
#   - developerPortalStatus/legacyPortalStatus ("Disabled") werden von azurerm
#     NICHT gemappt → kein Diff; werden bewusst nicht verwaltet (siehe Migration-Doku).

resource "azurerm_api_management" "this" {
  name                = var.apim_name
  location            = var.location
  resource_group_name = var.resource_group_name

  publisher_email = var.publisher_email
  publisher_name  = var.publisher_name

  sku_name = "StandardV2_1"

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = var.public_network_access == "Enabled"

  # Pflicht, sobald virtual_network_configuration gesetzt ist. StandardV2
  # unterstützt nur "External"; Subnet ist delegiert an Microsoft.Web/serverFarms
  # (vgl. Azure-Samples/AI-Gateway foundry-e2e-private).
  virtual_network_type = "External"

  virtual_network_configuration {
    subnet_id = var.apim_out_subnet_id
  }

  notification_sender_email = "apimgmt-noreply@mail.windowsazure.com"

  protocols {
    # neuere Attr-Namen (azurerm 4.x): http2_enabled statt enable_http2
    http2_enabled = false
  }

  security {
    frontend_ssl30_enabled = false
    frontend_tls10_enabled = false
    frontend_tls11_enabled = false

    backend_ssl30_enabled = false
    backend_tls10_enabled = false
    backend_tls11_enabled = false

    triple_des_ciphers_enabled = false
  }
}
