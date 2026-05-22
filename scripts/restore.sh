#!/bin/bash
# Restaura la base de datos desde un backup SQL
#
# Uso:
#   ./restore.sh                    → lista backups disponibles para elegir
#   ./restore.sh cantina_xxx.sql    → restaura ese archivo específico

set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$DIR/backups"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${BLUE}→${NC} $1"; }

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}   🗄️  Cantina POS — Restaurar base de datos${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── Seleccionar archivo de backup ──────────────

if [ -n "$1" ]; then
    # Archivo pasado como argumento
    if [ -f "$BACKUP_DIR/$1" ]; then
        BACKUP_FILE="$BACKUP_DIR/$1"
    elif [ -f "$1" ]; then
        BACKUP_FILE="$1"
    else
        echo -e "${RED}Error: no se encontró el archivo '$1'${NC}"
        echo "Backups disponibles en $BACKUP_DIR:"
        ls "$BACKUP_DIR"/*.sql 2>/dev/null | xargs -I{} basename {} || echo "  (ninguno)"
        exit 1
    fi
else
    # Listar solo backups normales (excluir pre_restore_*)
    BACKUPS=($(ls "$BACKUP_DIR"/cantina_*.sql 2>/dev/null | sort -r))
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo -e "${RED}No hay backups disponibles en $BACKUP_DIR${NC}"
        echo "Ejecutá primero: scripts/backup.sh"
        exit 1
    fi

    echo -e "Backups disponibles:\n"
    for i in "${!BACKUPS[@]}"; do
        FILE="${BACKUPS[$i]}"
        NAME=$(basename "$FILE")
        SIZE=$(du -h "$FILE" | cut -f1)
        AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "$FILE")) / 3600 ))
        echo -e "  ${BOLD}$((i+1))${NC}) $NAME  ${BLUE}($SIZE, hace ${AGE_HOURS}h)${NC}"
    done
    echo ""

    read -p "Elegí un número (Enter para el más reciente [1]): " CHOICE
    CHOICE="${CHOICE:-1}"

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#BACKUPS[@]} ]; then
        echo -e "${RED}Número inválido.${NC}"
        exit 1
    fi

    BACKUP_FILE="${BACKUPS[$((CHOICE-1))]}"
fi

BACKUP_NAME=$(basename "$BACKUP_FILE")
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo -e "Backup seleccionado: ${BOLD}$BACKUP_NAME${NC} ($BACKUP_SIZE)"
echo ""

# ── Confirmación ───────────────────────────────

echo -e "${YELLOW}⚠️  ADVERTENCIA: esto reemplaza TODOS los datos actuales.${NC}"
echo -e "${YELLOW}   Los pedidos, clientes y productos del sistema actual se perderán.${NC}"
echo ""
read -p "Escribí RESTAURAR para confirmar: " CONFIRM

if [ "$CONFIRM" != "RESTAURAR" ]; then
    echo "Operación cancelada."
    exit 0
fi

echo ""

# ── Backup de seguridad del estado actual ──────

EMERGENCY="$BACKUP_DIR/pre_restore_$(date +%Y%m%dT%H%M%S).sql"
info "Haciendo backup de seguridad del estado actual..."
if pg_dump cantina_pos > "$EMERGENCY"; then
    ok "Backup de seguridad: $(basename "$EMERGENCY")"
else
    echo -e "${RED}No se pudo hacer el backup de seguridad. Abortando.${NC}"
    exit 1
fi

# ── Detener backend ────────────────────────────

info "Deteniendo backend..."
sudo systemctl stop cantina-api
ok "Backend detenido"

# ── Restaurar ──────────────────────────────────

info "Limpiando base de datos actual..."
psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos \
    -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO cantina;" \
    -q
ok "Base de datos limpia"

info "Restaurando desde $BACKUP_NAME..."
if psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos < "$BACKUP_FILE" > /dev/null 2>&1; then
    ok "Datos restaurados"
else
    echo ""
    fail "Error durante la restauración"
    echo ""
    echo -e "${YELLOW}Intentando recuperar desde el backup de seguridad...${NC}"
    psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos \
        -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO cantina;" -q
    psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos < "$EMERGENCY" > /dev/null 2>&1
    ok "Estado anterior recuperado desde: $(basename "$EMERGENCY")"
    sudo systemctl start cantina-api
    exit 1
fi

# ── Reiniciar backend ──────────────────────────

info "Reiniciando backend..."
sudo systemctl start cantina-api

for i in $(seq 1 15); do
    sleep 1
    if curl -sf http://localhost:3001/api/health > /dev/null 2>&1; then
        ok "Backend activo (${i}s)"
        break
    fi
    if [ "$i" -eq 15 ]; then
        fail "El backend no respondió en 15 segundos"
        journalctl -u cantina-api -n 20 --no-pager
        exit 1
    fi
done

# ── Verificación ───────────────────────────────

echo ""
PEDIDOS=$(psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos -t \
    -c "SELECT COUNT(*) FROM \"Pedido\";" 2>/dev/null | tr -d ' ')
PRODUCTOS=$(psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos -t \
    -c "SELECT COUNT(*) FROM \"Producto\" WHERE activo = true;" 2>/dev/null | tr -d ' ')
CLIENTES=$(psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos -t \
    -c "SELECT COUNT(*) FROM \"Cliente\" WHERE activo = true;" 2>/dev/null | tr -d ' ')

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "   ${GREEN}${BOLD}✓ Restauración completada${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   Backup restaurado : $BACKUP_NAME"
echo -e "   Pedidos           : $PEDIDOS"
echo -e "   Productos activos : $PRODUCTOS"
echo -e "   Clientes activos  : $CLIENTES"
echo ""
echo -e "   ${BLUE}Backup de seguridad guardado en:${NC}"
echo -e "   $(basename "$EMERGENCY")"
echo ""
