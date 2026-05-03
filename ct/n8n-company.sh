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

APP="n8n"
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

header_info "$APP"
variables
color
catch_errors

start
build_container
description
msg_ok "n8n offline container provisioned successfully"
