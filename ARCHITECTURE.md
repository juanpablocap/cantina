# Arquitectura — Cantina POS

## Visión general

Sistema POS para cantina que corre 100% en LAN/offline. Un servidor Ubuntu con Node.js sirve la API y el frontend estático. Las tablets acceden por IP local vía Chromium.

```
[Tablet/Browser]
      │ HTTP :80
      ▼
   [Nginx]  ← reverse proxy
      │ HTTP :3001
      ▼
  [Node.js]  (cantina-api)
      │
      ▼
 [PostgreSQL]  :5432
```

---

## Estructura del proyecto

```
cantina-pos/
├── server.js                  # Backend único (Express + Socket.io + Prisma)
├── package.json
├── prisma/
│   └── schema.prisma          # Esquema de base de datos
├── client/
│   ├── src/                   # Fuente React/Vite (para desarrollo)
│   └── dist/                  # Frontend compilado (lo que se sirve en prod)
│       ├── index.html         # App POS principal (caja, cocina, admin)
│       ├── autoservicio.html  # Vista autoservicio para tablets clientes
│       ├── cocina.html        # Vista simplificada para cocina
│       ├── promo.html         # TV del salón — carrusel de imágenes promo
│       ├── vendor/            # React, ReactDOM, Babel (offline, sin CDN)
│       └── fonts/             # Fuentes tipográficas (offline, sin CDN)
├── scripts/
│   ├── healthcheck.sh         # Estado completo del sistema
│   ├── backup.sh              # pg_dump con timestamp, retiene últimos 30
│   ├── restore.sh             # Restaura backup con auto-backup previo
│   ├── restart_backend.sh     # Reinicia cantina-api con health check
│   ├── restart_all.sh         # Reinicio ordenado: postgresql → api → nginx
│   └── setup_autorestart.sh   # Configura Restart= en systemd (correr una sola vez)
├── backups/                   # Archivos .sql generados por backup.sh o la API
├── images/                    # Imágenes de productos (servidas como estático)
├── seed.js                    # Datos iniciales de productos/categorías
├── seed-clientes.js           # Datos iniciales de clientes
├── MASTER_CONTEXT.md          # Contexto y filosofía del proyecto
├── PROJECT_TODO.md            # Lista de tareas pendientes
└── ARCHITECTURE.md            # Este archivo
```

---

## Servicios systemd

| Servicio               | Puerto | Restart         | Habilitado |
|------------------------|--------|-----------------|------------|
| cantina-api.service    | 3001   | always (5s)     | sí         |
| nginx.service          | 80     | always (5s)     | sí         |
| postgresql@18-main     | 5432   | on-failure (10s)| sí         |

Archivos de servicio:
- `/etc/systemd/system/cantina-api.service` — definición principal
- `/etc/systemd/system/nginx.service.d/restart.conf` — override Restart=always
- `/etc/systemd/system/postgresql@18-main.service.d/restart.conf` — override Restart=on-failure

---

## Backend (server.js)

Un solo archivo Node.js con Express. Usa Prisma como ORM sobre PostgreSQL.

### Rutas API

**Sistema**
| Método | Ruta                          | Descripción                        |
|--------|-------------------------------|------------------------------------|
| GET    | /api/health                   | Health check simple                |
| GET    | /api/system                   | CPU, RAM, disco, servicios, backup |
| POST   | /api/system/restart/:service  | Reinicia cantina-api o postgresql  |
| POST   | /api/system/clear-cache       | Limpia caché RAM                   |
| POST   | /api/system/backup            | Genera backup de la DB             |

**Usuarios y autenticación**
| Método | Ruta              | Descripción                   |
|--------|-------------------|-------------------------------|
| GET    | /api/usuarios     | Lista usuarios activos        |
| POST   | /api/usuarios     | Crea usuario                  |
| PUT    | /api/usuarios/:id | Actualiza usuario             |
| DELETE | /api/usuarios/:id | Desactiva usuario (soft delete)|
| POST   | /api/login        | Login por PIN                 |

**Catálogo**
| Método | Ruta                       | Descripción                |
|--------|----------------------------|----------------------------|
| GET    | /api/categorias            | Lista categorías           |
| GET    | /api/productos             | Productos activos          |
| POST   | /api/productos             | Crea producto              |
| PUT    | /api/productos/:id         | Actualiza producto         |
| GET    | /api/productos/barcode/:code | Busca por código de barra|

**Clientes / Cuenta corriente**
| Método | Ruta                    | Descripción                      |
|--------|-------------------------|----------------------------------|
| GET    | /api/clientes           | Clientes activos con pagos       |
| POST   | /api/clientes           | Crea cliente                     |
| PUT    | /api/clientes/:id       | Actualiza cliente                |
| POST   | /api/clientes/:id/pago  | Registra pago y descuenta saldo  |

**Pedidos**
| Método | Ruta                       | Descripción                             |
|--------|----------------------------|-----------------------------------------|
| GET    | /api/pedidos               | Pedidos de hoy                          |
| GET    | /api/pedidos/all           | Últimos 200 pedidos                     |
| POST   | /api/pedidos               | Crea pedido, descuenta stock, emite WS  |
| PUT    | /api/pedidos/:id           | Actualiza pedido, emite WS              |
| POST   | /api/pedidos/:id/cobrar    | Marca cobrado, gestiona cuenta corriente|
| POST   | /api/pedidos/:id/cancelar  | Cancela y restaura stock, emite WS      |
| GET    | /api/pedidos/:id/ticket    | Genera texto de ticket para impresora   |

