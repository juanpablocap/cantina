#!/bin/bash
# Monitor en tiempo real — Cantina POS
# Uso: bash scripts/monitor.sh
# Refresca cada 5 segundos. Ctrl+C para salir.

ROUTER="192.168.100.101"
ROUTER_USER="root"
ROUTER_PASS="adminHW"
SERVER="192.168.100.54"
API="http://localhost:3001/api"
INTERVALO=5

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
MUTED='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC}  $1"; }
fail() { echo -e "  ${RED}✗${NC}  $1"; ERRORES=$((ERRORES+1)); }
warn() { echo -e "  ${YELLOW}!${NC}  $1"; }
sep()  { echo -e "${MUTED}  ────────────────────────────────────────${NC}"; }

check_all() {
  ERRORES=0
  clear

  # ── Header ─────────────────────────────────────────────────────────
  echo ""
  echo -e "  ${BOLD}🍽️  CANTINA POS — MONITOR${NC}  ${MUTED}$(date '+%d/%m/%Y %H:%M:%S')${NC}  ${MUTED}[Ctrl+C para salir]${NC}"
  sep

  # ── Red ────────────────────────────────────────────────────────────
  echo -e "  ${BOLD}${BLUE}RED${NC}"

  # Router — ping + SSH si está disponible sshpass
  RTT=$(ping -c 1 -W 2 "$ROUTER" 2>/dev/null | grep -oP 'time=\K[0-9.]+')
  if [ -n "$RTT" ]; then
    if command -v sshpass &>/dev/null; then
      ROUTER_UPTIME=$(sshpass -p "$ROUTER_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
        "${ROUTER_USER}@${ROUTER}" "uptime -p 2>/dev/null || cat /proc/uptime" 2>/dev/null | head -1 | tr -d '\r')
      if [ -n "$ROUTER_UPTIME" ]; then
        ok "Router $ROUTER — ${RTT}ms · uptime: $ROUTER_UPTIME"
      else
        ok "Router $ROUTER — ${RTT}ms (SSH no disponible)"
      fi
    else
      ok "Router $ROUTER — ${RTT}ms"
    fi
  else
    fail "Router $ROUTER — SIN RESPUESTA"
  fi

  # IP propia
  IP_LOCAL=$(ip -4 addr show enp0s31f6 2>/dev/null | grep -oP '(?<=inet )\d+\.\d+\.\d+\.\d+' | head -1)
  [ -n "$IP_LOCAL" ] && ok "Servidor $IP_LOCAL" || warn "No detecta IP en enp0s31f6"

  sep

  # ── Servicios ──────────────────────────────────────────────────────
  echo -e "  ${BOLD}${BLUE}SERVICIOS${NC}"

  systemctl is-active postgresql -q \
    && ok "PostgreSQL" \
    || fail "PostgreSQL — CAÍDO (sudo systemctl restart postgresql)"

  systemctl is-active cantina-api -q \
    && ok "Backend API" \
    || fail "Backend API — CAÍDO (bash scripts/restart_backend.sh)"

  systemctl is-active nginx -q \
    && ok "Nginx" \
    || fail "Nginx — CAÍDO (sudo systemctl restart nginx)"

  # API health
  if curl -sf "$API/health" > /dev/null 2>&1; then
    ok "API responde en :3001"
  else
    fail "API no responde — backend sin levantar"
  fi

  sep

  # ── POS — estado del día ───────────────────────────────────────────
  echo -e "  ${BOLD}${BLUE}VENTAS DE HOY${NC}"

  POS_DATA=$(curl -sf "$API/pedidos" 2>/dev/null)
  if [ -n "$POS_DATA" ]; then
    python3 - <<PYEOF
import json, sys

peds = json.loads("""$POS_DATA""")
cobrados    = [p for p in peds if p['cobrado']]
sin_cobrar  = [p for p in peds if not p['cobrado'] and p['estado'] != 'cancelado']
cancelados  = [p for p in peds if p['estado'] == 'cancelado']
total_hoy   = sum(p['total'] for p in cobrados)
efectivo    = sum(p['total'] for p in cobrados if p['metodo_pago'] == 'efectivo')
transfer    = sum(p['total'] for p in cobrados if p['metodo_pago'] == 'transferencia')
fiado       = sum(p['total'] for p in cobrados if p['metodo_pago'] == 'cuenta_corriente')

G = '\033[0;32m'; Y = '\033[1;33m'; R = '\033[0;31m'; M = '\033[0;37m'; B = '\033[1m'; NC = '\033[0m'

print(f"  {B}  Total vendido:{NC} \${total_hoy:,.0f}".replace(',','.'))
print(f"  {M}  Pedidos cobrados: {len(cobrados)}  |  Cancelados: {len(cancelados)}{NC}")
print(f"  {M}  Efectivo: \${efectivo:,.0f}  |  Transfer: \${transfer:,.0f}  |  Fiado: \${fiado:,.0f}{NC}".replace(',','.'))

if sin_cobrar:
    print(f"  {Y}!{NC}  {Y}{len(sin_cobrar)} pedido(s) SIN COBRAR:{NC}")
    for p in sin_cobrar[:5]:
        tipo = f"Mesa {p['mesa_numero']}" if p['tipo'] == 'mesa' else 'Barra'
        print(f"  {M}     #{str(p['numero']).zfill(3)} {tipo} — \${p['total']:,.0f}{NC}".replace(',','.'))
else:
    print(f"  {G}✓{NC}  Sin pedidos pendientes de cobro")
PYEOF
  else
    warn "No se pudo leer pedidos del día"
  fi

  sep

  # ── Base de datos ──────────────────────────────────────────────────
  echo -e "  ${BOLD}${BLUE}BASE DE DATOS${NC}"

  DB_PRODS=$(psql "postgresql://cantina:cantina2025@localhost:5432/cantina_pos" \
    -t -c "SELECT COUNT(*) FROM \"Producto\" WHERE activo=true;" 2>/dev/null | tr -d ' \n')
  DB_CLIENTES=$(psql "postgresql://cantina:cantina2025@localhost:5432/cantina_pos" \
    -t -c "SELECT COUNT(*) FROM \"Cliente\" WHERE activo=true;" 2>/dev/null | tr -d ' \n')
  DEUDA_TOTAL=$(psql "postgresql://cantina:cantina2025@localhost:5432/cantina_pos" \
    -t -c "SELECT COALESCE(SUM(saldo),0) FROM \"Cliente\" WHERE saldo>0;" 2>/dev/null | tr -d ' \n')

  if [ -n "$DB_PRODS" ]; then
    ok "DB conectada — Productos: ${DB_PRODS}  |  Clientes: ${DB_CLIENTES}  |  Deuda total: \$${DEUDA_TOTAL}"
  else
    fail "No se puede conectar a PostgreSQL"
  fi

  # Backup
  BACKUP_DIR="$(cd "$(dirname "$0")/.." && pwd)/backups"
  LAST_BACKUP=$(ls "$BACKUP_DIR"/*.sql 2>/dev/null | sort | tail -1)
  if [ -n "$LAST_BACKUP" ]; then
    AGE_H=$(( ($(date +%s) - $(stat -c %Y "$LAST_BACKUP")) / 3600 ))
    NAME=$(basename "$LAST_BACKUP")
    SIZE=$(du -h "$LAST_BACKUP" | cut -f1)
    [ "$AGE_H" -lt 25 ] \
      && ok "Backup: $NAME ($SIZE, hace ${AGE_H}h)" \
      || warn "Backup desactualizado: hace ${AGE_H}h — ejecutá scripts/backup.sh"
  else
    warn "Sin backups — ejecutá scripts/backup.sh"
  fi

  sep

  # ── Recursos ───────────────────────────────────────────────────────
  echo -e "  ${BOLD}${BLUE}RECURSOS${NC}"

  RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
  RAM_USED=$(free -m  | awk '/Mem:/ {print $3}')
  RAM_PCT=$((RAM_USED * 100 / RAM_TOTAL))
  [ "$RAM_PCT" -lt 80 ] \
    && ok "RAM: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)" \
    || warn "RAM alta: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)"

  DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
  DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
  DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
  [ "$DISK_PCT" -lt 85 ] \
    && ok "Disco: ${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT}%)" \
    || warn "Disco alto: ${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT}%)"

  UPTIME=$(uptime -p | sed 's/up //')
  ok "Uptime: $UPTIME"

  sep

  # ── Resultado ──────────────────────────────────────────────────────
  if [ "$ERRORES" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✓ TODO FUNCIONA CORRECTAMENTE${NC}"
  else
    echo -e "  ${RED}${BOLD}✗ $ERRORES PROBLEMA(S) DETECTADO(S) — ver detalles arriba${NC}"
  fi
  echo -e "  ${MUTED}Próximo chequeo en ${INTERVALO}s...${NC}"
  echo ""
}

# Loop principal
# Nota: para chequeo SSH del router instalar: sudo apt-get install -y sshpass
trap 'echo ""; echo "Monitor detenido."; exit 0' INT
while true; do
  check_all
  sleep "$INTERVALO"
done
