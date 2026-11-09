# Terraform-Migration (Bicep → Terraform, ohne Neuanlage)

Migration des Platform-API-Gateways von Bicep (`infra/*.bicep`) auf Terraform
(`terraform/`). Die laufenden Azure-Ressourcen wurden **nicht** neu angelegt,
sondern per `import`-Blöcken in den Terraform-State übernommen.

**Erfolgskriterium:** `terraform plan` zeigt **0 to add, 0 to change, 0 to
destroy** (bzw. nur dokumentierte, harmlose In-place-Änderungen). Kein
Replace/Destroy. In dieser Migration wurde **kein Apply** gefahren — nur
gelesen und geplant (lokaler State via `init -backend=false`).

**Erreicht (2026-11-09):** `Plan: 19 to import, 0 to add, 0 to change,
0 to destroy.` — Plan gespeichert (`terraform/tfplan`, gitignored).

## Vorgehen

1. Bicep-Quellen vollständig gelesen, 1:1-Mapping-Tabelle (unten).
2. Terraform-Code (`terraform/`) mit Root + 8 Modulen geschrieben.
3. Live-IDs gegen Azure verifiziert (Read-only, Admin-Profil
   `AZURE_CONFIG_DIR=~/.azure-adm`, Subscription TBIT Training).
4. `terraform fmt -recursive`, `terraform init -backend=false`,
   `terraform validate`, dann Plan-Iteration bis 0/0/0.
5. Bicep erst entfernen, wenn Plan grün — bis dahin bleibt `infra/` unangetastet.

## Struktur

```
terraform/
├── versions.tf          TF >= 1.12, azurerm = 4.57.0 (exakt); backend "azurerm" {} auskommentiert (siehe State)
├── providers.tf         subscription_id, resource_provider_registrations = "none"
├── variables.tf         Defaults 1:1 aus platform.bicep
├── main.tf              Wiring (RG, Data-Source Foundry, 8 Module)
├── imports.tf           alle verifizierten Import-IDs
├── outputs.tf           Bicep-Parität + vnet_id, Subnet-IDs, DNS-Zonen-ID
├── terraform.tfvars     Live-Stand (keine Secrets!)
├── backend.hcl.example  Vorlage Remote-Backend (Storage existiert bewusst nicht)
└── modules/
    ├── vnet/                  VNet, 3 Subnets, NSG (Allow-AzureKeyVault-Out)
    ├── apim/                  APIM StandardV2, External-VNet-Integration
    ├── apim_private_endpoint/ PE (Gateway) + privatelink-DNS-Zone/A-Record/VNet-Link
    ├── keyvault_appgw_cert/   KV + App-GW-User-MI + Access-Policies (Zertifikat extern)
    ├── appgw/                 PIP + WAF-Policy (eigene Ressource) + AppGW WAF_v2
    ├── foundry_rbac/          APIM-MI → OpenAI User am Foundry-Account
    ├── testvm/                optionale Jumpbox (count = deploy_test_vm)
    └── foundry_models/        azurerm_cognitive_deployment (for_each)
```

## Mapping-Tabelle (Bicep → Terraform → Import-ID)

