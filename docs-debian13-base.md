# Debian 13 Base (leere Imagegrundlage)

Diese Grundlage erstellt einen minimalen Debian-13-LXC als Startpunkt.

## Dateien
- `ct/debian13-base.sh` – erstellt den CT
- `install/debian13-base-install.sh` – minimale Basiskonfiguration ohne Zusatz-App

## Start
```bash
bash ct/debian13-base.sh
```

## Funktionen einbinden (eigene Installer)

### 1) Build-Funktionen einbinden (Host-Seite)
In `ct/<dein-script>.sh`:

```bash
source "$(dirname "$0")/../misc/build.func"
```

Pflichtvariablen:
- `APP`
- `INSTALLER_SCRIPT_NAME`
- `var_os`, `var_version`, `var_cpu`, `var_ram`, `var_disk`, `var_bridge`

Dann Ablauf:
```bash
header_info "$APP"
variables
color
catch_errors
start
build_container
description
```

### 2) Install-Funktionen einbinden (CT-Seite)
In `install/<dein-installer>.sh`:

```bash
if [[ -f /root/install.func ]]; then
  source /root/install.func
else
  source "$(dirname "$0")/../misc/install.func"
fi
```

Typischer Ablauf:
```bash
color
catch_errors
prepare_locale
network_check
configure_proxy
configure_apt_offline
update_os
# ... eigene Pakete / Dienste ...
motd_ssh
customize
configure_root_console_access
cleanup_lxc
```

### 3) Eigene App hinzufügen
- Kopiere `install/debian13-base-install.sh` nach `install/<app>-install.sh`
- Ergänze `apt_run install ...` und Service-Setup
- Erstelle `ct/<app>.sh` mit `INSTALLER_SCRIPT_NAME="<app>-install.sh"`

