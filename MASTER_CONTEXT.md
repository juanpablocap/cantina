# Cantina POS — Master Context

## Objetivo

Sistema POS touchscreen para cantina, funcionando 100% en red local (LAN), sin dependencia de internet.
Incluye: impresora térmica para tickets, TV en el salón con carrusel de imágenes promocionales, tablets touchscreen para autoservicio de clientes, monitoreo profesional del servidor.

---

## Estado actual del sistema (junio 2026)

El sistema está **en producción, estable y documentado**. Todos los servicios levantan solos tras un reboot. No hay reescrituras pendientes — se trabaja en mejoras incrementales.

### Completado

- Backend Express + Socket.io + Prisma estable, transacciones en operaciones críticas
- Frontend React (Babel in-browser) con Modern POS v2 — bottom navigation, rediseño estructural completo
- Sistema de doble tema: `modern` (default, indigo) y `classic` (terracota), switchable via toggle 🌙, persistido en localStorage
- Autorestart de todos los servicios: postgresql → cantina-api → nginx → netdata
- Monitoreo profesional: **Netdata v2.10.3** en `http://192.168.100.54/monitor/`
- Sparklines Chart.js en la pestaña Sistema (CPU, RAM, disco, red RX/TX, últimos 10 min)
- TV promo carousel: `promo.html` fullscreen + API completa (upload/delete imágenes)
- Backups con retención de 30 días; scripts de mantenimiento completos
- Documentación completa: ARCHITECTURE, DEPLOYMENT, RECOVERY, OPERACION, SERVER_INFO, MASTER_CONTEXT
- Código demo eliminado (botón "Simular pedido autoservicio" removido)
- **Pantalla Caja con 3 solapas:** Hoy (cierre normal) · Historial (últimos 30 cierres con Ver/Descargar) · Estadísticas (gráfico torta, rankings, métricas, selector de rango)
- **Productos sin stock:** permanecen activos y clickeables; stock puede ser negativo; badge "SIN STOCK" en la card
- **Validación cantidad:** `POST /api/pedidos` rechaza `cantidad ≤ 0` o no entero — evita pedidos inválidos
- **Descuento real en cobro:** `POST /api/pedidos/:id/cobrar` calcula y persiste el `total` post-descuento; la cuenta corriente incrementa el monto real cobrado (no el bruto)
- **Cierre de caja persistente:** `CierreCaja.details` (JSON) guarda los productos vendidos para consulta futura desde Historial
- **Nuevas rutas:** `GET /api/cierres/:id`, `GET /api/estadisticas?range=...`, `GET /api/pedidos/por-fecha?fecha=...`

### Pendiente (requiere acceso físico)

- Kiosk Chromium en tablets: fullscreen, reconexión, autorestart
- Guía visual con capturas de pantalla
- Restore completo desde cero (probar)
- Revisión usuarios y permisos PostgreSQL

---

## Stack técnico

| Componente | Tecnología |
|---|---|
| OS | Ubuntu 26.04 LTS |
| Backend | Node.js 20 + Express 5 + Socket.io 4 |
| ORM | Prisma 5 sobre PostgreSQL 18 |
| Frontend | React 18 + Babel in-browser + Chart.js 4.4 |
| Servidor web | Nginx — :80 → :3001 + /monitor/ → :19999 |
| Monitoreo | Netdata v2.10.3 (bind localhost:19999) |
| Gestión procesos | systemd: cantina-api, nginx, postgresql@18-main, netdata |
| Administración | SSH + scripts bash |

**100% offline en runtime:** React, ReactDOM, Babel, Chart.js, fuentes en `/vendor/` y `/fonts/`.

---

## URLs del sistema

| Pantalla | URL | Dispositivo |
|---|---|---|
| POS principal | `http://192.168.100.54/` | PC caja / tablet admin |
| Cocina | `http://192.168.100.54/cocina.html` | Pantalla cocina |
| Autoservicio | `http://192.168.100.54/autoservicio.html` | Tablet clientes |
| TV Promociones | `http://192.168.100.54/promo.html` | TV del salón |
| Monitor Netdata | `http://192.168.100.54/monitor/` | Técnico / admin |

**Servidor:** `ssh cantina@192.168.100.54` — IP fija en la LAN.

---

## Archivos clave

| Archivo | Descripción |
|---|---|
| `server.js` | Backend completo (~780 líneas, un solo archivo) |
| `client/dist/index.html` | POS principal (~4500 líneas, React inline) |
| `client/dist/cocina.html` | Vista cocina |
| `client/dist/autoservicio.html` | Tablet autoservicio |
| `client/dist/promo.html` | TV carrusel de promociones (fullscreen, polling 30s) |
| `client/dist/vendor/chart.umd.min.js` | Chart.js 4.4 — servido offline |
| `prisma/schema.prisma` | Esquema DB (9 modelos) |
| `images/` | Imágenes del carrusel TV (servidas en `/images/`) |
| `scripts/healthcheck.sh` | Estado completo del sistema |
| `scripts/dashboard.sh` | TUI interactivo SSH con acciones rápidas |
| `scripts/backup.sh` | Backup DB (retiene últimos 30) |
| `scripts/restart_all.sh` | Reinicia todos los servicios en orden correcto |
| `scripts/setup_netdata.sh` | Instala Netdata + configura nginx /monitor/ |
| `scripts/nginx-cantina.conf` | Config nginx fuente (incluye /monitor/) |

