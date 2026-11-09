# Application Gateway v2 mit WAF (OWASP CRS) vor der APIM-Instanz
# (vgl. infra/modules/appgw.bicep). TLS-Terminierung mit dem LE-Zertifikat
# aus Key Vault (User-MI mit get). Backend = APIM-Gateway-FQDN; die Auflösung
# läuft über den CNAME auf <apim>.privatelink.azure-api.net → A-Record
# (PE-IP) in der privaten Zone, die an das VNet gelinkt ist (AppGW v2 nutzt
# VNet-gelinkte private Zonen).
#
# Import-Matching (live verifiziert 2026-11-09):
#   - sslPolicy/autoscaleConfiguration live null → nicht setzen
#     (sku.capacity = 1 entspricht dem Live-Stand),
#   - WAF-Policy als eigene Ressource (inline webApplicationFirewallConfiguration
#     am Gateway ist retired: ApplicationGatewayWafConfigurationDeprecated),
#   - Unternamen 1:1 aus Bicep (gwipconfig, frontend-public, port-443, appgw-tls,
#     pool-<fqdn>, https-to-apim, https-<host>, probe-apim-status, route-to-apim).

locals {
  backend_pool_name     = "pool-${var.backend_fqdn}"
  backend_http_settings = "https-to-apim"
  http_listener_name    = "https-${var.hostname}"
  probe_name            = "probe-apim-status"
  frontend_port_name    = "port-443"
  rule_name             = "route-to-apim"
}

resource "azurerm_public_ip" "this" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku               = "Standard"
  sku_tier          = "Regional"
  allocation_method = "Static"
  # idle_timeout: azurerm-Default 4 Minuten == Live-Wert

  domain_name_label = var.public_ip_dns_label
}

# WAF-Policy als eigene Ressource. requestBodyInspectLimitInKB wird von
# azurerm gemappt (Default 128!) und muss explizit auf den Live-Wert 2000,
# fileUploadEnforcement / requestBodyEnforcement werden NICHT gemappt
# (kein Diff, Plattform-Defaults).
resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.appgw_name}-wafpolicy"
  location            = var.location
  resource_group_name = var.resource_group_name

  policy_settings {
    enabled            = true
    mode               = "Prevention"
    request_body_check = true
    # Max. erlaubter Wert (2 MB) - Daten-/GraphQL-APIs mit größeren Bodies
    max_request_body_size_in_kb = 2000
    # azurerm-Default wäre 128 — Live-Stand ist 2000 (Bicep), sonst Diff
    request_body_inspect_limit_in_kb = 2000
  }

  managed_rules {
    managed_rule_set {
      # azurerm >= 4.x: type/version (statt rule_set_type/rule_set_version)
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "this" {
  name                = var.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gwipconfig"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "frontend-public"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  ssl_certificate {
    name = var.cert_name
    # Versionless Secret-URI → Auto-Update bei KV-Rotation
    key_vault_secret_id = var.cert_secret_uri
  }

  backend_address_pool {
    name  = local.backend_pool_name
    fqdns = [var.backend_fqdn]
  }

  probe {
    name                = local.probe_name
    protocol            = "Https"
    host                = var.backend_fqdn
    path                = var.probe_path
    interval            = 30
    timeout             = 15
    unhealthy_threshold = 3

    pick_host_name_from_backend_http_settings = false

    # Live-Stand (match.statusCodes = ["200-399"]) — ohne match-Block würde
    # TF die Match-Bedingung entfernen und den Default (200-399 intern?)
    # vs. Live vergleichen.
    match {
      status_code = ["200-399"]
    }
  }

  backend_http_settings {
    name                  = local.backend_http_settings
    port                  = 443
    protocol              = "Https"
    cookie_based_affinity = "Disabled"
    request_timeout       = 120

    # Host-Header + SNI aus dem Backend-FQDN (<apim>.azure-api.net)
    pick_host_name_from_backend_address = true

    probe_name = local.probe_name
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = "frontend-public"
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Https"
    ssl_certificate_name           = var.cert_name
    host_name                      = var.hostname
  }

  request_routing_rule {
    name                       = local.rule_name
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_pool_name
    backend_http_settings_name = local.backend_http_settings
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.this.id
}
