# AGENTS.md

## Projektkontext

Dieses Repository `Jello-de/Proxmox_Install_Scripts` enthält angepasste Proxmox-LXC-Installationsscripts. Viele Scripts basieren konzeptionell oder strukturell auf `community-scripts/ProxmoxVE`.

Wenn ein Script aus `community-scripts/ProxmoxVE` übernommen oder angepasst wurde, gilt das Community-Script als technische Referenz. Änderungen sollen nicht unnötig von bewährten Community-Mustern abweichen.

## n8n-company Regeln

Das n8n-company Script soll die funktionierende n8n-Struktur aus `community-scripts/ProxmoxVE` übernehmen.

Für n8n gilt:

- Verwende `/opt/n8n.env` als zentrale Environment-Datei.
- Verwende in systemd `EnvironmentFile=/opt/n8n.env`.
- Verwende keinen hart codierten Pfad wie `/usr/local/bin/n8n`.
- Starte n8n über `ExecStart=/usr/bin/env n8n start` oder über einen dynamisch per `command -v n8n` ermittelten Pfad.
- Für lokalen HTTP-Modus setze:
  - `N8N_SECURE_COOKIE=false`
  - `N8N_PORT=5678`
  - `N8N_PROTOCOL=http`
  - `N8N_HOST=<Container-IP>`
  - `N8N_LISTEN_ADDRESS=0.0.0.0`
  - `N8N_USER_FOLDER=/opt/n8n/.n8n`
- Der Dienst soll als `User=n8n` und `Group=n8n` laufen.
- `/opt/n8n/.n8n` muss existieren und `n8n:n8n` gehören.
- n8n CLI-Kommandos dürfen nicht als root ohne `N8N_USER_FOLDER` ausgeführt werden.
- Für CLI-Kommandos immer dieselbe Umgebung wie beim Dienst verwenden:
  `runuser -u n8n -- env N8N_USER_FOLDER=/opt/n8n/.n8n n8n <command>`
- Das Script darf keine `/root/.n8n/config` erzeugen.

## Bekannte Fehler, die vermieden werden müssen

Nicht verwenden:

```ini
ExecStart=/usr/local/bin/n8n
