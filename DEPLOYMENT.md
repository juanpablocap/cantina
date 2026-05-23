# Instalación desde cero — Cantina POS

Para reinstalar en un servidor existente, usar el backup completo del sistema (ver [BACKUP_GUIDE.md](BACKUP_GUIDE.md)).

Esta guía es para una instalación nueva en hardware limpio.

---

## Requisitos

- Ubuntu 22.04+ (probado en 26.04)
- 2 GB RAM mínimo (recomendado 4 GB+)
- 20 GB disco mínimo
- Acceso a internet para la instalación (luego funciona offline)

---

## Paso 1 — Crear usuario

```bash
sudo adduser cantina
sudo usermod -aG sudo cantina
su - cantina
```

---

## Paso 2 — Instalar dependencias

```bash
# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# PostgreSQL 18
sudo apt install -y postgresql postgresql-contrib

# Nginx
sudo apt install -y nginx

# Herramientas útiles
sudo apt install -y git curl rsync
```

---

## Paso 3 — Clonar o copiar el proyecto

### Opción A: desde git

```bash
cd /home/cantina
git clone <url-del-repo> cantina-pos
cd cantina-pos
```

### Opción B: desde backup de sistema

```bash
tar -xzf cantina_sistema_YYYYMMDDTHHMMSS.tar.gz
cp -r cantina_sistema_YYYYMMDDTHHMMSS/proyecto /home/cantina/cantina-pos
```

---

## Paso 4 — Instalar dependencias Node.js

```bash
cd /home/cantina/cantina-pos
npm install
cd client && npm install && npm run build && cd ..
```

---

## Paso 5 — Base de datos

```bash
# Crear usuario y base de datos
sudo -u postgres psql -c "CREATE USER cantina WITH PASSWORD 'cantina2025';"
sudo -u postgres psql -c "CREATE DATABASE cantina_pos OWNER cantina;"

# Ejecutar migraciones
npx prisma migrate deploy

# Cargar datos iniciales (primera vez)
node seed.js
node seed-clientes.js
```

Si se restaura desde backup:
```bash
psql postgresql://cantina:cantina2025@localhost:5432/cantina_pos < backups/cantina_YYYYMMDDTHHMMSS.sql
```

---

## Paso 6 — Variables de entorno

El archivo `.env` se usa solo en desarrollo. En producción las variables van en el service de systemd (ya incluidas en el archivo del Paso 7).

Crear `.env` para desarrollo local:
```bash
cat > .env << 'EOF'
DATABASE_URL="postgresql://cantina:cantina2025@localhost:5432/cantina_pos"
PORT=3001
NODE_ENV=production
EOF
```

---

## Paso 7 — Servicios systemd

```bash
# Servicio del backend
sudo cp scripts/setup_autorestart.sh /tmp/
sudo bash /tmp/setup_autorestart.sh

# O instalar manualmente:
sudo tee /etc/systemd/system/cantina-api.service << 'EOF'
[Unit]
Description=Cantina POS API
After=network.target postgresql@18-main.service
Requires=postgresql@18-main.service

[Service]
Type=simple
User=cantina
WorkingDirectory=/home/cantina/cantina-pos
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production
Environment=DATABASE_URL=postgresql://cantina:cantina2025@localhost:5432/cantina_pos
Environment=PORT=3001

[Install]
WantedBy=multi-user.target
EOF

# Override restart para nginx
sudo mkdir -p /etc/systemd/system/nginx.service.d
sudo tee /etc/systemd/system/nginx.service.d/restart.conf << 'EOF'
[Unit]
After=cantina-api.service

[Service]
Restart=always
RestartSec=5
ExecStartPre=/home/cantina/cantina-pos/scripts/wait_for_backend.sh
EOF

sudo systemctl daemon-reload
sudo systemctl enable cantina-api nginx postgresql
```

---

## Paso 8 — Configurar nginx

```bash
sudo tee /etc/nginx/sites-available/cantina << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    access_log /var/log/nginx/cantina.access.log;
    error_log  /var/log/nginx/cantina.error.log;

    location /socket.io/ {
        proxy_pass         http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade    $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host       $host;
    }

    location / {
        proxy_pass         http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header   Host            $host;
        proxy_set_header   X-Real-IP       $remote_addr;
        proxy_read_timeout 60s;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/cantina /etc/nginx/sites-enabled/cantina
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
```

---

## Paso 9 — Arrancar todo

```bash
bash scripts/restart_all.sh
```

---

## Paso 10 — Verificar

```bash
bash scripts/healthcheck.sh
```

Todo debería mostrar ✓. Abrir `http://<IP-del-servidor>/` en un navegador para confirmar.

---

## Configurar inicio automático del kiosk (tablets)

Ver guía específica en `KIOSK.md` (pendiente).

---

## Primer uso

1. Ingresar a `http://<IP>/`
2. El PIN por defecto del admin es el que se configuró en `seed.js`
3. Ir a **Productos** para configurar el menú
4. Ir a **Usuarios** para crear los usuarios del sistema

## URLs disponibles tras la instalación

| URL | Pantalla |
|---|---|
| `http://<IP>/` | POS principal — caja, cocina, admin |
| `http://<IP>/cocina.html` | Vista cocina |
| `http://<IP>/autoservicio.html` | Autoservicio para clientes |
| `http://<IP>/promo.html` | TV del salón — carrusel de promociones |

El TV del salón debe apuntar a `http://<IP>/promo.html`. Las imágenes se gestionan desde la pestaña **Sistema** del POS principal (botón **📁 Abrir archivos** → seleccionar imágenes del pendrive → **📥 Importar todas**).
