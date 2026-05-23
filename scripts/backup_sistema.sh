#!/bin/bash
# Backup completo del sistema Cantina POS
# Incluye: base de datos, proyecto, configuración nginx y systemd
# Genera un .tar.gz que permite restaurar todo el sistema desde cero

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/backups/sistema"
DATE=$(date +%Y%m%dT%H%M%S)
NAME="cantina_sistema_${DATE}"
WORK_DIR="/tmp/${NAME}"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; exit 1; }
info() { echo -e "  ${BLUE}→${NC} $1"; }

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}   Cantina POS — Backup completo del sistema${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "   $(date '+%d/%m/%Y %H:%M:%S')"
echo ""

mkdir -p "$BACKUP_DIR"
mkdir -p "$WORK_DIR/db"
mkdir -p "$WORK_DIR/proyecto"
mkdir -p "$WORK_DIR/sistema/nginx"
mkdir -p "$WORK_DIR/sistema/systemd"

# ── 1. Base de datos ───────────────────────────────
info "Volcando base de datos..."
if pg_dump cantina_pos > "$WORK_DIR/db/cantina_pos.sql"; then
    DB_SIZE=$(du -h "$WORK_DIR/db/cantina_pos.sql" | cut -f1)
    ok "Base de datos ($DB_SIZE)"
else
    fail "Error al volcar la base de datos"
fi

# ── 2. Proyecto ────────────────────────────────────
info "Copiando proyecto (sin node_modules)..."
rsync -a \
    --exclude='node_modules' \
    --exclude='client/node_modules' \
    --exclude='.git' \
    --exclude='backups' \
    "$ROOT_DIR/" "$WORK_DIR/proyecto/"
ok "Proyecto copiado"

# ── 3. Configuración del sistema ───────────────────
info "Copiando configuración del sistema..."

cp /etc/nginx/sites-available/cantina    "$WORK_DIR/sistema/nginx/cantina"          2>/dev/null && ok "nginx: sites-available/cantina" || echo -e "  ${YELLOW}!${NC} nginx config no encontrada"
cp /etc/systemd/system/cantina-api.service                    "$WORK_DIR/sistema/systemd/cantina-api.service"       && ok "systemd: cantina-api.service"
cp /etc/systemd/system/nginx.service.d/restart.conf           "$WORK_DIR/sistema/systemd/nginx-restart.conf"        2>/dev/null && ok "systemd: nginx restart.conf" || true
cp /etc/systemd/system/postgresql@18-main.service.d/restart.conf "$WORK_DIR/sistema/systemd/postgresql-restart.conf" 2>/dev/null && ok "systemd: postgresql restart.conf" || true

# ── 4. RESTORE.md ──────────────────────────────────
info "Generando instrucciones de restauración..."
cat > "$WORK_DIR/RESTORE.md" << 'RESTORE'
# Restauración completa — Cantina POS

Este archivo contiene todo lo necesario para levantar el sistema desde cero.

## Contenido del backup

```
db/
  cantina_pos.sql          Base de datos completa (pg_dump)
proyecto/                  Código fuente del proyecto
sistema/
  nginx/cantina            Configuración nginx
  systemd/
    cantina-api.service    Servicio systemd del backend
    nginx-restart.conf     Override Restart para nginx
    postgresql-restart.conf Override Restart para PostgreSQL
```

---

## Requisitos previos

```bash
# Node.js 20+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# PostgreSQL 18
sudo apt install -y postgresql postgresql-contrib

# nginx
sudo apt install -y nginx
```

---

## Paso 1 — Usuario del sistema

```bash
sudo adduser cantina          # crear usuario si no existe
sudo usermod -aG sudo cantina
```

---

## Paso 2 — Proyecto

```bash
sudo cp -r proyecto/ /home/cantina/cantina-pos
sudo chown -R cantina:cantina /home/cantina/cantina-pos
cd /home/cantina/cantina-pos
npm install
cd client && npm install && npm run build && cd ..
```

---

## Paso 3 — Base de datos

```bash
# Crear usuario y base de datos
sudo -u postgres psql -c "CREATE USER cantina WITH PASSWORD 'cantina2025';"
sudo -u postgres psql -c "CREATE DATABASE cantina_pos OWNER cantina;"

# Restaurar datos
psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos < db/cantina_pos.sql
```

---

## Paso 4 — Configuración nginx

```bash
sudo cp sistema/nginx/cantina /etc/nginx/sites-available/cantina
sudo ln -sf /etc/nginx/sites-available/cantina /etc/nginx/sites-enabled/cantina
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

---

## Paso 5 — Servicios systemd

```bash
# cantina-api
sudo cp sistema/systemd/cantina-api.service /etc/systemd/system/cantina-api.service

# nginx restart override
sudo mkdir -p /etc/systemd/system/nginx.service.d
sudo cp sistema/systemd/nginx-restart.conf /etc/systemd/system/nginx.service.d/restart.conf

# postgresql restart override
sudo mkdir -p /etc/systemd/system/postgresql@18-main.service.d
sudo cp sistema/systemd/postgresql-restart.conf /etc/systemd/system/postgresql@18-main.service.d/restart.conf

# Recargar y habilitar
sudo systemctl daemon-reload
sudo systemctl enable postgresql cantina-api nginx
sudo systemctl start postgresql cantina-api nginx
```

---

## Paso 6 — Verificar

```bash
bash /home/cantina/cantina-pos/scripts/healthcheck.sh
```

Todo debería mostrar ✓. Si hay problemas:

```bash
journalctl -u cantina-api -n 50
journalctl -u nginx -n 20
```

---

## Acceso

- App principal: `http://<IP-del-servidor>/`
- Cocina: `http://<IP-del-servidor>/cocina.html`
- Autoservicio: `http://<IP-del-servidor>/autoservicio.html`

RESTORE
ok "RESTORE.md generado"

# ── 5. Empaquetar ──────────────────────────────────
info "Empaquetando..."
TAR_FILE="$BACKUP_DIR/${NAME}.tar.gz"
tar -czf "$TAR_FILE" -C /tmp "$NAME"
TAR_SIZE=$(du -h "$TAR_FILE" | cut -f1)
ok "Archivo: backups/sistema/${NAME}.tar.gz ($TAR_SIZE)"

# Limpiar directorio temporal
rm -rf "$WORK_DIR"

# Mantener los últimos 10 backups de sistema
COUNT=$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ "$COUNT" -gt 10 ]; then
    TO_DELETE=$((COUNT - 10))
    ls "$BACKUP_DIR"/*.tar.gz | sort | head -"$TO_DELETE" | xargs rm -f
    echo -e "  ${YELLOW}!${NC} Backups antiguos eliminados: $TO_DELETE"
fi

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${BOLD}✓ Backup completo guardado${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Para restaurar desde cero:"
echo -e "  ${YELLOW}tar -xzf backups/sistema/${NAME}.tar.gz${NC}"
echo -e "  ${YELLOW}cat ${NAME}/RESTORE.md${NC}"
echo ""

echo "Backups de sistema disponibles:"
ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{print "  " $NF " (" $5 ")"}' | sed "s|$BACKUP_DIR/||"
echo ""