| Bicep (infra/…) | Terraform | Import-ID (Subscription `5cef6e78-e33e-4ceb-855e-5d85f4debdd4`, live verifiziert 2026-11-09) |
| --- | --- | --- |
| platform.bicep: (implizites RG) | `azurerm_resource_group.platform` | `…/resourceGroups/tbi-rg-exam-ai-103-platform` |
| modules/vnet.bicep: apimNsg | `module.vnet.azurerm_network_security_group.apim_out` | `…/platform/providers/Microsoft.Network/networkSecurityGroups/tbi-vnet-exam-ai-103-platform-snet-apim-out-nsg` |
| modules/vnet.bicep: vnet | `module.vnet.azurerm_virtual_network.this` | `…/platform/providers/Microsoft.Network/virtualNetworks/tbi-vnet-exam-ai-103-platform` |
| modules/vnet.bicep: vnet.subnets[0] | `module.vnet.azurerm_subnet.appgw` | `…/virtualNetworks/…/subnets/snet-appgw` |
| modules/vnet.bicep: vnet.subnets[1] | `module.vnet.azurerm_subnet.apim_out` | `…/virtualNetworks/…/subnets/snet-apim-out` |
| modules/vnet.bicep: vnet.subnets[2] | `module.vnet.azurerm_subnet.privatelink` | `…/virtualNetworks/…/subnets/snet-privatelink` |
| modules/apim.bicep: apim | `module.apim.azurerm_api_management.this` | `…/platform/providers/Microsoft.ApiManagement/service/tbi-apim-exam-ai-103` |
| modules/apim-privateendpoint.bicep: privateEndpoint | `module.apim_private_endpoint.azurerm_private_endpoint.this` | `…/platform/providers/Microsoft.Network/privateEndpoints/pe-tbi-apim-exam-ai-103-gateway` |
| …: dnsZone | `module.apim_private_endpoint.azurerm_private_dns_zone.this` | `…/platform/providers/Microsoft.Network/privateDnsZones/privatelink.azure-api.net` |
| …: aRecord | `module.apim_private_endpoint.azurerm_private_dns_a_record.apim` | `…/privateDnsZones/privatelink.azure-api.net/A/tbi-apim-exam-ai-103` |
| …: vnetLink | `module.apim_private_endpoint.azurerm_private_dns_zone_virtual_network_link.this` | `…/privateDnsZones/privatelink.azure-api.net/virtualNetworkLinks/tbi-apim-exam-ai-103-vnet-link` |
| modules/keyvault-appgw-cert.bicep: appGwIdentity | `module.keyvault_appgw_cert.azurerm_user_assigned_identity.appgw` | `…/platform/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tbi-mi-agw-exam-ai-103` |
| …: keyVault | `module.keyvault_appgw_cert.azurerm_key_vault.this` | `…/platform/providers/Microsoft.KeyVault/vaults/tbi-kv-ai103plat` |
| modules/appgw.bicep: publicIp | `module.appgw.azurerm_public_ip.this[0]` | `…/platform/providers/Microsoft.Network/publicIPAddresses/tbi-pip-agw-exam-ai-103` |
| …: wafPolicy | `module.appgw.azurerm_web_application_firewall_policy.this[0]` | `…/platform/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/tbi-agw-exam-ai-103-wafpolicy` |
| …: appGw | `module.appgw.azurerm_application_gateway.this[0]` | `…/platform/providers/Microsoft.Network/applicationGateways/tbi-agw-exam-ai-103` |
| modules/foundry-rbac.bicep: roleAssignment | `module.foundry_rbac.azurerm_role_assignment.apim_openai_user` | `…/tbi-rg-exam-ai-103-mte/providers/Microsoft.CognitiveServices/accounts/tbit-training-ai-103-pr-resource/providers/Microsoft.Authorization/roleAssignments/b05b8d5a-9230-5159-ab6e-1c066aa9c611` |
| main.bicep: modelDeployment[0] | `module.foundry_models.azurerm_cognitive_deployment.this["gpt-5-mini"]` | `…/tbi-rg-exam-ai-103-mte/providers/Microsoft.CognitiveServices/accounts/tbit-training-ai-103-pr-resource/deployments/gpt-5-mini` |
| modules/testvm.bicep: nsg/pip/nic/vm | `module.testvm.*` | — (existiert nicht im Azure, kein Import) |
| main.bicep: account (existing) | `data.azurerm_cognitive_account.foundry` (nur Data-Source) | — |
| Foundry-RG `tbi-rg-exam-ai-103-mte` | nur Data-Source-Kontext | — |

### Bewusst NICHT importiert

- **APIM-Unterressourcen** (APIs, Products, Named Values, Backends,
  Subscriptions): bleiben bei **apiops** (`apim-artifacts/` als Source of
  Truth). Keine `azurerm_api_management_api*`, `_product*`, `_named_value`,
  `_backend`, `_subscription`-Ressourcen im Code.
- **KV-Zertifikat `appgw-tls`** (und Secrets generell): externer Workflow
  `cert:issue`/`cert:import` (DNS-01 via Cloudflare) — unverändert.