**Cierre de caja**
| Método | Ruta         | Descripción                    |
|--------|--------------|--------------------------------|
| POST   | /api/cierres | Registra cierre de caja        |
| GET    | /api/cierres | Últimos 30 cierres             |

**Autoservicio**
| Método | Ruta                          | Descripción                            |
|--------|-------------------------------|----------------------------------------|
| POST   | /api/autoservicio/pedido      | Envía pedido pendiente de aprobación   |
| GET    | /api/autoservicio/pendientes  | Lista pedidos pendientes               |
| DELETE | /api/autoservicio/:id         | Elimina pedido de la cola              |

> ⚠️ La cola de autoservicio es **en memoria** — se pierde si el backend se reinicia.

**Carrusel TV**
| Método | Ruta               | Descripción                                              |
|--------|--------------------|----------------------------------------------------------|
| GET    | /api/carousel      | Lista imágenes activas (usada por promo.html y el POS)   |
| POST   | /api/carousel      | Sube imagen (base64 JSON), guarda en `/images/` y en DB  |
| DELETE | /api/carousel/:id  | Elimina imagen del disco y de la DB                      |

### WebSocket (Socket.io)

Eventos emitidos por el servidor:
- `nuevo-pedido` — cuando se crea un pedido
- `pedido-actualizado` — cuando se modifica, cobra o cancela un pedido
- `notif-autoservicio` — cuando llega un pedido desde autoservicio

Eventos recibidos por el servidor:
- `pedido-autoservicio` — pedido desde tablet autoservicio
- `cambiar-estado` — cambio de estado desde cocina

---

## Base de datos (PostgreSQL)

Manejado con Prisma. Schema en `prisma/schema.prisma`.

```
Usuario         → login por PIN, roles (caja, cocina, admin)
Categoria       → agrupa productos, puede tener despacho_directo
Producto        → precio, stock, stock_min, código de barras opcional
Cliente         → nombre, apodo, división, saldo cuenta corriente
ClientePago     → historial de pagos de clientes
Pedido          → tipo (mesa/barra), estado, cobrado, método de pago
PedidoItem      → líneas del pedido con precio capturado al momento
CierreCaja      → resumen de cierre con efectivo/transferencia/fiado
CarouselImage   → imágenes para el carrusel de la pantalla de TV
```

**Estados de un pedido:** `pendiente` → `listo` → `entregado` / `cancelado`

**Métodos de pago:** `efectivo`, `transferencia`, `cuenta_corriente`

---

## Frontend

Cuatro vistas independientes en `client/dist/`:

| Archivo             | Uso                                                      |
|---------------------|----------------------------------------------------------|
| `index.html`        | POS principal: caja, cocina, admin, clientes, reportes   |
| `autoservicio.html` | Tablet de autoservicio para clientes                     |
| `cocina.html`       | Vista simplificada para la cocina                        |
| `promo.html`        | TV del salón — carrusel fullscreen de imágenes promo     |

### promo.html — TV Promociones

Página sin UI (fullscreen, sin cursor) diseñada para correr en el TV del salón:
- Consulta `GET /api/carousel` al cargar y cada 30 segundos
- Rota imágenes con crossfade (1.2s) cada 8 segundos
- Si la lista de imágenes cambia, reconstruye el carrusel automáticamente
- Las imágenes se gestionan desde la pestaña **Sistema** del POS (botón 📁 + importar)
- Los archivos se guardan en `/home/cantina/cantina-pos/images/`

El frontend usa React con Babel en el browser (sin build step en producción). Las dependencias (React, ReactDOM, Babel, fuentes) están en `/vendor/` y `/fonts/` — **sin dependencias de internet**.

---

## Nginx

Proxy inverso en puerto 80 → Node.js en 3001.
- WebSocket habilitado para Socket.io en `/socket.io/`
- Logs en `/var/log/nginx/cantina.access.log` y `cantina.error.log`
- Config en `/etc/nginx/sites-enabled/cantina`

---

## Scripts de mantenimiento

Todos en `scripts/`, ejecutar con `bash scripts/<nombre>.sh`:

```bash
bash scripts/healthcheck.sh       # Ver estado del sistema
bash scripts/backup.sh            # Hacer backup manual
bash scripts/restore.sh <archivo> # Restaurar backup
bash scripts/restart_backend.sh   # Reiniciar solo el backend
bash scripts/restart_all.sh       # Reiniciar todo en orden
```

---

## Notas técnicas

- `escpos` y `escpos-usb` están en dependencies pero la impresión se maneja por el endpoint `/api/pedidos/:id/ticket` que devuelve texto plano. La integración USB directa no está implementada aún.
- `dotenv` está en dependencies pero no se usa: las variables de entorno se inyectan via el systemd service file.
- `pg` está en dependencies pero el acceso a DB se hace exclusivamente via Prisma.
