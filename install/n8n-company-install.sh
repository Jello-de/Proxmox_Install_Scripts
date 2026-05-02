#!/usr/bin/env bash
if [[ -f /root/install.func ]]; then
  source /root/install.func
else
  source "$(dirname "$0")/../misc/install.func"
fi

# Enterprise defaults
INTERNAL_APT_HOST="${INTERNAL_APT_HOST:-apt-mirror.intern.local}"
INTERNAL_APT_MIRROR="${INTERNAL_APT_MIRROR:-http://apt-mirror.intern.local/debian}"
DEBIAN_CODENAME="${DEBIAN_CODENAME:-bookworm}"

# Optional proxies
HTTP_PROXY="${HTTP_PROXY:-}"
HTTPS_PROXY="${HTTPS_PROXY:-}"
NPM_CONFIG_REGISTRY="${NPM_CONFIG_REGISTRY:-http://npm-mirror.intern.local/repository/npm/}"

# n8n runtime config
N8N_PORT="${N8N_PORT:-5678}"
N8N_USER="${N8N_USER:-n8n}"
N8N_HOME="/opt/n8n"
N8N_BINARY="/usr/local/bin/n8n"

color
catch_errors
network_check
configure_proxy
configure_apt_offline
update_os

apt-get install -y ca-certificates curl gnupg sqlite3 qemu-guest-agent
systemctl enable --now qemu-guest-agent

# Node.js aus Debian Repo (offline-freundlich)
apt-get install -y nodejs npm
npm config set registry "$NPM_CONFIG_REGISTRY"
npm install -g --omit=dev n8n

# System user + directories
id -u "$N8N_USER" >/dev/null 2>&1 || useradd --system --create-home --home-dir "$N8N_HOME" --shell /usr/sbin/nologin "$N8N_USER"
mkdir -p "$N8N_HOME/.n8n"
chown -R "$N8N_USER:$N8N_USER" "$N8N_HOME"

cat >/etc/systemd/system/n8n.service <<SERVICE
[Unit]
Description=n8n Workflow Automation
After=network.target

[Service]
Type=simple
User=${N8N_USER}
Group=${N8N_USER}
Environment=N8N_PORT=${N8N_PORT}
Environment=N8N_HOST=0.0.0.0
Environment=N8N_PROTOCOL=http
Environment=N8N_USER_FOLDER=${N8N_HOME}/.n8n
ExecStart=${N8N_BINARY}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now n8n

motd_ssh
customize
cleanup_lxc
msg_ok "n8n company offline installation complete"
