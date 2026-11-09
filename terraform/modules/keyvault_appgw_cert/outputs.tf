output "appgw_identity_id" {
  value = azurerm_user_assigned_identity.appgw.id
}

output "appgw_identity_client_id" {
  value = azurerm_user_assigned_identity.appgw.client_id
}

output "keyvault_name" {
  value = azurerm_key_vault.this.name
}

output "cert_secret_uri" {
  # Versionless Secret-URI (ohne Version) — identisch zu Bicep certSecretUri.
  # Versionless bewusst: AppGW zieht Zertifikats-Rotationen automatisch.
  value = "${azurerm_key_vault.this.vault_uri}secrets/${var.cert_name}"
}
