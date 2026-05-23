#!/bin/bash
# Dashboard interactivo Cantina POS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MUTED='\033[0;37m'
BOLD='\033[1m'; NC='\033[0m'

DB_URL="postgresql://cantina:cantina2025@localhost:5432/cantina_pos"

# ── Mostrar estado ─────────────────────────────────
show_status() {
    clear
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}   Cantina POS — Panel de control${NC}   ${MUTED}$(date '+%d/%m/%Y %H:%M:%S')${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "  ${BLUE}ESTADO DEL SISTEMA${NC}"
    systemctl is-active postgresql -q \
        && echo -e "  ${GREEN}✓${NC} Base de datos (PostgreSQL)" \
        || echo -e "  ${RED}✗${NC} Base de datos NO funciona"
    systemctl is-active cantina-api -q \
        && echo -e "  ${GREEN}✓${NC} Aplicación (cantina-api)" \
        || echo -e "  ${RED}✗${NC} Aplicación NO funciona"
    systemctl is-active nginx -q \
        && echo -e "  ${GREEN}✓${NC} Servidor web (nginx)" \
        || echo -e "  ${RED}✗${NC} Servidor web NO funciona"
    curl -sf http://localhost:3001/api/health > /dev/null 2>&1 \
        && echo -e "  ${GREEN}✓${NC} La app responde correctamente" \
        || echo -e "  ${RED}✗${NC} La app NO responde"

    echo ""
    echo -e "  ${BLUE}RECURSOS${NC}"
    RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    RAM_USED=$(free -m  | awk '/Mem:/ {print $3}')
    RAM_PCT=$((RAM_USED * 100 / RAM_TOTAL))
    DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    UPTIME=$(uptime -p | sed 's/up //')
    IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')

    [ "$RAM_PCT" -lt 80 ] \
        && echo -e "  ${GREEN}✓${NC} Memoria RAM: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)" \
        || echo -e "  ${YELLOW}!${NC} Memoria RAM alta: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)"
    [ "$DISK_PCT" -lt 85 ] \
        && echo -e "  ${GREEN}✓${NC} Disco: ${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT}%)" \
        || echo -e "  ${YELLOW}!${NC} Disco casi lleno: ${DISK_USED} / ${DISK_TOTAL} (${DISK_PCT}%)"
    echo -e "  ${MUTED}   Encendido hace: $UPTIME  |  IP: $IP${NC}"

    echo ""
    echo -e "  ${BLUE}DATOS${NC}"
    if psql "$DB_URL" -c "SELECT 1" -q > /dev/null 2>&1; then
        PEDIDOS_HOY=$(psql "$DB_URL" -t -c \
            "SELECT COUNT(*) FROM \"Pedido\" WHERE \"createdAt\" >= CURRENT_DATE;" 2>/dev/null | tr -d ' ')
        PRODUCTOS=$(psql "$DB_URL" -t -c \
            "SELECT COUNT(*) FROM \"Producto\" WHERE activo = true;" 2>/dev/null | tr -d ' ')
        echo -e "  ${GREEN}✓${NC} Pedidos de hoy: ${PEDIDOS_HOY}  |  Productos activos: ${PRODUCTOS}"
    else
        echo -e "  ${RED}✗${NC} No se puede leer la base de datos"
    fi

    LAST=$(ls "$ROOT_DIR/backups"/*.sql 2>/dev/null | sort | tail -1)
    if [ -n "$LAST" ]; then
        AGE_H=$(( ($(date +%s) - $(stat -c %Y "$LAST")) / 3600 ))
        LAST_NAME=$(basename "$LAST")
        LAST_SIZE=$(du -h "$LAST" | cut -f1)
        [ "$AGE_H" -lt 25 ] \
            && echo -e "  ${GREEN}✓${NC} Última copia de seguridad: hace ${AGE_H}h ($LAST_SIZE)" \
            || echo -e "  ${YELLOW}!${NC} Copia de seguridad desactualizada: hace ${AGE_H}h — usar opción 3"
    else
        echo -e "  ${YELLOW}!${NC} Sin copias de seguridad — usar opción 3"
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ── Menú ───────────────────────────────────────────
show_menu() {
    echo -e "  ${CYAN}¿Qué querés hacer?${NC}"
    echo ""
    echo -e "  ${BOLD}[1]${NC}  Reiniciar la aplicación"
    echo -e "  ${BOLD}[2]${NC}  Reiniciar todo el sistema"
    echo -e "  ${BOLD}[3]${NC}  Guardar copia de seguridad (datos)"
    echo -e "  ${BOLD}[4]${NC}  Guardar copia de seguridad completa"
    echo -e "  ${BOLD}[5]${NC}  Ver registros de la aplicación"
    echo -e "  ${BOLD}[6]${NC}  Ver registros del servidor web"
    echo -e "  ${BOLD}[7]${NC}  Actualizar pantalla"
    echo -e "  ${BOLD}[q]${NC}  Salir"
    echo ""
    echo -n "  Presioná el número de la acción: "
}

# ── Pantalla de confirmación ───────────────────────
# Devuelve 0 si el usuario presionó ENTER, 1 si presionó cualquier otra tecla
confirmar() {
    local titulo="$1"
    local descripcion="$2"
    clear
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}   ${YELLOW}⚠  $titulo${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  $descripcion"
    echo ""
    echo -e "  Presioná  ${GREEN}${BOLD}ENTER${NC}  para continuar"
    echo -e "  Presioná  ${MUTED}cualquier otra tecla${NC}  para cancelar"
    echo ""
    read -r -n 1 key
    [[ "$key" == "" ]]
}

# ── Pausa antes de volver al menú ─────────────────
volver() {
    echo ""
    echo -e "  ${MUTED}─────────────────────────────────────────────────${NC}"
    echo -e "  ${MUTED}Presioná cualquier tecla para volver al menú...${NC}"
    read -r -n 1 -s
}

# ── Loop principal ─────────────────────────────────
while true; do
    show_status
    show_menu
    read -r -n 1 OPT
    echo ""
    echo ""

    case "$OPT" in

        1)  # Reiniciar la aplicación
            confirmar \
                "Reiniciar la aplicación" \
                "La cantina no estará disponible por unos segundos mientras reinicia." \
            || continue
            echo ""
            bash "$SCRIPT_DIR/restart_backend.sh"
            volver
            ;;

        2)  # Reiniciar todo el sistema
            confirmar \
                "Reiniciar TODO el sistema" \
                "Se van a reiniciar la base de datos, la aplicación y el servidor web.\n  La cantina no estará disponible por aproximadamente 20 segundos." \
            || continue
            echo ""
            bash "$SCRIPT_DIR/restart_all.sh"
            volver
            ;;

        3)  # Backup de datos
            echo -e "  Guardando copia de seguridad de los datos..."
            echo ""
            bash "$SCRIPT_DIR/backup.sh"
            volver
            ;;

        4)  # Backup sistema completo
            confirmar \
                "Copia de seguridad completa" \
                "Se va a guardar una copia de todo el sistema.\n  Esto puede tardar hasta 30 segundos." \
            || continue
            echo ""
            bash "$SCRIPT_DIR/backup_sistema.sh"
            volver
            ;;

        5)  # Logs backend
            clear
            echo -e "${BOLD}Registros de la aplicación — últimas 60 líneas${NC}"
            echo ""
            journalctl -u cantina-api -n 60 --no-pager
            echo ""
            echo -e "  ${MUTED}[f] ver en tiempo real  |  cualquier otra tecla para volver${NC}"
            read -r -n 1 resp
            [[ "$resp" == "f" ]] && journalctl -u cantina-api -f --no-pager
            ;;

        6)  # Logs nginx
            clear
            echo -e "${BOLD}Registros del servidor web${NC}"
            echo ""
            echo -e "${BLUE}Errores (últimas 40 líneas):${NC}"
            echo ""
            tail -40 /var/log/nginx/cantina.error.log 2>/dev/null || echo "  (sin errores registrados)"
            echo ""
            echo -e "${BLUE}Accesos recientes (últimas 20 líneas):${NC}"
            echo ""
            tail -20 /var/log/nginx/cantina.access.log 2>/dev/null || echo "  (sin accesos registrados)"
            volver
            ;;

        7|"")
            ;;

        q|Q)
            echo ""
            exit 0
            ;;
    esac
done
