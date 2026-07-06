# Cantina POS

Sistema POS touchscreen para cantina corporativa argentina. Corre 100% en LAN, sin dependencia de internet en runtime. Un servidor Ubuntu sirve la API y el frontend estático; las tablets acceden por IP local vía Chromium.

**Server:** `192.168.100.54` — `ssh cantina@192.168.100.54`

**GitHub:** `https://github.com/juanpablocap/cantina.git` — el hook post-commit hace push automático tras cada commit.

## Stack

- **Backend:** Node.js 20 + Express 5 + Prisma 5 + PostgreSQL 18 + Socket.io 4
- **Frontend:** 4 HTMLs independientes, React 18 + Babel in-browser (sin build step en producción)
- **Proxy:** Nginx :80 → :3001 (WebSocket habilitado, `/monitor/` → Netdata :19999)
- **Offline:** React, ReactDOM, Babel, Chart.js 4.4, fuentes en `/vendor/` y `/fonts/` — sin CDN

## Archivos principales

| Archivo | Descripción |
|---|---|
| `server.js` | Backend completo (~660 líneas) — Express + Socket.io + Prisma. Un solo archivo. |
| `client/dist/index.html` | POS principal (~3600 líneas) — caja, pedidos, mesas, admin, clientes, sistema |
| `client/dist/cocina.html` | Display para la cocina — estados de pedidos en tiempo real |
| `client/dist/autoservicio.html` | Kiosko self-service para clientes |
| `client/dist/promo.html` | TV del salón — carrusel fullscreen, polling 30s, crossfade 1.2s |
| `client/dist/vendor/` | React, ReactDOM, Babel, Chart.js 4.4 (servidos offline) |
| `prisma/schema.prisma` | Esquema DB — 9 modelos |
| `scripts/` | healthcheck, backup, restore, restart_all, dashboard TUI, setup_netdata |
| `images/` | Imágenes del carrusel TV (servidas en `/images/`) |

## UI — antes de tocar cualquier cosa visual

**Leé los estilos existentes en `client/dist/index.html` antes de hacer cambios de UI.**

El POS tiene dos temas switchables sin recargar, persistidos en `localStorage` (clave `posTheme`):
- `modern` (default): accent indigo `#6366F1`, bg `#070A12`
- `classic`: accent terracota `#E07A5F`, bg `#0A0D14`

Cada tema define tokens de color en un objeto `S.*` usado en todo el JSX. No hardcodear colores — usar los tokens del tema activo.

La navegación es bottom bar fija (Modern POS v2): Venta / Pedidos / Mesas / Caja / ⋯Más + drawer secundario.

## Documentación — leer antes de cambios grandes

| Doc | Cuándo leerlo |
|---|---|
| `MASTER_CONTEXT.md` | Estado general, URLs, filosofía del proyecto |
| `ARCHITECTURE.md` | Rutas API completas, estructura de archivos, servicios systemd, DB |
| `PROJECT_TODO.md` | Qué está hecho y qué falta |
| `OPERACION.md` | Flujos de uso desde el punto de vista del operador |
| `RECOVERY.md` | Troubleshooting, cómo restaurar desde cero |

## Riesgos críticos vigentes

1. **Cola autoservicio en memoria** — `pendingAutoservicio` en server.js se pierde al reiniciar el backend. No persiste en DB.
2. **Sin autenticación en la API** — cualquier dispositivo en la LAN puede leer y modificar datos. Aceptable para LAN cerrada, pero no agregar endpoints sensibles sin considerar esto.
3. **Kiosk Chromium no configurado** — las tablets requieren configuración física (fullscreen, autorestart, reconexión).
4. **Impresora térmica no integrada** — `escpos`/`escpos-usb` están en dependencies pero sin implementar. El ticket se genera como texto plano en `GET /api/pedidos/:id/ticket`.
5. **`client/src/App.jsx` es el template Vite por defecto** — `npm run build` en `client/` sobreescribiría `client/dist/` con el template. Los 4 HTMLs reales son handcrafted, no se buildean.

## Filosofía

Priorizar: estabilidad · simplicidad · recovery rápido · offline/LAN · mantenibilidad.

Evitar: complejidad innecesaria · dependencias cloud · reescrituras · features no pedidas.

Analizar antes de cambiar. Preservar el funcionamiento existente.
