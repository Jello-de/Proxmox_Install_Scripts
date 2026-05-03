#!/usr/bin/env bash
if [[ -f /root/install.func ]]; then
  source /root/install.func
else
  source "$(dirname "$0")/../misc/install.func"
fi

# Enterprise defaults
INTERNAL_APT_HOST="${INTERNAL_APT_HOST:-deb.debian.org}"
INTERNAL_APT_MIRROR="${INTERNAL_APT_MIRROR:-http://deb.debian.org/debian}"
DEBIAN_CODENAME="${DEBIAN_CODENAME:-}"

# Optional proxies
HTTP_PROXY="${HTTP_PROXY:-}"
HTTPS_PROXY="${HTTPS_PROXY:-}"
NPM_CONFIG_REGISTRY="${NPM_CONFIG_REGISTRY:-https://registry.npmjs.org/}"

# n8n runtime config
N8N_PORT="${N8N_PORT:-5678}"
N8N_USER="${N8N_USER:-n8n}"
N8N_HOME="/opt/n8n"
N8N_ENV_FILE="/opt/n8n.env"
NODEJS_MAJOR="${NODEJS_MAJOR:-22}"
N8N_VERSION="${N8N_VERSION:-2.18.5}"
NODESOURCE_SETUP_URL="${NODESOURCE_SETUP_URL:-https://deb.nodesource.com/setup_${NODEJS_MAJOR}.x}"
INSTALL_LOG="/var/log/n8n-company-install.log"

run_logged() {
  local cmd="$*"
  if [[ "${VERBOSE:-0}" == "1" ]]; then
    bash -lc "$cmd" 2>&1 | tee -a "$INSTALL_LOG"
    return ${PIPESTATUS[0]}
  fi
  bash -lc "$cmd" >>"$INSTALL_LOG" 2>&1
}

show_latest_npm_log() {
  local latest_log
  latest_log="$(ls -1t /root/.npm/_logs/*debug-0.log 2>/dev/null | head -n1 || true)"
  if [[ -n "$latest_log" ]]; then
    msg_info "Letzte npm Debug-Log ($latest_log), letzte 120 Zeilen:"
    tail -n 120 "$latest_log" || true
  fi
}

check_resources() {
  local avail_kb mem_mb
  avail_kb="$(df -Pk / | awk 'NR==2 {print $4}')"
  mem_mb="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)"
  msg_info "Ressourcencheck: freier Platz=${avail_kb}KB, RAM=${mem_mb}MB"
  if (( avail_kb < 2097152 )); then
    msg_error "Zu wenig freier Speicherplatz (<2GB)."
    exit 1
  fi
  if (( mem_mb < 1024 )); then
    msg_error "Zu wenig RAM (<1024MB) für n8n/npm Build-Schritte."
    exit 1
  fi
}

color
catch_errors
prepare_locale
mkdir -p /var/log
: >"$INSTALL_LOG"
network_check
configure_proxy
configure_apt_offline
update_os
check_resources

apt_run install ca-certificates curl gnupg sqlite3

# Node.js 22+ für n8n sicherstellen
apt_run remove nodejs npm || true
apt_run autoremove || true
apt_run update
apt_run install ca-certificates curl gnupg build-essential python3 python3-setuptools make g++

if ! run_logged "curl -fsSL '$NODESOURCE_SETUP_URL' | bash -"; then
  msg_error "NodeSource Setup fehlgeschlagen."
  tail -n 120 "$INSTALL_LOG" || true
  exit 1
fi
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
if command -v n8n >/dev/null 2>&1 && [[ "$(n8n --version 2>/dev/null || true)" == "${N8N_VERSION}" ]]; then
  msg_info "n8n ${N8N_VERSION} ist bereits installiert, überspringe npm Install."