---

## API — rutas principales

**Sistema**
- `GET /api/system` — CPU, RAM, disco, red RX/TX KB/s, temperatura, servicios, último backup
- `GET /api/system/history` — historial de métricas (buffer circular 120 registros, ~10 min)
- `POST /api/system/backup` — genera backup de la DB
- `POST /api/system/clear-cache` — libera caché RAM

**Pedidos**
- `GET /api/pedidos` — pedidos de hoy
- `GET /api/pedidos/por-fecha?fecha=YYYY-MM-DD` — pedidos cobrados de una fecha específica
- `POST /api/pedidos` — crea pedido (valida `cantidad > 0` entero)
- `POST /api/pedidos/:id/cobrar` — cobra pedido; aplica `descuento_pct` al total y lo persiste; `cuenta_corriente` usa el monto real

**Cierre de caja y estadísticas**
- `POST /api/cierres` — registra cierre; acepta `details` JSON con productos vendidos
- `GET /api/cierres` — últimos 30 cierres
- `GET /api/cierres/:id` — cierre individual
- `GET /api/estadisticas?range=today|week|month|lastmonth|all` — ventas por producto, ticket promedio, hora pico

**Carrusel TV**
- `GET /api/carousel` — lista imágenes activas (usada por promo.html y el POS)
- `POST /api/carousel` — sube imagen (base64 JSON), guarda en `/images/` y en DB
- `DELETE /api/carousel/:id` — elimina imagen del disco y de la DB

**WebSocket (Socket.io)**
- Emite: `nuevo-pedido`, `pedido-actualizado`, `notif-autoservicio`
- Recibe: `pedido-autoservicio`, `cambiar-estado`

---

## Modelos de base de datos

```
Usuario        → login por PIN, roles (caja, cocina, admin)
Categoria      → agrupa productos, flag despacho_directo
Producto       → precio, stock (puede ser negativo), stock_min, código de barras
Cliente        → cuenta corriente (fiado)
ClientePago    → historial de pagos
Pedido         → tipo mesa/barra, estado, cobrado, método de pago, descuento_pct, total (post-descuento)
PedidoItem     → líneas del pedido con precio capturado
CierreCaja     → resumen de cierre diario + details JSON (desglose de productos vendidos)
CarouselImage  → imágenes para el TV (filename, orden, activo)
```

**Estados de pedido:** `pendiente` → `en_preparacion` → `listo` → `entregado` / `cancelado`

**Métodos de pago:** `efectivo`, `transferencia`, `cuenta_corriente`

---

## Monitoreo

**Netdata v2.10.3** — dashboard profesional instalado y corriendo.
- URL: `http://192.168.100.54/monitor/` (proxy nginx → `localhost:19999`)
- Bind: solo a loopback, acceso únicamente vía nginx
- 200+ métricas auto-descubiertas, resolución 1s, historial de horas/días
- Reinstalación: `sudo bash scripts/setup_netdata.sh`

**Sparklines inline en el POS** (pestaña Sistema → 6 chart-cards):
- CPU%, RAM%, Disco%, Temperatura, Red RX, Red TX
- Chart.js 4.4 servido offline desde `/vendor/`
- Datos: `GET /api/system` cada 5s + `GET /api/system/history` al iniciar
- Botón **📊 Monitor** abre Netdata en nueva pestaña

---

## TV Promo Carousel

- `promo.html` — fullscreen, sin cursor, sin UI, para correr permanente en TV
- Rota imágenes cada 8s con crossfade 1.2s
- Polling cada 30s — se actualiza solo si cambian las imágenes
- Gestión desde pestaña **Sistema** del POS: **📁 Abrir archivos** → seleccionar del pendrive → **📥 Importar todas**
- Botón **📺 VER TV** abre promo.html en nueva pestaña
- Archivos en `/home/cantina/cantina-pos/images/`, servidos en `/images/`

---

## Diseño UI (Modern POS v2)

Rediseño estructural completo (no solo colores):

- **Navegación:** bottom bar fija (Venta / Pedidos / Mesas / Caja / ⋯Más) + drawer secundario
- **Header:** 52px con logo, reloj, estado DB, badge de usuario, toggle de tema
- **Venta:** tarjetas de producto con banda de color por categoría, grid mesas 8 col, carrito 38%
- **Pedidos:** agrupados por urgencia (LISTOS → EN COCINA → ENTREGADOS → COBRADOS → CANCELADOS)
- **Numpad:** bottom sheet, botones 68px, backdrop blur
- **Tema classic:** preservado intacto — útil para debug o preferencia personal
- Tokens modern: accent `#6366F1`, bg `#070A12`, surface `#0D1120`
- Tokens classic: accent `#E07A5F`, bg `#0A0D14`, surface `#12151C`

---

## Filosofía del proyecto

**Priorizar:** estabilidad · simplicidad · recovery rápido · offline/LAN · mantenibilidad a largo plazo

**Evitar:** complejidad innecesaria · microservicios · dependencias cloud · reescrituras · arquitectura enterprise

**Reglas de trabajo:** analizar antes de cambiar · preservar funcionamiento existente · documentar todo · no agregar features no pedidas · no hay código demo en producción
