#!/bin/bash
# Estado completo del sistema Cantina POS
# Muestra de un vistazo si todo funciona bien

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; MUTED='\033[0;37m'; NC='\033[0m'; BOLD='\033[1m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS+1)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
ERRORS=0

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}   🍽️  Cantina POS — Estado del sistema${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "   $(date '+%d/%m/%Y %H:%M:%S')"
echo ""

# ── Servicios ──────────────────────────────────
echo -e "${BLUE}Servicios${NC}"

systemctl is-active postgresql -q \
    && ok "PostgreSQL" \
    || fail "PostgreSQL (sudo systemctl restart postgresql)"

systemctl is-active cantina-api -q \
    && ok "Backend (cantina-api)" \
    || fail "Backend (scripts/restart_backend.sh)"

systemctl is-active nginx -q \
    && ok "Nginx" \
    || fail "Nginx (sudo systemctl restart nginx)"

# ── API ────────────────────────────────────────
echo ""
echo -e "${BLUE}API${NC}"

if curl -sf http://localhost:3001/api/health > /dev/null 2>&1; then
    ok "Backend responde en :3001"
else
    fail "Backend no responde en :3001"
fi

if curl -sf http://localhost:80/api/health > /dev/null 2>&1; then
    ok "Nginx proxya correctamente (:80 → :3001)"
else
    fail "Nginx no proxya (:80)"
fi

# ── Base de datos ──────────────────────────────
echo ""
echo -e "${BLUE}Base de datos${NC}"

if psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos -c "SELECT 1" -q > /dev/null 2>&1; then
    PEDIDOS_HOY=$(psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos -t -c \
        "SELECT COUNT(*) FROM \"Pedido\" WHERE \"createdAt\" >= CURRENT_DATE;" 2>/dev/null | tr -d ' ')
    PRODUCTOS=$(psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos -t -c \
        "SELECT COUNT(*) FROM \"Producto\" WHERE activo = true;" 2>/dev/null | tr -d ' ')
    ok "Conexión OK — Pedidos hoy: ${PEDIDOS_HOY} | Productos activos: ${PRODUCTOS}"
else
    fail "No se puede conectar a PostgreSQL"
fi

# ── Recursos ───────────────────────────────────
echo ""
echo -e "${BLUE}Recursos${NC}"

RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_PCT=$((RAM_USED * 100 / RAM_TOTAL))
[ "$RAM_PCT" -lt 80 ] && ok "RAM: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)" \
    || warn "RAM alta: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)"

DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
[ "$DISK_PCT" -lt 85 ] && ok "Disco: ${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT}%)" \
    || warn "Disco alto: ${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT}%)"

UPTIME=$(uptime -p | sed 's/up //')
ok "Uptime: $UPTIME"

IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
ok "IP local: $IP"

# ── Backups ────────────────────────────────────
echo ""
echo -e "${BLUE}Backups${NC}"

BACKUP_DIR="$(cd "$(dirname "$0")/.." && pwd)/backups"
LAST=$(ls "$BACKUP_DIR"/*.sql 2>/dev/null | sort | tail -1)
if [ -n "$LAST" ]; then
    AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "$LAST")) / 3600 ))
    LAST_NAME=$(basename "$LAST")
    LAST_SIZE=$(du -h "$LAST" | cut -f1)
    [ "$AGE_HOURS" -lt 25 ] \
        && ok "Último backup: $LAST_NAME ($LAST_SIZE, hace ${AGE_HOURS}h)" \
        || warn "Backup desactualizado: $LAST_NAME (hace ${AGE_HOURS}h) — ejecutá scripts/backup.sh"
else
    warn "Sin backups — ejecutá scripts/backup.sh"
fi

# ── Resultado ──────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "   ${GREEN}${BOLD}✓ Sistema operativo${NC}"
else
    echo -e "   ${RED}${BOLD}✗ $ERRORS problema(s) detectado(s)${NC}"
fi
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
