terraform {
  # Versions-Pin korrespondiert mit mise [tools] terraform = "1.12.2" (siehe ../mise.toml)
  required_version = ">= 1.12.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.57.0"
    }
  }

  # Remote-Backend: BEWUSST (noch) AUSKOMMENTIERT.
  # Grund: Ein deklarierter backend-Block erzwingt Backend-Initialisierung
  # (`terraform plan` bricht sonst mit "Backend initialization required" ab);
  # der azurerm-Backend-Init wiederum verlangt einen existierenden Storage-Account
  # (storage_account_name ist Pflicht) — der laut Migrations-Spezifikation NICHT
  # angelegt werden durfte. Lokal läuft der State daher als Local-Backend
  # (terraform/terraform.tfstate, gitignored).
  # Reaktivierung sobald der State-Storage steht (Vorlage: backend.hcl.example):
  #   1. Block unten entkommentieren
  #   2. terraform init -backend-config=backend.hcl -migrate-state
  #  (Vor Aktivierung auskommentiert lassen, sonst schlaegt `terraform plan`
  #   mit Local-State fehl — siehe docs/terraform-migration.md, Abschnitt State.)
  # backend "azurerm" {}
}

# Entcheidung azurerm vs. azapi (siehe docs/terraform-migration.md):
# azurerm 4.57.0 bildet APIM StandardV2 vollstaedig ab:
#   - sku_name = "StandardV2_1" ist ein gueltiger SKU-Wert,
#   - virtual_network_type = "External" + virtual_network_configuration.subnet_id
#     sind nicht an klassische SKUs gebunden (Passthrough an die ARM-API,
#     die External-Integration fuer StandardV2 akzeptiert),
#   - security-Block deckt die TLS-Custom-Properties ab, protocols.enable_http2
#     deckt "...Gateway.Protocols.Server.Http2" ab.
# azapi wird daher NICHT benoetigt. (github.com/hashicorp/terraform-provider-azurerm
# issue #30296 betrifft nur "Internal"-Injection auf StandardV2, nicht External.)
