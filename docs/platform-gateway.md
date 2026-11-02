# Platform-API-Gateway Runbook

Privates API-Gateway vor Azure AI Foundry und Fabric GraphQL, veröffentlicht unter `api.maikteske.dev`.

## Architektur

```
Internet ── Cloudflare DNS-only (Gray Cloud, kein Proxy)
   │  api.maikteske.dev  CNAME → tbi-agw-exam-ai-103.swedencentral.cloudapp.azure.com
   ▼
Application Gateway v2 + WAF (OWASP 3.2, Prevention)
   │  TLS-Terminierung: LE-Zertifikat (DNS-01) aus Key Vault tbi-kv-ai103plat
   ▼
APIM StandardV2 (outbound VNet, subnet delegiert an Microsoft.Web/serverFarms)
   │  Private Endpoint (sub-resource Gateway) in snet-privatelink
   ▼                                    ▼
AI Foundry Account               Fabric GraphQL API
(RBAC: APIM-MI = Cognitive       (authentication-managed-identity,
 Services OpenAI User)            resource https://api.fabric.microsoft.com)
```

- APIM `publicNetworkAccess` wird nach PE-Anlage auf `Disabled` gestellt (Two-Phase-Lockdown).
- Namensschema: RG `tbi-rg-exam-ai-103-platform`, APIM `tbi-apim-exam-ai-103`, KV `tbi-kv-ai103plat`, AppGW `tbi-agw-exam-ai-103`, MI `tbi-mi-agw-exam-ai-103`.
- Keine Cloudflare-Origin-CA im Key Vault: Zertifikat kommt als LE-PFX via Import, Cloudflare bleibt DNS-only.

## Voraussetzungen

| Was | Wo |
|---|---|
| Admin-Az-Konto (`AZURE_CONFIG_DIR=~/.azure-adm`) | Rechner, auf dem die platform-Tasks laufen |
| Scoped Cloudflare-API-Token (Zone `maikteske.dev`, DNS:Edit) | `fnox set CLOUDFLARE_API_TOKEN` |
| SP-Creds für apiops (`AZURE_CLIENT_SECRET`) | fnox (schon vorhanden) |
| Bicep/az | `az bicep install`, az ≥ 2.5x |

## Deploy-Sequenz (Phase 1 – Plattform)

```sh
mise run platform:bootstrap   # RG+VNet+APIM+PE+KV+RBAC, ohne AppGW, public=Enabled
mise run cert:issue           # LE via DNS-01 (braucht CLOUDFLARE_API_TOKEN)
mise run cert:import          # PFX → KV-Zertifikat appgw-tls
mise run platform:deploy      # voll inkl. AppGW
mise run platform:lockdown    # APIM public=Disabled (nur noch PE-Inbound)
```

Verifikation nach lockdown:

```sh
az apim show -g "$PLATFORM_RG" -n "$PLATFORM_APIM" \
  --query "{public:properties.publicNetworkAccess,vnet:properties.virtualNetworkType,pe:properties.privateEndpointConnections[0].properties.privateEndpointConnectionStatus}" -o table
```

- `public: Disabled`, `pe: Approved` (bei `Pending`: Connection approve, siehe unten).
- DNS-Prüfung privat: `nslookup <apim>.azure-api.net` aus dem VNet → private IP.
- Cloudflare-DNS (manuell, einmalig): CNAME `api` → `tbi-agw-exam-ai-103.swedencentral.cloudapp.azure.com`, **Gray Cloud**.

## Zertifikat-Renewal

`mise run cert:renew` (issue + KV-Import). AppGW liest das versionless Secret-URI (`…/secrets/appgw-tls`) und pickt neue Versionen selbst auf (Zyklus ~24 h; nach Renew ggf. AppGW-Neustart, wenn sofort nötig).

## Phase 2 – API-Content (apiops)

Ownership-Grenze: **Bicep definiert keine apis/policies/products** — alles API-Content läuft über `apim-artifacts/` (sonst Drift gegen `--delete-unmatched`).

