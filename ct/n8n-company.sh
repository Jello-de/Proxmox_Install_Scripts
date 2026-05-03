#!/usr/bin/env bash
set -Eeuo pipefail

GITLAB_PROJECT_RAW_BASE="${GITLAB_PROJECT_RAW_BASE:-https://raw.githubusercontent.com/Jello-de/Proxmox_Install_Scripts/main}"
GITLAB_PRIVATE_TOKEN="${GITLAB_PRIVATE_TOKEN:-}"

load_build_functions() {
  local local_func="$(dirname "$0")/../misc/build.func"
  if [[ -f "$local_func" ]]; then
    # shellcheck disable=SC1090
    source "$local_func"
    return
  fi

  local tmp_func
  tmp_func="$(mktemp)"
  local func_url="${GITLAB_PROJECT_RAW_BASE}/misc/build.func"
  if [[ -n "${GITLAB_PRIVATE_TOKEN}" ]]; then
    curl -fsSL -H "PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}" "$func_url" -o "$tmp_func"
  else
    curl -fsSL "$func_url" -o "$tmp_func"
  fi
  # shellcheck disable=SC1090
  source "$tmp_func"
}

load_build_functions

APP="n8n-company"
INSTALLER_SCRIPT_NAME="n8n-company-install.sh"

# Sizing defaults (n8n)
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"

# Debian defaults
var_os="${var_os:-debian}"
var_version="${var_version:-13}"

# Network defaults
var_bridge="${var_bridge:-vmbr0}"
var_vlan="${var_vlan:-}"
var_ip="${var_ip:-dhcp}"
var_gw="${var_gw:-}"

select_mode() {
  echo ""
  echo "1) Default Settings"
  echo "2) Advanced Settings"
  echo "3) Verbose/Diagnostic Mode"
  echo "4) Exit"
  read -r -p "Auswahl [1-4]: " mode
  case "$mode" in
    1) ;;
    2)
      read -r -p "CTID (leer=auto): " VMID
      read -r -p "Hostname (leer=auto): " HOSTNAME_OVERRIDE
      read -r -p "CPU Cores [${var_cpu}]: " input; var_cpu="${input:-$var_cpu}"
      read -r -p "RAM MB [${var_ram}]: " input; var_ram="${input:-$var_ram}"
      read -r -p "Disk GB [${var_disk}]: " input; var_disk="${input:-$var_disk}"
      read -r -p "Template Storage [${PVE_TEMPLATE_STORAGE:-local}]: " input; PVE_TEMPLATE_STORAGE="${input:-${PVE_TEMPLATE_STORAGE:-local}}"
      read -r -p "RootFS Storage [${PVE_ROOTFS_STORAGE:-local-lvm}]: " input; PVE_ROOTFS_STORAGE="${input:-${PVE_ROOTFS_STORAGE:-local-lvm}}"
      read -r -p "Bridge [${var_bridge}]: " input; var_bridge="${input:-$var_bridge}"
      read -r -p "VLAN (leer=none) [${var_vlan:-}]: " input; var_vlan="${input:-$var_vlan}"
      read -r -p "IP (dhcp oder CIDR) [${var_ip}]: " input; var_ip="${input:-$var_ip}"
      if [[ "$var_ip" != "dhcp" ]]; then
        read -r -p "Gateway [${var_gw:-}]: " input; var_gw="${input:-$var_gw}"
      fi
      read -r -p "Unprivileged? (1/0) [${var_unprivileged:-1}]: " input; var_unprivileged="${input:-${var_unprivileged:-1}}"
      ;;
    3)
      set -x
      ;;
    4)
      exit 0
      ;;
    *)
      msg_error "Ungültige Auswahl"
      exit 1
      ;;
  esac
}

show_plan() {
  echo ""
  echo "Geplante Konfiguration:"
  echo "  CTID: ${VMID:-auto}"
  echo "  Hostname: ${HOSTNAME_OVERRIDE:-auto}"
  echo "  CPU/RAM/DISK: ${var_cpu}/${var_ram}MB/${var_disk}GB"
  echo "  Storage Template/RootFS: ${PVE_TEMPLATE_STORAGE:-local}/${PVE_ROOTFS_STORAGE:-local-lvm}"
  echo "  Network: bridge=${var_bridge} vlan=${var_vlan:-none} ip=${var_ip} gw=${var_gw:-none}"
  read -r -p "Mit Erstellung fortfahren? (y/N): " confirm
  [[ "${confirm,,}" == "y" ]]
}

header_info "$APP"
variables
color
catch_errors

select_mode
show_plan || { msg_error "Abbruch durch Benutzer."; exit 1; }

start
build_container
description
msg_ok "n8n company container provisioned successfully"
