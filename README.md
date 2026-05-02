# Proxmox_Install_Scripts

Offline-Unternehmensvorlage für Proxmox LXC (Debian-Fokus), inspiriert von:
https://github.com/community-scripts/ProxmoxVE/

## Zielbild: Bereitstellung via GitLab

Die Installationsskripte werden aus einem GitLab-Repository bezogen (Raw URL), optional mit `GITLAB_PRIVATE_TOKEN`.
Damit ist eine zentrale Bereitstellung, Versionierung und Freigabe im Unternehmensnetz möglich.

## Struktur

- `ct/company-debian-offline.sh` – erstellt den LXC und lädt den Installer aus GitLab.
- `install/company-debian-offline-install.sh` – installiert Enterprise-Baseline im Container.
- `misc/build.func` – gemeinsame Build-/Provisioning-Funktionen inkl. GitLab-Download.
- `misc/install.func` – gemeinsame Installations-/Hardening-Funktionen.

## Voraussetzungen (Proxmox Host)

1. Debian LXC Template lokal vorhanden (z. B. auf `local`).
2. Proxmox Host kann die interne GitLab-URL erreichen.
3. Optional: `GITLAB_PRIVATE_TOKEN` für private Projekte.
4. Netzwerkzugang vom CT zum internen APT-Mirror (`INTERNAL_APT_HOST`).

## Nutzung

```bash
chmod +x ct/company-debian-offline.sh install/company-debian-offline-install.sh

# GitLab Quelle setzen
export GITLAB_PROJECT_RAW_BASE="https://gitlab.example.com/company/proxmox-install-scripts/-/raw/main"
# optional bei privatem Projekt
export GITLAB_PRIVATE_TOKEN="<token>"

# optional CT Variablen
export var_version=12
export var_vlan=20
export var_ip='10.20.30.40/24'
export var_gw='10.20.30.1'

bash ct/company-debian-offline.sh
```

## Wichtige Variablen

- GitLab:
  - `GITLAB_PROJECT_RAW_BASE` (z. B. `https://gitlab.example.com/group/project/-/raw/main`)
  - `GITLAB_PRIVATE_TOKEN` (optional)
- Build/CT:
  - `var_cpu`, `var_ram`, `var_disk`
  - `var_os` (Default: `debian`)
  - `var_version` (Default: `12`)
  - `var_bridge`, `var_vlan`, `var_ip`, `var_gw`
  - `PVE_TEMPLATE_STORAGE` (Default: `local`)
  - `PVE_ROOTFS_STORAGE` (Default: `local-lvm`)
- Installer:
  - `INTERNAL_APT_HOST`
  - `INTERNAL_APT_MIRROR`
  - `DEBIAN_CODENAME` (z. B. `bookworm`)
  - `HTTP_PROXY`, `HTTPS_PROXY`
