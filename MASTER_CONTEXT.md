# Cantina POS — Master Context

## Objetivo

Sistema POS touchscreen para cantina, funcionando 100% en red local (LAN), sin dependencia de internet.
Incluye: impresora térmica para tickets, TV en el salón que muestra imágenes de promociones/ofertas en carrusel, tablets touchscreen para autoservicio de clientes.

---

## Estado actual del sistema (mayo 2026)

El sistema está **en producción y funcionando**. Todos los servicios levantan solos tras un reboot. No hay reescrituras pendientes — se trabaja en mejoras incrementales.

### Lo que ya está hecho

- Backend Express + Socket.io + Prisma estable, con transacciones en operaciones críticas
- Frontend React (Babel in-browser, sin build step) con tema visual moderno (Modern POS v2)
- Sistema de doble tema: `modern` (default) y `classic`, switchable, persistido en localStorage
- Autorestart de todos los servicios: postgresql → cantina-api → nginx (orden correcto)
- Manejo de errores en todas las rutas; indicador visual SIN CONEXIÓN
- Backups automáticos con script; retención de 30 días
- Scripts de mantenimiento: `dashboard.sh`, `healthcheck.sh`, `backup.sh`, `restart_all.sh`
- Documentación completa: ARCHITECTURE, DEPLOYMENT, RECOVERY, OPERACION, SERVER_INFO
- TV promo carousel: página fullscreen `promo.html` + API de gestión de imágenes
- Gestión de imágenes desde pendrive: upload base64 → disco + DB, eliminación desde el POS

---

## Stack técnico (estado real)

| Componente | Tecnología |
|---|---|
| OS | Ubuntu 26.04 LTS |
| Backend | Node.js 20 + Express 5 + Socket.io 4 |
| ORM | Prisma 5 sobre PostgreSQL 18 |
| Frontend | React 18 con Babel in-browser (sin bundler en producción) |
| Servidor web | Nginx — reverse proxy :80 → :3001, WebSocket habilitado |
| Gestión procesos | systemd (cantina-api, nginx, postgresql@18-main) |
| Administración | SSH + scripts bash |

**Sin dependencias de internet en runtime:** React, ReactDOM, Babel, fuentes y librerías están en `/vendor/` y `/fonts/`.

---

## Servidores y URLs

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
| `server.js` | Backend completo (~640 líneas, un solo archivo) |
| `client/dist/index.html` | POS principal (~3600 líneas, React inline) |
| `client/dist/cocina.html` | Vista cocina |
| `client/dist/autoservicio.html` | Tablet autoservicio |
| `client/dist/promo.html` | TV carrusel de promociones |
| `prisma/schema.prisma` | Esquema DB (9 modelos) |
| `scripts/` | Mantenimiento: healthcheck, backup, restart, dashboard |
| `images/` | Imágenes del carrusel TV (servidas en `/images/`) |

---

## Modelos de base de datos

```
Usuario        → login por PIN, roles (caja, cocina, admin)
Categoria      → agrupa productos, flag despacho_directo
Producto       → precio, stock, stock_min, código de barras
Cliente        → cuenta corriente (fiado)
ClientePago    → historial de pagos
Pedido         → tipo mesa/barra, estado, cobrado, método de pago
PedidoItem     → líneas del pedido con precio capturado
CierreCaja     → resumen de cierre diario
CarouselImage  → imágenes para el TV del salón (filename, orden, activo)
```

**Estados de pedido:** `pendiente` → `en_preparacion` → `listo` → `entregado` / `cancelado`

---

## Monitoreo — Netdata + sparklines inline

**Netdata** es el dashboard profesional de métricas del servidor.
- URL: `http://192.168.100.54/monitor/` (proxy nginx → localhost:19999)
- Se instala con: `sudo bash scripts/setup_netdata.sh`
- Métricas en tiempo real: CPU, RAM, disco, red, temperatura, procesos, etc.
- Resolución de 1 segundo, historial de horas/días incluido
- Sin configuración adicional — auto-descubrimiento completo

**Sparklines inline en el POS** (pestaña Sistema):
- Gráficos Chart.js en tiempo real: CPU%, RAM%, Disco%, Red RX, Red TX
- Datos vienen de `GET /api/system` cada 5s + historial desde `GET /api/system/history`
- Historial en memoria: últimos 120 registros (~10 min a 5s de intervalo)
- Botón "📊 Monitor" abre Netdata completo en nueva pestaña

## TV Promo Carousel

- **Página:** `promo.html` — fullscreen, sin cursor, sin UI, diseñada para correr permanente en un TV
- **Rotación:** cada 8 segundos con crossfade de 1.2s
- **Polling:** consulta `/api/carousel` cada 30 segundos; si cambian las imágenes reconstruye el carrusel automáticamente
- **API:** `POST /api/carousel` (sube imagen en base64, guarda en `/images/` + DB) · `DELETE /api/carousel/:id`
- **Gestión:** desde la pestaña **Sistema** del POS → botón **📺 VER TV** para previsualizar · **📁 Abrir archivos** para seleccionar del pendrive · **📥 Importar todas**
- **Almacenamiento:** `/home/cantina/cantina-pos/images/` (servido en `/images/` por Express)

---

## Diseño UI (Modern POS v2)

El frontend fue rediseñado estructuralmente (no solo colores):

- **Navegación:** bottom bar fija con 5 ítems (Venta / Pedidos / Mesas / Caja / ⋯Más) + drawer para pestañas secundarias
- **Header:** 52px con logo, reloj, estado DB, badge de usuario, toggle de tema
- **Venta:** tarjetas de producto con banda de color de categoría, grid de mesas 8 columnas, panel carrito 38%
- **Pedidos:** agrupados por urgencia (LISTOS → EN COCINA → ENTREGADOS → COBRADOS → CANCELADOS)
- **Numpad:** bottom sheet con botones de 68px
- **Tema classic:** preservado intacto, seleccionable desde el toggle 🌙 — útil para debug o preferencia del operador
- **Colores modern:** accent `#6366F1` (indigo), bg `#070A12`, surface `#0D1120`

---

## Filosofía del proyecto

**Priorizar:** estabilidad · simplicidad · recovery rápido · funcionamiento offline/LAN · mantenibilidad

**Evitar:** complejidad innecesaria · microservicios · dependencias cloud · reescrituras · arquitectura enterprise

**Reglas:** analizar antes de cambiar · preservar funcionamiento existente · documentar todo · no agregar features no pedidas

---

## UX Goals

Usado por operadores no técnicos, en ambientes rápidos, con tablets touchscreen y posiblemente mala iluminación. La interfaz prioriza: botones grandes · pocos clicks · feedback visual inmediato · velocidad · simplicidad extrema.