```sh
mise run apim:extract          # Bootstrap: Ist-Stand extrahieren
# Artefakte autorieren: foundry-models-API, Fabric-GraphQL-API, Products, Policies
mise run apim:publish:dryrun   # Review!
mise run apim:publish
```

Fabric-Backend: **nicht** die kopierte Public-URL der GraphQL-API verwenden (die nimmt nur User-Tokens), sondern den SP/MI-Endpunkt:

```
https://api.fabric.microsoft.com/v1/workspaces/4c5f30f5-a10f-4886-9972-cfd4b63a6f83/graphqlapis/8857282e-4a3c-4c9b-b821-f1ba31f95f57/execute
```

Policies je API: `authentication-managed-identity` (resource `https://api.fabric.microsoft.com` bzw. Foundry) + `graphql-max-depth`/`graphql-max-complexity`.

## Smoke-Tests (Stand: deployiert)

PublicGateway: `api.maikteske.dev` (Cloudflare CNAME, DNS-only, LE-Zertifikat aus KV `appgw-tls`).
Subscription-Key: Product **platform-apis** (Subscription `smoke` in APIM angelegt).

```sh
KEY=<primary-key der Subscription 'smoke'>
curl -sf https://api.maikteske.dev/status-0123456789abcdef   # AppGW→APIM gesund (valides LE-Zert)

# Foundry (OpenAI legacy endpoint, MI-Auth via policy resource cognitiveservices.azure.com):
curl "https://api.maikteske.dev/foundry/openai/deployments/gpt-5-mini/chat/completions?api-version=2024-10-21" \
  -H "Ocp-Apim-Subscription-Key: $KEY" -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"pong?"}],"max_completion_tokens":32}'

# Fabric GraphQL (execute endpoint, MI-Auth via policy resource api.fabric.microsoft.com):
curl "https://api.maikteske.dev/fabric" \
  -H "Ocp-Apim-Subscription-Key: $KEY" -H "Content-Type: application/json" \
  -d '{"query":"query { entities_gold_layers(first: 10) { items { id } } }"}'
```

APIM-Lektion: Operations mit `method: "*"` werden von StandardV2 nicht geroutet —
pro Methode eigene Operations (POST/GET × `/{*path}` und `/`) anlegen (siehe apim-artifacts/apis/*/operations).

## Manuelles Zutun (einmalig, Fabric-Tenant) — Status

1. ✅ APIM-System-MI (`tbi-apim-exam-ai-103`, principalId `c897f71c-a17a-4816-97c5-7538567ff8e8`) als **Member** des Fabric-Workspaces `4c5f30f5-a10f-4886-9972-cfd4b63a6f83` (via roleAssignments-API).
2. ⚠️ Tenant-Setting **„Service principals can call Fabric public APIs"** (`ServicePrincipalAccessPermissionAPIs`) ist enabled, aber auf Security-Groups beschränkt — APIM-MI muss in eine erlaubte Gruppe (z. B. `azu_sub_tbi_fabric_analytics_app_dev`) oder direkt ins Setting (Admin-Portal → Developer settings). API-PATH war readonly (405); Graph durch CAE blockiert.
3. Workspace-Capacity muss laufen (war zeitweise pausiert → Fabric-401).

## Troubleshooting

| Symptom | Ursache/Lösung |
|---|---|
| PE-Connection `Pending` | `az network private-endpoint-connection` … approve (APIM PE muss manuell freigegeben werden) |
| AppGW-Backend unhealthy | Zone `privatelink.azure-api.net` gelinkt? CNAME-Kette `<apim>.azure-api.net → <apim>.privatelink.azure-api.net` prüfen |
| 502/5xx direkt nach deploy | KV-Zert fehlt oder PE nicht Approved → Sequenz von oben |
| cert:issue schlägt fehl | `CLOUDFLARE_API_TOKEN` fehlt in fnox oder Token-Limits zu eng (Zone + DNS:Edit) |
| apiops löscht APIs | Artefakte sind Source of Truth — nie direkt in APIM clicken, immer extract→edit→publish |
