# Azure-Auth im foundry-dev Workspace

Stand: 2026-11-02 — aktuell aktiver Pfad plus zwei dokumentierte Alternativen.

## Aktuell: Coder User Secrets → SP-Login → fnox/Key Vault → mise

Trust-Kette beim Workspace-Start bzw. ersten Terminal:

```
Coder User Secrets (coderd-DB, 3 Secrets mit env-Target)
  AZURE_CLIENT_ID / AZURE_TENANT_ID / AZURE_CLIENT_SECRET
  │  injiziert in den Agent-Prozess → jede Shell / SSH-Session / Startup-Script
  ▼
.bashrc-Bootstrap (postStartCommand schreibt den Block)
  az login --service-principal (einmalig pro Boot, Guard: az account show)
  ▼
SP-Session (MSAL-Cache in /root/.azure, ephemeral — je Boot neu)
  │
  ├─ fnox: azure-kms entschlüsselt AZURE_CLIENT_SECRET in fnox.toml (Crypto User auf fnox-crypto)
  ├─ fnox Leases: FOUNDRY_TOKEN (ai.azure.com), AZURE_ARM_TOKEN (management)
  └─ Quickstart/Samples: DefaultAzureCredential → AzureCliCredential
```

Aufteilung der Variablen:

| Variable | Quelle | Warum |
| --- | --- | --- |
| `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` | `mise.toml [env]` + Coder Secret | keine Secrets (in jedem Token enthalten); mise für Tasks/Shell, Coder-Secret für den bashrc-Bootstrap vor dem mise-Hook |
| `AZURE_CLIENT_SECRET` | fnox (`azure-kms`, Chiffretext in git) + Coder Secret | einziger sensitiver Wert; Transport über coderd statt Klartext-Datei |

Datei-/Storage-Orte:

- `/workspaces/.secrets/azure-sp.env` — **entfernt** ( war der frühere Klartext-Transport auf dem PVC)
- `~/.azure` (MSAL-Cache) — ephemeral, je Boot neu per SP-Login
- `/workspaces/.mise` — mise-Tool-Installs (PVC, persistent)
- `/workspaces/.fnox-state` — Lease-Ledger (PVC, persistent)
- `/workspaces/.vscode-extensions` — persistenter VS Code-Extensions-Ordner (PVC), via Symlink aus postStartCommand

### Rotation

```sh
az ad app credential reset --id bf29e298-2db6-47e4-9c8a-e101b139cd19 --years 2   # neuer Secret
fnox set AZURE_CLIENT_SECRET --provider azure-kms    # lokal, neuer Chiffretext in fnox.toml (commit)
printf %s "$AZURE_CLIENT_SECRET" | coder secret update azure-client-secret   # Wert via stdin, nie als Argument
# Workspace restarten
```

### Grenzen

- Secrets ändern/löschen revociert nichts, was schon injiziert wurde — Rotation immer in Azure durchführen.
- Coder speichert Secret-Werte in der coderd-DB; verschlüsselt at rest nur mit aktivierter DB-Encryption.
- Wer Shell-Zugriff auf den Workspace hat, kann die injizierten Env-Werte lesen (wie bei jeder Injektion).
- `postStartCommand` läuft als Kind von envbuilder, nicht des Coder-Agenten → sieht User-Secret-Env **nicht**. Der az-Login lebt deshalb im `.bashrc`-Block (Agent-Kontext) mit Guard, sodass er einmal pro Boot beim ersten Terminal läuft.

## VS Code Extensions (web)

Coder Web-VS Code installiert `customizations.vscode.extensions` aus der devcontainer.json **nicht automatisch**. Ge_setzt_ wird ein persistenter Extensions-Ordner (`postStartCommand`-Symlink auf das PVC), damit Installationen Restarts überleben. Einmalig bzw. nach Bedarf im integrierten Terminal:

```sh
code --install-extension hverlin.mise-vscode ms-azuretools.vscode-bicep
```

Alternativ headless über die Server-CLI (nach dem ersten VS-Code-Connect):

```sh
"$(ls -d ~/.vscode-server/cli/servers/*/server | head -1)/bin/code-server" \
  --install-extension ms-azuretools.vscode-bicep
```

`az bicep install` läuft im postStartCommand, damit `az bicep build/decompile` sofort nutzbar ist.

## Alternative A: age-Provider (offline, ohne Key Vault)

SP-Secret wird mit age verschlüsselt in `fnox.toml` commitet; Entschlüsselung braucht nur eine age-Identity-Datei im Workspace — kein KV, kein az-Login für fnox.

1. Key erzeugen und Public Key (Recipient) notieren:

   ```sh
   age-keygen -o ~/.config/fnox/age.txt && age-keygen -y ~/.config/fnox/age.txt   # → age1…
   ```

2. Provider in `fnox.toml` ergänzen (Recipients: Mac + Workspace):

   ```toml
   [providers.age]
   type = "age"
   recipients = ["age1…mac", "age1…workspace"]
   ```

3. Secret umschlüsseln: `fnox set AZURE_CLIENT_SECRET --provider age` (oder `fnox reencrypt -p age`), commiten.
4. Transport der Workspace-Identity: Datei (z. B. `/workspaces/.secrets/age.txt`, 0600) **oder** K8s-Secret im Template **oder** Coder File-Secret (`coder secret create age-key --file /root/.config/fnox/age.txt`).
5. Bootstrap-Kette ändert sich zu: age-Key → `fnox get AZURE_CLIENT_SECRET` → `az login --service-principal` → Foundry.

Bewertung: kein Azure-/KV-Dependency für den Secret-Store, offline-fähig; dafür manueller Key-Transport, Rotation = Re-Encrypt + Neuverteilung, keine Audit-Logs. Root-of-Trust kollabiert auf die age-Datei.

## Alternative B: Azure Workload Identity (kein Secret überhaupt)

Federated Credential zwischen dem Homelab-Cluster (OIDC-Issuer) und der App-Registrierung; der Pod tauscht sein Service-Account-Token gegen ein Azure-Token — ganz ohne Client-Secret.

1. Homelab-K8s mit OIDC-Issuer ausstatten (z. B. kube-oidc-proxy / cluster registrieren in Azure via `az k8s-connection`-Muster oder manuell: Issuer-URL + Signing-Keys öffentlich erreichbar).
2. Federated Credential auf der App-Registrierung anlegen:

   ```sh
   az ad app federated-credential create --id <app-object-id> --parameters '{
     "name": "homelab-foundry-dev", "issuer": "https://<oidc-issuer>",
     "subject": "system:serviceaccount:coder:foundry-dev", "audiences": ["api://AzureADTokenExchange"] }'
   ```

3. Kubernetes: ServiceAccount mit Annotation `azure.workload.identity/client-id`, Label `azure.workload.identity/use: true`, Trust-Bridge (Azure Workload Identity Webhook oder azure-workload-identity-Operator) installieren.
4. fnox/azure-identity löst dann via `WorkloadIdentityCredential` (Teil der DefaultAzureCredential-Kette) auf — ganz ohne Env-Secret.
5. Coder Secrets + bashrc-Bootstrap entfallen komplett.

Bewertung: sicherste und wartungsärmste Variante (kein Secret-Transport, Rotation nur Azure-seitig); Aufwand liegt im Homelab (OIDC-Issuer + Webhook). Erst sinnvoll, wenn der Cluster einen stabilen öffentlichen OIDC-Issuer hat.
