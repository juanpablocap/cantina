#!/bin/bash
# Instala y configura Netdata + actualiza nginx para servir /monitor/
# Uso: bash scripts/setup_netdata.sh

set -e
BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"

log()  { echo -e "${BOLD}${GREEN}[netdata]${RESET} $1"; }
warn() { echo -e "${BOLD}${YELLOW}[aviso]${RESET} $1"; }
err()  { echo -e "${BOLD}${RED}[error]${RESET} $1"; exit 1; }

[[ $EUID -ne 0 ]] && err "Ejecutar como root: sudo bash scripts/setup_netdata.sh"

# ─── 1. Instalar Netdata ─────────────────────────────────────────────────────
log "Instalando Netdata..."
if command -v netdata &>/dev/null; then
  warn "Netdata ya está instalado — saltando instalación"
else
  export DEBIAN_FRONTEND=noninteractive
  # Intentar desde repos del sistema primero (más rápido, sin prompts)
  if apt-get install -y netdata 2>/dev/null; then
    log "Netdata instalado desde apt"
  else
    # Fallback: kickstart oficial con flags no-interactivos
    log "Probando kickstart oficial..."
    curl -fsSL https://get.netdata.cloud/kickstart.sh | \
      bash -s -- --stable-channel --no-updates --disable-telemetry \
        --non-interactive --install-type any || err "Instalación fallida"
    log "Netdata instalado vía kickstart"
  fi
fi

# ─── 2. Configurar Netdata ───────────────────────────────────────────────────
NETDATA_CONF="/etc/netdata/netdata.conf"
log "Configurando Netdata..."

if [[ ! -f "$NETDATA_CONF" ]]; then
  mkdir -p /etc/netdata
  touch "$NETDATA_CONF"
fi

# Escribir config mínima si el archivo está vacío o no tiene [global]
if ! grep -q "\[global\]" "$NETDATA_CONF" 2>/dev/null; then
cat > "$NETDATA_CONF" << 'EOF'
[global]
    hostname = cantina-server
    update every = 1
    history = 3600

[web]
    bind to = 127.0.0.1:19999
    allow connections from = localhost 192.168.*.*
    allow dashboard from = localhost 192.168.*.*
    x-frame-options = noframe

[plugins]
    # Habilitar los que más importan
    proc = yes
    diskspace = yes
    network viewer = yes
    apps = no
    cgroups = yes
EOF
  log "netdata.conf creado"
else
  # Asegurar que bind to apunte a loopback (acceso solo via nginx)
  sed -i '/bind to/c\\tbind to = 127.0.0.1:19999' "$NETDATA_CONF" 2>/dev/null || true
  log "netdata.conf ya existía — bind actualizado"
fi

# ─── 3. Actualizar nginx para /monitor/ ──────────────────────────────────────
NGINX_CONF_SRC="$(dirname "$0")/nginx-cantina.conf"
NGINX_CONF_DEST="/etc/nginx/sites-available/cantina"
log "Actualizando nginx..."

if ! grep -q "location /monitor/" "$NGINX_CONF_DEST"; then
  cp "$NGINX_CONF_SRC" "$NGINX_CONF_DEST"
  log "Config nginx actualizada con /monitor/"
else
  warn "/monitor/ ya existe en nginx — sin cambios"
fi

nginx -t && systemctl reload nginx && log "nginx recargado"

# ─── 4. Habilitar y arrancar Netdata ─────────────────────────────────────────
systemctl enable netdata
systemctl restart netdata
sleep 3

if systemctl is-active --quiet netdata; then
  log "Netdata activo ✓"
else
  err "Netdata no arrancó — revisar: journalctl -u netdata -n 30"
fi

# ─── 5. Verificar ────────────────────────────────────────────────────────────
if curl -sf http://127.0.0.1:19999/api/v1/info &>/dev/null; then
  log "API de Netdata responde ✓"
else
  warn "Netdata instalado pero API no responde aún — puede tardar 10-20s más"
fi

echo ""
echo -e "${BOLD}${GREEN}✅ Netdata listo${RESET}"
echo ""
echo "  Dashboard completo:  http://192.168.100.54/monitor/"
echo "  Desde el POS:        pestaña Sistema → botón 📊 Monitor"
echo ""
echo "  Para ver métricas en tiempo real:"
echo "    curl -s 'http://127.0.0.1:19999/api/v1/data?chart=system.cpu&after=-60' | head -c 200"
echo ""
