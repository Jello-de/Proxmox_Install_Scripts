#!/usr/bin/env bash
set -Eeuo pipefail

GITLAB_PROJECT_RAW_BASE="${GITLAB_PROJECT_RAW_BASE:-https://raw.githubusercontent.com/Jello-de/Proxmox_Install_Scripts/main}"
GITLAB_PRIVATE_TOKEN="${GITLAB_PRIVATE_TOKEN:-}"

source "$(dirname "$0")/../misc/build.func"

APP="debian13-base"
INSTALLER_SCRIPT_NAME="debian13-base-install.sh"

# Lean image defaults
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
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
msg_ok "Debian 13 base image container created"
