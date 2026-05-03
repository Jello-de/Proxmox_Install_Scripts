#!/usr/bin/env bash
if [[ -f /root/install.func ]]; then
  source /root/install.func
else
  source "$(dirname "$0")/../misc/install.func"
fi

# Enterprise defaults
INTERNAL_APT_HOST="${INTERNAL_APT_HOST:-deb.debian.org}"
INTERNAL_APT_MIRROR="${INTERNAL_APT_MIRROR:-http://deb.debian.org/debian}"
DEBIAN_CODENAME="${DEBIAN_CODENAME:-bookworm}"

# Optional proxies
HTTP_PROXY="${HTTP_PROXY:-}"
HTTPS_PROXY="${HTTPS_PROXY:-}"
NPM_CONFIG_REGISTRY="${NPM_CONFIG_REGISTRY:-https://registry.npmjs.org/}"

# n8n runtime config
N8N_PORT="${N8N_PORT:-5678}"
N8N_USER="${N8N_USER:-n8n}"
N8N_HOME="/opt/n8n"
N8N_BINARY="/usr/local/bin/n8n"
NODEJS_MAJOR="${NODEJS_MAJOR:-22}"
N8N_VERSION="${N8N_VERSION:-2.18.5}"
NODESOURCE_SETUP_URL="${NODESOURCE_SETUP_URL:-https://deb.nodesource.com/setup_${NODEJS_MAJOR}.x}"

color
catch_errors
prepare_locale
network_check
configure_proxy
configure_apt_offline
update_os

apt_run install ca-certificates curl gnupg sqlite3 qemu-guest-agent
if ! systemctl enable --now qemu-guest-agent; then
  msg_info "qemu-guest-agent konnte nicht aktiviert werden (in LXC ggf. erwartet)"
fi

# Node.js 22+ für n8n sicherstellen
apt_run remove nodejs npm || true
apt_run autoremove || true
apt_run update
apt_run install ca-certificates curl gnupg build-essential python3 python3-setuptools make g++

curl -fsSL "$NODESOURCE_SETUP_URL" | bash -
apt_run install nodejs

node -v
npm -v
if ! node -e "process.exit(Number(process.versions.node.split('.')[0]) >= Number(process.env.NODEJS_MAJOR || 22) ? 0 : 1)"; then
  msg_error "Node.js-Version ist zu alt für n8n. Benötigt >= ${NODEJS_MAJOR}.x"
  exit 1
fi

# npm registry Erreichbarkeit prüfen (DNS)
NPM_REGISTRY_HOST="$(echo "$NPM_CONFIG_REGISTRY" | sed -E 's#^[a-z]+://##; s#/.*$##')"
if ! getent hosts "$NPM_REGISTRY_HOST" >/dev/null 2>&1; then
  msg_error "npm Registry Host nicht auflösbar: $NPM_REGISTRY_HOST"
  msg_info "Setze NPM_CONFIG_REGISTRY auf einen erreichbaren Mirror oder https://registry.npmjs.org/"
  exit 1
fi
msg_ok "npm Registry Host auflösbar: $NPM_REGISTRY_HOST"

npm config set registry "$NPM_CONFIG_REGISTRY"
npm install -g --omit=dev "n8n@${N8N_VERSION}"

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
