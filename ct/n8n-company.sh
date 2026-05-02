#!/usr/bin/env bash
source "$(dirname "$0")/../misc/build.func"

APP="n8n (Company Offline)"
INSTALLER_SCRIPT_NAME="n8n-company-install.sh"
GITLAB_PROJECT_RAW_BASE="${GITLAB_PROJECT_RAW_BASE:-https://gitlab.example.com/company/proxmox-install-scripts/-/raw/main}"
GITLAB_PRIVATE_TOKEN="${GITLAB_PRIVATE_TOKEN:-}"

# Sizing defaults (n8n)
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"

# Debian defaults
var_os="${var_os:-debian}"
var_version="${var_version:-12}"

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