- **Zweites Role-Assignment am Foundry-Account**
  `fdc0bad1-81fc-4fa5-a14e-c77d9ca35941` (anderer Service-Principal, Rolle
  „Cognitive Services User"): gehört nicht zu dieser Platform. Da es nicht im
  State ist, würde Terraform es **nicht** löschen — solange es nicht importiert
  bleibt es außen vor.

## Entscheidungen

### azurerm statt azapi

azurerm 4.57.0 bildet alles Nötige ab; azapi wird **nicht** benötigt:

- `sku_name = "StandardV2_1"` ist gültig (Valid Values: `Consumption`,
  `Developer`, `Basic`, `BasicV2`, `Standard`, `StandardV2`, `Premium`,
  `PremiumV2`).
- `virtual_network_type = "External"` + `virtual_network_configuration.subnet_id`
  sind im Provider-Schema nicht an klassische SKUs gebunden (Passthrough an
  die ARM-API; ARM akzeptiert External-Integration für StandardV2, das Bicep
  hat es identisch deployed). Der bekannte Fehler „Managing Virtual Network
  Configuration with Type Internal not supported for Sku Type 'StandardV2'"
  (azurerm issue #30296) betrifft nur `Internal`-Injection, nicht External.

### Import-Details (Perma-Diff-Vermeidung)

Die folgenden Live-Werte weichen von naiven azurerm-Defaults ab und sind
deshalb explizit im Config (ohne `ignore_changes`):

| Stelle | Live-Wert | Maßnahme |
| --- | --- | --- |
| APIM `notificationSenderEmail` | `apimgmt-noreply@mail.windowsazure.com` | explizit gesetzt (sonst Update-Diff) |
| APIM Custom-Property Http2 | `False` | `protocols { enable_http2 = false }` |
| APIM TLS/SSL30/TripleDes168 (6 Keys) | alle `False` | `security`-Block komplett auf `false` |
| APIM `developerPortalStatus`/`legacyPortalStatus` | `Disabled` | von azurerm nicht gemappt → kein Diff, bewusst nicht verwaltet |
| Subnets `privateEndpointNetworkPolicies` | alle 3 `Disabled` | `private_endpoint_network_policies = "Disabled"` (azurerm-Default wäre `Enabled`!) |
| Delegation snet-apim-out `actions` | `["Microsoft.Network/virtualNetworks/subnets/action"]` (von APIM-Integration ergänzt) | explizit im Config |
| PE `customNetworkInterfaceName` / `ipConfigurations` | leer / `[]` (dynamische IP) | beide Blöcke weglassen (ForceNew-Schutz) |
| AppGW `sslPolicy` / `autoscaleConfiguration` | null / null | nicht gesetzt (`sku.capacity = 1`) |
| AppGW Probe `match.statusCodes` | `["200-399"]` | `match { status_code = ["200-399"] }` (sonst Entfernen-Diff) |
| WAF `requestBodyInspectLimitInKB` | 2000 | WIRD von azurerm gemappt (Default 128!) → `request_body_inspect_limit_in_kb = 2000` |
| WAF `*Enforcement`, `computedDisabledRules` | true/true/Known-CVEs | von azurerm nicht gemappt → kein Diff |
| RBAC-Assignment `scope` (Casing) | API liefert `…/resourcegroups/…` (klein), Data-Source `…/resourceGroups/…` | Scope im Wiring via `replace(id, "resourceGroups", "resourcegroups")` angeglichen (scope ist ForceNew → sonst Replace!) |
| Deployment `raiPolicyName` | `Microsoft.DefaultV2` | `rai_policy_name` explizit gesetzt (API-Default wäre `Microsoft.Default`) |

### `ignore_changes`

**Bewusst keine `ignore_changes`-Blöcke nötig**: Alle bekannten Fremd-Updates
(APIM-Custom-Properties, Delegation-Action, KV-Cert-Rotation) sind entweder
bereits im Config abgebildet, vom Provider nicht gemappt (→ kein Diff) oder
betreffen Ressourcen, die Terraform gar nicht verwaltet (KV-Zertifikat).
Falls später Drift entsteht, hier gezielt ergänzen — nicht pauschal.

### Modul-Design

- `appgw`-Modul hat `count = deploy_appgw ? 1 : 0` → Import-Adressen mit
  `[0]`; Bootstrap-Phase ohne AppGW bleibt möglich.
- `foundry_models` nutzt `for_each` über `foundry_deployments` (Map) →
  Import-Adresse mit Key `["gpt-5-mini"]`; zusätzliche Deployments hängen
  sauber an.
- `testvm`-Ressourcen existieren nicht im Azure → Modul ohne Import-Blöcke.
- Foundry-Account + -RG bleiben als Data-Source referenziert (Portal-verwaltet).
- Role-Assignment-Name ist die **fixe Bicep-GUID**
  `guid(account.id, 'apim-openai-user')` → ohne fixen Namen würde TF eine
  Zufalls-GUID erzeugen und ein Replace planen.
- Import-ID-Spezialitäten: `azurerm_web_application_firewall_policy`
  verlangt im Import-ID klein geschriebenes `applicationGateway…Policies`
  (ARM-IDs sind case-insensitive, der Provider-Parser nicht);
  `azurerm_subnet_network_security_group_association` wird mit der
  **Subnet-ID allein** importiert (KEIN `<subnet>|<nsg>`-Format);
  Import-Adressen von counted Modulen tragen den Index am **Modul**
  (`module.appgw[0].…`, nicht an der Ressource).

## Phasen-Schalter (statt Bicep-Parameter)

| mise-Task | deploy_appgw | apim_public_network_access | deploy_test_vm |
| --- | --- | --- | --- |
| `platform:bootstrap` | `false` | `Enabled` | `false` |
| `platform:deploy` | `true` | `Enabled` | `false` |
| `platform:lockdown` | `true` | `Disabled` | `false` |
| `terraform.tfvars` (Live-Stand) | `true` | `Disabled` | `false` |

`terraform.tfvars` enthält den Live-Stand und ersetzt `platform.bicepparam`;
die Tasks überschreiben per `-var`. **Apply immer mit gespeichertem Plan**
(`-out=tfplan` + `apply tfplan`), nie `-auto-approve`.

## State

- Migration läuft mit **lokalem State** (`terraform/terraform.tfstate`,
  gitignored).
- Der Storage-Account wurde bewusst **nicht** angelegt (Spec; Vorlage:
  `backend.hcl.example`).
- **`backend "azurerm" {}` ist deshalb in `versions.tf` AUSKOMMENTIERT**
  (war im PR-Verlauf temporär aktiv): Ein deklarierter backend-Block erzwingt
  Backend-Initialisierung — `terraform plan` bricht sonst mit
  „Backend initialization required" ab, und der azurerm-Backend-Init wiederum
  verlangt einen existierenden Storage-Account (`storage_account_name` ist
  Pflicht). Ohne Storage ist der Remote-Backend-Init also unmöglich und der
  lokale Plan blockiert.
- Übergang auf Remote-Backend: einmalig Storage + Container anlegen → Block
  entkommentieren → `terraform init -backend-config=backend.hcl -migrate-state`
  → danach steht der State remote (Blob-Lease = Locking). Siehe auch
  backend.hcl.example-Kommentar.

## Offene Punkte / TODOs

- [ ] Remote-Backend-Storage beschließen und anlegen (dann `infra/` endgültig
      entfernen — erst wenn Plan mit Remote-State unverändert 0/0/0 bleibt).
- [ ] `terraform.terraform.lock.hcl` entsteht beim ersten `init` — für
      Reproducibility nach Entscheidung committen (aktuell via `.gitignore`
      `terraform/.terraform*` ausgeschlossen, gemäß Spec).
- [ ] CI: `terraform fmt -check`, `terraform validate` (und optional plan gegen
      eine Stub-Subscription) ergänzen.
- [ ] Nach Produktivstellung von Terraform: `infra/` löschen (Regel 5) und
      `docs/platform-gateway.md` final ohne Bicep-Referenzen.

## Nicht im Umfang

- Neue Subnets/DNS/WAF für weitere Backends (z. B. TB One Invoice).
- Änderungen an `apim-artifacts/` (apiops bleibt Source of Truth).
- Zert-Workflow (`.acme/`, `cert:*`).
- `.devcontainer/`.
