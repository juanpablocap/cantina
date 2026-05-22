#!/bin/bash
# Reinicia todos los servicios en el orden correcto:
# PostgreSQL → cantina-api → nginx
# Usar cuando el sistema está en un estado desconocido o tras un problema grave

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

ok() { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; }
info() { echo -e "${BLUE}→ $1${NC}"; }

echo -e "${YELLOW}🔄 Reinicio completo del sistema Cantina POS${NC}"
echo "$(date '+%d/%m/%Y %H:%M:%S')"
echo ""

# 1. PostgreSQL
info "Reiniciando PostgreSQL..."
if sudo systemctl restart postgresql; then
    sleep 2
    if sudo systemctl is-active postgresql -q; then
        ok "PostgreSQL activo"
    else
        fail "PostgreSQL no levantó"
        journalctl -u postgresql -n 10 --no-pager
        exit 1
    fi
else
    fail "Error al reiniciar PostgreSQL"
    exit 1
fi

# 2. Backend
info "Reiniciando backend (cantina-api)..."
sudo systemctl restart cantina-api
for i in $(seq 1 15); do
    sleep 1
    if curl -sf http://localhost:3001/api/health > /dev/null 2>&1; then
        ok "Backend activo (${i}s)"
        break
    fi
    if [ "$i" -eq 15 ]; then
        fail "Backend no respondió en 15 segundos"
        journalctl -u cantina-api -n 20 --no-pager
        exit 1
    fi
    echo -n "."
done

# 3. Nginx
info "Reiniciando nginx..."
if sudo systemctl restart nginx; then
    sleep 1
    if sudo systemctl is-active nginx -q; then
        ok "Nginx activo"
    else
        fail "Nginx no levantó"
        journalctl -u nginx -n 10 --no-pager
        exit 1
    fi
else
    fail "Error al reiniciar nginx"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Sistema completamente operativo${NC}"
echo ""

# Verificación final
if curl -sf http://localhost:80/api/health > /dev/null 2>&1; then
    ok "API accesible en puerto 80"
else
    fail "API no responde en puerto 80"
fi
