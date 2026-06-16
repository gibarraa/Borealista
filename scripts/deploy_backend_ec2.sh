#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"

PEM_PATH="${1:-}"
SSH_TARGET="${2:-ubuntu@3.131.135.169}"
APP_DIR="${APP_DIR:-/opt/borealista-backend}"
SERVICE_NAME="${SERVICE_NAME:-borealista-backend}"
PORT="${PORT:-8080}"
REPLACE_TOMCAT="${REPLACE_TOMCAT:-true}"

if [[ -z "$PEM_PATH" ]]; then
  echo "Uso: $0 /ruta/a/la-llave.pem [usuario@host]"
  exit 1
fi

if [[ ! -f "$PEM_PATH" ]]; then
  echo "No existe la llave: $PEM_PATH"
  exit 1
fi

if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "No existe el backend en: $BACKEND_DIR"
  exit 1
fi

chmod 600 "$PEM_PATH"

SSH_OPTS=(
  -i "$PEM_PATH"
  -o StrictHostKeyChecking=accept-new
  -o ConnectTimeout=15
)

ARCHIVE_PATH="$(mktemp -t borealista-backend.XXXXXX.tar.gz)"
trap 'rm -f "$ARCHIVE_PATH"' EXIT

tar \
  --exclude ".DS_Store" \
  --exclude "node_modules" \
  -C "$BACKEND_DIR" \
  -czf "$ARCHIVE_PATH" \
  .

echo "Verificando acceso SSH a $SSH_TARGET..."
ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "echo 'SSH OK'" >/dev/null

echo "Subiendo backend empaquetado..."
scp "${SSH_OPTS[@]}" "$ARCHIVE_PATH" "$SSH_TARGET:/tmp/borealista-backend.tar.gz" >/dev/null

echo "Instalando backend en $SSH_TARGET..."
ssh "${SSH_OPTS[@]}" "$SSH_TARGET" \
  "APP_DIR='$APP_DIR' SERVICE_NAME='$SERVICE_NAME' PORT='$PORT' REPLACE_TOMCAT='$REPLACE_TOMCAT' bash -s" <<'REMOTE'
set -euo pipefail

TMP_ARCHIVE="/tmp/borealista-backend.tar.gz"
TMP_WORKDIR="$(mktemp -d)"
NEXT_DIR="${APP_DIR}.next"
PREVIOUS_DIR="${APP_DIR}.previous"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
BACKUP_DIR="/home/ubuntu/borealista-backups"

cleanup() {
  rm -rf "$TMP_WORKDIR"
}
trap cleanup EXIT

if ! command -v sudo >/dev/null 2>&1; then
  echo "El servidor no tiene sudo disponible."
  exit 1
fi

sudo apt-get update -y
sudo apt-get install -y curl ca-certificates gnupg

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

if [[ "$REPLACE_TOMCAT" == "true" ]]; then
  mkdir -p "$BACKUP_DIR"

  if [[ -f /var/lib/tomcat10/webapps/BorealistaAPI.war ]]; then
    sudo cp \
      /var/lib/tomcat10/webapps/BorealistaAPI.war \
      "$BACKUP_DIR/BorealistaAPI.$(date +%Y%m%d-%H%M%S).war"
  fi

  if systemctl list-unit-files | grep -q '^tomcat10\.service'; then
    sudo systemctl stop tomcat10 || true
    sudo systemctl disable tomcat10 || true
  fi

  if systemctl list-unit-files | grep -q '^tomcat\.service'; then
    sudo systemctl stop tomcat || true
  fi

  sleep 2
fi

sudo rm -rf "$NEXT_DIR"
mkdir -p "$TMP_WORKDIR"
tar -xzf "$TMP_ARCHIVE" -C "$TMP_WORKDIR"

if [[ -f "${APP_DIR}/data/db.json" ]]; then
  mkdir -p "$TMP_WORKDIR/data"
  cp "${APP_DIR}/data/db.json" "$TMP_WORKDIR/data/db.json"
fi

sudo mkdir -p "$NEXT_DIR"
sudo cp -R "$TMP_WORKDIR"/. "$NEXT_DIR"/
sudo chown -R ubuntu:ubuntu "$NEXT_DIR"

cd "$NEXT_DIR"
npm install --omit=dev

sudo tee "$SERVICE_PATH" >/dev/null <<SERVICE
[Unit]
Description=Borealista Backend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
Environment=PORT=$PORT
ExecStart=/usr/bin/env node src/server.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

sudo rm -rf "$PREVIOUS_DIR"
if [[ -d "$APP_DIR" ]]; then
  sudo mv "$APP_DIR" "$PREVIOUS_DIR"
fi
sudo mv "$NEXT_DIR" "$APP_DIR"

if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow "$PORT"/tcp || true
fi

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

echo
echo "Puertos activos relevantes:"
sudo ss -tulpn | grep -E ":(22|80|8080|3306)\s" || true

echo
echo "Estado del servicio:"
sudo systemctl --no-pager --full status "$SERVICE_NAME" | sed -n '1,20p'

echo
echo "Health check local:"
curl -fsS "http://127.0.0.1:${PORT}/health"
REMOTE

echo
echo "Deploy completado."
echo "API esperada: http://${SSH_TARGET#*@}:${PORT}/BorealistaAPI/api"
