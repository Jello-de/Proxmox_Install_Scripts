#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -f /root/install.func ]]; then
  source /root/install.func
else
  source "$(dirname "$0")/../misc/install.func"
fi

INTERNAL_APT_HOST="${INTERNAL_APT_HOST:-deb.debian.org}"
INTERNAL_APT_MIRROR="${INTERNAL_APT_MIRROR:-http://deb.debian.org/debian}"
DEBIAN_CODENAME="${DEBIAN_CODENAME:-trixie}"
HTTP_PROXY="${HTTP_PROXY:-}"
HTTPS_PROXY="${HTTPS_PROXY:-}"

color
catch_errors
prepare_locale
network_check
configure_proxy
configure_apt_offline
update_os

# intentionally minimal: empty Debian 13 baseline only
motd_ssh
customize
configure_root_console_access
cleanup_lxc
msg_ok "Debian 13 base image install complete"
