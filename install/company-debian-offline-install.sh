#!/usr/bin/env bash
if [[ -f /root/install.func ]]; then
  source /root/install.func
else
  source "$(dirname "$0")/../misc/install.func"
fi

# Enterprise defaults (über Umgebungsvariablen überschreibbar)
INTERNAL_APT_HOST="${INTERNAL_APT_HOST:-deb.debian.org}"
INTERNAL_APT_MIRROR="${INTERNAL_APT_MIRROR:-http://deb.debian.org/debian}"
DEBIAN_CODENAME="${DEBIAN_CODENAME:-}"

# Optional proxy
HTTP_PROXY="${HTTP_PROXY:-}"
HTTPS_PROXY="${HTTPS_PROXY:-}"

color
catch_errors
prepare_locale
network_check
configure_proxy
configure_apt_offline
update_os
enable_unattended_security_updates

# Basis-Tooling
apt_run install ca-certificates curl gnupg vim htop qemu-guest-agent
if ! systemctl enable --now qemu-guest-agent; then
  msg_info "qemu-guest-agent konnte nicht aktiviert werden (in LXC ggf. erwartet)"
fi

motd_ssh
customize
cleanup_lxc
msg_ok "Offline enterprise baseline installation complete"
