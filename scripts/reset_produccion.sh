#!/bin/bash
# Reset a producción: borra todos los datos de prueba y deja el sistema base.
# Conserva: usuarios (para poder loguear).
# Borra: productos, categorías, clientes, pedidos, cierres, carrusel.
#
# USO: bash scripts/reset_produccion.sh
# Requiere confirmación doble antes de ejecutar.

set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$DIR/backups"
IMAGES_DIR="$DIR/images"
DATE=$(date +%Y%m%dT%H%M%S)

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${RED}${BOLD}⚠️  RESET A PRODUCCIÓN — CANTINA POS${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Este script borra TODOS los datos de prueba:"
echo ""
echo "  ❌  Pedidos e items"
echo "  ❌  Cierres de caja"
echo "  ❌  Clientes y pagos"
echo "  ❌  Productos"
echo "  ❌  Categorías"
echo "  ❌  Imágenes del carrusel TV"
echo ""
echo "  ✅  Usuarios (se conservan para poder loguear)"
echo ""
echo -e "${YELLOW}Antes de continuar, hace un backup de prueba si querés.${NC}"
echo ""

# Confirmación 1
read -p "¿Estás seguro? Escribí 'SI BORRAR' para continuar: " CONFIRM1
if [ "$CONFIRM1" != "SI BORRAR" ]; then
    echo "Cancelado."
    exit 0
fi

# Confirmación 2
echo ""
read -p "Segunda confirmación — escribí 'PRODUCCION' para ejecutar: " CONFIRM2
if [ "$CONFIRM2" != "PRODUCCION" ]; then
    echo "Cancelado."
    exit 0
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. Backup automático pre-reset
echo ""
echo -n "📦 Backup de seguridad pre-reset... "
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="pre_reset_${DATE}.sql"
if pg_dump cantina_pos > "$BACKUP_DIR/$BACKUP_FILE"; then
    SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✓ OK${NC} (backups/$BACKUP_FILE — $SIZE)"
else
    echo -e "${RED}✗ Error en el backup. Abortando.${NC}"
    exit 1
fi

# 2. Borrar datos en orden correcto (respeta FK)
echo ""
echo -n "🗑  Borrando pedidos e items... "
psql cantina_pos -c "TRUNCATE TABLE \"PedidoItem\" RESTART IDENTITY CASCADE;" -q
psql cantina_pos -c "TRUNCATE TABLE \"Pedido\" RESTART IDENTITY CASCADE;" -q
echo -e "${GREEN}✓${NC}"

echo -n "🗑  Borrando cierres de caja... "
psql cantina_pos -c "TRUNCATE TABLE \"CierreCaja\" RESTART IDENTITY CASCADE;" -q
echo -e "${GREEN}✓${NC}"

echo -n "🗑  Borrando clientes y pagos... "
psql cantina_pos -c "TRUNCATE TABLE \"ClientePago\" RESTART IDENTITY CASCADE;" -q
psql cantina_pos -c "TRUNCATE TABLE \"Cliente\" RESTART IDENTITY CASCADE;" -q
echo -e "${GREEN}✓${NC}"

echo -n "🗑  Borrando productos... "
psql cantina_pos -c "TRUNCATE TABLE \"Producto\" RESTART IDENTITY CASCADE;" -q
echo -e "${GREEN}✓${NC}"

echo -n "🗑  Borrando categorías... "
psql cantina_pos -c "TRUNCATE TABLE \"Categoria\" RESTART IDENTITY CASCADE;" -q
echo -e "${GREEN}✓${NC}"

echo -n "🗑  Borrando carrusel TV (DB)... "
psql cantina_pos -c "TRUNCATE TABLE \"CarouselImage\" RESTART IDENTITY CASCADE;" -q
echo -e "${GREEN}✓${NC}"

echo -n "🗑  Borrando imágenes del carrusel (archivos)... "
if [ -d "$IMAGES_DIR" ]; then
    COUNT=$(find "$IMAGES_DIR" -maxdepth 1 -type f | wc -l)
    find "$IMAGES_DIR" -maxdepth 1 -type f -delete
    echo -e "${GREEN}✓${NC} ($COUNT archivos)"
else
    echo -e "${GREEN}✓${NC} (directorio vacío)"
fi

# 3. Verificar usuarios conservados
echo ""
USUARIOS=$(psql cantina_pos -t -c "SELECT COUNT(*) FROM \"Usuario\";" | tr -d ' ')
echo -e "${GREEN}✓ Usuarios conservados: $USUARIOS${NC}"

# 4. Backup post-reset (estado limpio)
echo ""
echo -n "📦 Backup del estado limpio... "
CLEAN_FILE="base_produccion_${DATE}.sql"
if pg_dump cantina_pos > "$BACKUP_DIR/$CLEAN_FILE"; then
    SIZE=$(du -h "$BACKUP_DIR/$CLEAN_FILE" | cut -f1)
    echo -e "${GREEN}✓ OK${NC} (backups/$CLEAN_FILE — $SIZE)"
fi

echo ""
echo -e "${GREEN}${BOLD}✅ Reset completado.${NC}"
echo ""
echo "  Próximos pasos:"
echo "  1. Cargar categorías reales (Admin → Categorías)"
echo "  2. Cargar carta de productos (Admin → Productos)"
echo "  3. Cargar clientes con cuenta corriente (Cuentas → Nuevo cliente)"
echo "  4. Subir imágenes al carrusel TV (Sistema → Carrusel)"
echo "  5. Hacer primer backup real: bash scripts/backup.sh"
echo ""
