# Proxmox_Install_Scripts

Offline-Unternehmensvorlage für Proxmox LXC (Debian-Fokus), inspiriert von:
https://github.com/community-scripts/ProxmoxVE/

## Struktur

- `ct/company-debian-offline.sh` – erstellt den LXC und startet den Installer.
- `install/company-debian-offline-install.sh` – installiert Enterprise-Baseline im Container.
- `misc/build.func` – gemeinsame Build-/Provisioning-Funktionen.
- `misc/install.func` – gemeinsame Installations-/Hardening-Funktionen.

## Voraussetzungen (Proxmox Host)

1. Debian LXC Template lokal vorhanden (z. B. auf `local`):
   - `debian-12` Template muss über interne/offline Prozesse bereitgestellt sein.
2. Installer-Datei auf Host unter `${INTERNAL_SNIPPETS_DIR}` (Default `/var/lib/vz/snippets`).
3. Netzwerkzugang vom CT zum internen APT-Mirror (`INTERNAL_APT_HOST`).

## Nutzung

```bash
chmod +x ct/company-debian-offline.sh install/company-debian-offline-install.sh
cp install/company-debian-offline-install.sh /var/lib/vz/snippets/

# optional Variablen setzen
export INTERNAL_SNIPPETS_DIR=/var/lib/vz/snippets
export var_version=12
export var_vlan=20
export var_ip='10.20.30.40/24'
export var_gw='10.20.30.1'

bash ct/company-debian-offline.sh
```

## Wichtige Variablen

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

## Hinweis

Diese Vorlage ist bewusst als Offline-/Intranet-Ansatz umgesetzt und verwendet keine externen Downloads im Laufzeitpfad der Installation.
