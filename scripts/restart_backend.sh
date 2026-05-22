#!/bin/bash
# Reinicia solo el backend Node.js (cantina-api)
# Útil cuando la app no responde pero la DB está bien

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}🔄 Reiniciando backend Cantina POS...${NC}"

sudo systemctl restart cantina-api

# Esperar hasta 10 segundos a que levante
for i in $(seq 1 10); do
    sleep 1
    if curl -sf http://localhost:3001/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Backend activo (${i}s)${NC}"
        echo ""
        systemctl status cantina-api --no-pager -l | grep -E "Active:|Main PID:|Memory:"
        exit 0
    fi
    echo -n "."
done

echo ""
echo -e "${RED}✗ El backend no respondió en 10 segundos${NC}"
echo ""
echo "Últimas líneas del log:"
journalctl -u cantina-api -n 20 --no-pager
exit 1
