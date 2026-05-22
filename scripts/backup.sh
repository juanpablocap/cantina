#!/bin/bash
# Backup de la base de datos PostgreSQL
# Guarda en backups/ con timestamp, mantiene los últimos 30

set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$DIR/backups"
DATE=$(date +%Y%m%dT%H%M%S)
FILE="cantina_${DATE}.sql"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}📦 Backup Cantina POS${NC}"
echo "Fecha: $(date '+%d/%m/%Y %H:%M:%S')"
echo ""

mkdir -p "$BACKUP_DIR"

echo -n "Creando backup... "
if pg_dump cantina_pos > "$BACKUP_DIR/$FILE"; then
    SIZE=$(du -h "$BACKUP_DIR/$FILE" | cut -f1)
    echo -e "${GREEN}✓ OK${NC} ($SIZE)"
else
    echo -e "${RED}✗ Error al crear el backup${NC}"
    exit 1
fi

# Mantener solo los últimos 30
COUNT=$(ls "$BACKUP_DIR"/*.sql 2>/dev/null | wc -l)
if [ "$COUNT" -gt 30 ]; then
    TO_DELETE=$((COUNT - 30))
    ls "$BACKUP_DIR"/*.sql | sort | head -"$TO_DELETE" | xargs rm -f
    echo "Backups antiguos eliminados: $TO_DELETE"
fi

echo ""
echo -e "${GREEN}✓ Backup guardado: backups/$FILE${NC}"
echo ""
echo "Backups disponibles:"
ls -lh "$BACKUP_DIR"/*.sql 2>/dev/null | awk '{print "  " $NF " (" $5 ")"}' | sed "s|$BACKUP_DIR/||"