else
  set +e
  run_logged "npm install -g --omit=dev --no-audit --no-fund --loglevel=error n8n@${N8N_VERSION}"
  npm_rc=$?
  set -e
  if [[ $npm_rc -ne 0 ]]; then
    if [[ $npm_rc -eq 130 ]]; then
      msg_error "npm Install wurde unterbrochen (SIGINT, Exit 130)."
    else
      msg_error "npm Install fehlgeschlagen (Exit ${npm_rc})."
    fi
    show_latest_npm_log
    tail -n 120 "$INSTALL_LOG" || true
    exit $npm_rc
  fi
fi

N8N_BIN="$(command -v n8n || true)"
if [[ -z "$N8N_BIN" ]]; then
  msg_error "n8n Binary nicht gefunden nach npm Installation."
  exit 1
fi

# System user + directories
id -u "$N8N_USER" >/dev/null 2>&1 || useradd --system --create-home --home-dir "$N8N_HOME" --shell /usr/sbin/nologin "$N8N_USER"
mkdir -p "$N8N_HOME/.n8n"
chown -R "$N8N_USER:$N8N_USER" "$N8N_HOME"

runuser -u "$N8N_USER" -- env N8N_USER_FOLDER="$N8N_HOME/.n8n" "$N8N_BIN" --version >/dev/null

cat >/etc/systemd/system/n8n.service <<SERVICE
[Unit]
Description=n8n Workflow Automation
After=network.target

[Service]
Type=simple
User=${N8N_USER}
Group=${N8N_USER}
EnvironmentFile=${N8N_ENV_FILE}
ExecStart=/usr/bin/env n8n start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

CT_IP="$(hostname -I | awk '{print $1}')"
cat >"${N8N_ENV_FILE}" <<ENV
N8N_SECURE_COOKIE=false
N8N_PORT=${N8N_PORT}
N8N_PROTOCOL=http
N8N_HOST=${CT_IP}
N8N_LISTEN_ADDRESS=0.0.0.0
N8N_USER_FOLDER=${N8N_HOME}/.n8n
ENV
chown ${N8N_USER}:${N8N_USER} "${N8N_ENV_FILE}"
chmod 640 "${N8N_ENV_FILE}"

systemctl daemon-reload
systemctl enable --now n8n

for _ in {1..30}; do
  systemctl is-active --quiet n8n && ss -lntp | grep -q ":${N8N_PORT} " && curl -fsS "http://127.0.0.1:${N8N_PORT}/" >/dev/null 2>&1 && break
  sleep 2
done

if ! systemctl is-active --quiet n8n; then
  msg_error "n8n service ist nicht aktiv."
  systemctl status n8n --no-pager || true
  journalctl -u n8n --no-pager -n 120 || true
  tail -n 120 "$INSTALL_LOG" || true
  exit 1
fi

if ! ss -lntp | grep -q ":${N8N_PORT} "; then
  msg_error "n8n lauscht nicht auf Port ${N8N_PORT}."
  systemctl status n8n --no-pager || true
  journalctl -u n8n --no-pager -n 120 || true
  tail -n 120 "$INSTALL_LOG" || true
  exit 1
fi

if ! curl -fsS "http://127.0.0.1:${N8N_PORT}/" >/dev/null 2>&1; then
  msg_error "n8n HTTP Healthcheck fehlgeschlagen auf 127.0.0.1:${N8N_PORT}."
  systemctl status n8n --no-pager || true
  journalctl -u n8n --no-pager -n 120 || true
  tail -n 120 "$INSTALL_LOG" || true
  exit 1
fi

if [[ -f /root/.n8n/config ]]; then
  msg_error "Unerwartete Root-Konfiguration gefunden: /root/.n8n/config"
  exit 1
fi

motd_ssh
customize
configure_root_console_access
cleanup_lxc
msg_ok "n8n company installation complete"
echo "n8n URL: http://${CT_IP}:${N8N_PORT}"
if [[ "${VERBOSE:-0}" == "1" ]]; then
  msg_info "Install-Log: ${INSTALL_LOG}"
else
  msg_info "Bei Problemen: tail -n 120 ${INSTALL_LOG}"
fi
