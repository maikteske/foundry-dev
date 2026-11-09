provider "azurerm" {
  subscription_id = var.subscription_id

  # Migration/Plan soll keine Ressourcen-Provider registrieren (nur lesen).
  resource_provider_registrations = "none"

  features {}
}
