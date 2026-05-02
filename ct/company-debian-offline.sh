#!/usr/bin/env bash
source "$(dirname "$0")/../misc/build.func"

APP="Company Debian Baseline"
INSTALLER_SCRIPT_NAME="company-debian-offline-install.sh"
# GitLab raw script source (self-hosted or gitlab.com)
GITLAB_PROJECT_RAW_BASE="${GITLAB_PROJECT_RAW_BASE:-https://raw.githubusercontent.com/Jello-de/Proxmox_Install_Scripts/main}"
GITLAB_PRIVATE_TOKEN="${GITLAB_PRIVATE_TOKEN:-}"

# Default sizing
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"

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
msg_ok "Completed successfully!"
