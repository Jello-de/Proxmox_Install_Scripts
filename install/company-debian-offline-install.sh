#!/usr/bin/env bash
source "$(dirname "$0")/../misc/install.func"

# Enterprise defaults (über Umgebungsvariablen überschreibbar)
INTERNAL_APT_HOST="${INTERNAL_APT_HOST:-apt-mirror.intern.local}"
INTERNAL_APT_MIRROR="${INTERNAL_APT_MIRROR:-http://apt-mirror.intern.local/debian}"
DEBIAN_CODENAME="${DEBIAN_CODENAME:-bookworm}"

# Optional proxy
HTTP_PROXY="${HTTP_PROXY:-}"
HTTPS_PROXY="${HTTPS_PROXY:-}"

color
catch_errors
network_check
configure_proxy
configure_apt_offline
update_os
enable_unattended_security_updates

# Basis-Tooling
apt-get install -y ca-certificates curl gnupg vim htop qemu-guest-agent
systemctl enable --now qemu-guest-agent

motd_ssh
customize
cleanup_lxc
msg_ok "Offline enterprise baseline installation complete"
