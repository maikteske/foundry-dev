# foundry-dev

Test-Repo für einen Coder-Workspace auf Basis des Templates `kubernetes-envbuilder` (Homelab). Der Workspace-Pod wird per Envbuilder direkt aus dieser `.devcontainer/devcontainer.json` gebaut.

## Inhalt des Devcontainers

- Basis-Image: `mcr.microsoft.com/devcontainers/dotnet:9.0` (Multi-Arch, arm64-tauglich; das **Microsoft Foundry Toolkit** benötigt die .NET-Runtime)
- Features: Python, Azure CLI, GitHub CLI
- VS Code Extensions: Foundry Toolkit (`ms-windows-ai-studio.windows-ai-studio`), Copilot, Copilot Chat, GitHub Pull Requests

## Nutzung mit Coder

1. Coder-Dashboard → **Templates → kubernetes-envbuilder → Create Workspace**
2. `Repository (auto)`: `https://github.com/maikteske/foundry-dev.git`
3. Erster Start dauert länger (Devcontainer-Image wird im Pod gebaut)
4. **VS Code Desktop**-Button im Dashboard öffnet die IDE

## Erste Schritte im Workspace

- GitHub-Login über das VS Code-Account-Menü (aktiviert Copilot)
- `az login` im Terminal, dann im Foundry Toolkit das Projekt auswählen
- Modell deployen: Toolkit → Model Catalog → gewünschtes Modell → Deploy
- Model-Deployments per IaC: `mise run deploy:whatif` (Plan-Preview) bzw. `mise run deploy` — siehe `terraform/modules/foundry_models`

## Platform-API-Gateway (Terraform `terraform/`)

Privates API-Gateway (APIM StandardV2 + AppGW v2/WAF + Private Endpoint) vor AI Foundry und Fabric GraphQL, public unter `api.maikteske.dev` (LE-Zertifikat via DNS-01 aus Key Vault). Alle Tasks, Architektur und Troubleshooting: **`docs/platform-gateway.md`**.

Infrastructure-as-Code läuft über **Terraform 1.12.2** (azurerm 4.57.0, via mise): `platform:init` → `platform:plan` → `platform:bootstrap` / `platform:deploy` / `platform:lockdown`. Apply immer nur mit gespeichertem Plan (`-out=tfplan` + `apply tfplan`), nie `-auto-approve`. Admin-Konto via `AZURE_CONFIG_DIR=~/.azure-adm`, CF-Token via fnox.

Migration-Details (Mapping-Tabelle, Import-IDs, azurerm-vs-azapi-Entscheidung): **`docs/terraform-migration.md`**.

Nur `/workspaces` ist persistent — alles außerhalb wird beim Neustart aus der Devcontainer-Spezifikation neu aufgebaut.
