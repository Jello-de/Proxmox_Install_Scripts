# Proxmox_Install_Scripts

Unternehmensvorlage für Proxmox LXC (Debian-Fokus), inspiriert von:
https://github.com/community-scripts/ProxmoxVE/

## Zielbild: Bereitstellung via GitLab

Die Installationsskripte werden aus eurem eigenen Repository bezogen (Raw URL), optional mit `GITLAB_PRIVATE_TOKEN`.
Damit bleibt ihr unabhängig vom Community-Repo und könnt Änderungen selbst steuern.

## Struktur

- `ct/company-debian-offline.sh` – erstellt den LXC und lädt den Installer aus GitLab.
- `install/company-debian-offline-install.sh` – installiert Enterprise-Baseline im Container.
- `misc/build.func` – gemeinsame Build-/Provisioning-Funktionen inkl. GitLab-Download.
- `misc/install.func` – gemeinsame Installations-/Hardening-Funktionen.

## Voraussetzungen (Proxmox Host)

1. Debian LXC Template lokal vorhanden (z. B. auf `local`).
2. Proxmox Host kann die interne GitLab-URL erreichen.
3. Optional: `GITLAB_PRIVATE_TOKEN` für private Projekte.
4. Netzwerkzugang vom CT zum konfigurierten APT-Host (intern oder `deb.debian.org`).

## Nutzung

```bash
chmod +x ct/company-debian-offline.sh install/company-debian-offline-install.sh

# GitLab Quelle setzen
export GITLAB_PROJECT_RAW_BASE="https://raw.githubusercontent.com/Jello-de/Proxmox_Install_Scripts/main"
# optional bei privatem Projekt
export GITLAB_PRIVATE_TOKEN="<token>"

# optional CT Variablen
export var_version=13
export var_vlan=20
export var_ip='10.20.30.40/24'
export var_gw='10.20.30.1'

bash ct/company-debian-offline.sh
```

## Wichtige Variablen

- GitLab:
  - `GITLAB_PROJECT_RAW_BASE` (z. B. `https://raw.githubusercontent.com/Jello-de/Proxmox_Install_Scripts/main`)
  - `GITLAB_PRIVATE_TOKEN` (optional)
- Build/CT:
  - `var_cpu`, `var_ram`, `var_disk`
  - `var_os` (Default: `debian`)
  - `var_version` (Default: `13`)
  - `var_bridge`, `var_vlan`, `var_ip`, `var_gw`
  - `PVE_TEMPLATE_STORAGE` (Default: `local`)
  - `PVE_ROOTFS_STORAGE` (Default: `local-lvm`)
  - `HOSTNAME_OVERRIDE` (optional, wird DNS-konform bereinigt)
- Installer:
  - `INTERNAL_APT_HOST` (optional; z. B. `deb.debian.org` oder interner Mirror-Host)
  - `INTERNAL_APT_MIRROR`
  - `DEBIAN_CODENAME` (optional; automatisch aus `/etc/os-release`, z. B. `trixie`)
  - `HTTP_PROXY`, `HTTPS_PROXY`
  - `SKIP_NETWORK_CHECK` (`1` = Erreichbarkeitscheck überspringen)
  - `NPM_CONFIG_REGISTRY` (n8n; Default: `https://registry.npmjs.org/`)
  - `NODEJS_MAJOR` (n8n; Default: `22`)
  - `N8N_VERSION` (n8n; Default: `2.18.5`)
  - `NODESOURCE_SETUP_URL` (optional; Default baut auf `NODEJS_MAJOR`)


## n8n (interner Gebrauch)

Zusätzlich ist ein n8n-spezifischer Company-Flow enthalten:

- `ct/n8n-company.sh` – erstellt einen Debian-LXC für n8n und lädt `install/n8n-company-install.sh` aus GitLab.
- `install/n8n-company-install.sh` – richtet n8n für Unternehmensbetrieb ein (eigene APT-/npm-Quellen konfigurierbar).

Beispiel:

```bash
chmod +x ct/n8n-company.sh install/n8n-company-install.sh
export GITLAB_PROJECT_RAW_BASE="https://raw.githubusercontent.com/Jello-de/Proxmox_Install_Scripts/main"
export GITLAB_PRIVATE_TOKEN="<token>"   # optional
export INTERNAL_APT_MIRROR="http://deb.debian.org/debian"
export NPM_CONFIG_REGISTRY="https://registry.npmjs.org/"  # oder interner npm-Mirror
bash ct/n8n-company.sh
```

Einzeiler (Bootstrap via curl) ist jetzt ebenfalls möglich:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jello-de/Proxmox_Install_Scripts/main/ct/n8n-company.sh)"
```


Hinweis: APT wird im Quiet-Modus (`-qq`) ausgeführt, um Ausgabe auf wichtige Meldungen (Warnungen/Fehler) zu reduzieren.
