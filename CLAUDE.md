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
| `server.js` | Backend completo (~900 líneas) — Express + Socket.io + Prisma. Un solo archivo. |
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

## Riesgos vigentes

1. **Cola autoservicio en memoria** — `pendingAutoservicio` en server.js se pierde al reiniciar el backend. No persiste en DB. IDs basados en `Date.now()`, no únicos bajo carga extrema. Aceptable para el volumen esperado (cajero aprueba manualmente antes de procesar).
2. **Sin autenticación en la API** — cualquier dispositivo en la LAN puede leer y modificar datos. Aceptable para LAN cerrada, pero no agregar endpoints sensibles sin considerar esto.
3. **Kiosk Chromium no configurado** — las tablets requieren configuración física (fullscreen, autorestart, reconexión).
4. **Sin tests automatizados** — no hay cobertura de tests. Flujos críticos validados manualmente. Stack sugerido: Vitest + Supertest.
5. **`client/src/App.jsx` es el template Vite por defecto** — `npm run build` en `client/` sobreescribiría `client/dist/` con el template. Los 4 HTMLs reales son handcrafted, no se buildean.

## Bugs críticos corregidos (auditoría julio 2026)

No tocar estas áreas sin leer el contexto completo — bugs sutiles que costó encontrar:

- **`POST /api/system/restart`**: responde `{ ok:true, restarting:true }` ANTES de ejecutar el reinicio. El proceso muere y no puede responder después. Cualquier cambio debe preservar este orden.
- **`POST /api/pedidos/:id/cobrar`**: usa `UPDATE WHERE cobrado=false` (guard atómico). No reemplazar por `findUnique` + check manual — hay una race condition documentada con cuenta corriente.
- **`midnightAR()`**: helper en server.js para calcular medianoche en Argentina. Todos los cálculos de "hoy" deben usar esto, no `new Date(); setHours(0,0,0,0)` que usa UTC del servidor.
- **`PUT /api/pedidos/:id`**: no acepta `estado='cancelado'` — debe ir por `/cancelar` que restaura stock. No revertir esta restricción.
- **`enrichPedido()` en server.js**: helper que agrega `solo_despacho` y `despacho_directo` por ítem a cada pedido antes de enviarlo al cliente. `solo_despacho=true` cuando todos los ítems son de una categoría `despacho_directo` y el producto tiene `cocina=false`. Estos campos NO están en la DB (Pedido/PedidoItem no los tienen); se computan en runtime desde `Categoria`. `GET /api/pedidos` y el emit de `POST /api/pedidos` deben pasar por `enrichPedido`. Si se agregan nuevos endpoints que devuelvan pedidos y los consuma cocina.html, deben usar el mismo helper.
- **`cocina.html` filtra `!p.solo_despacho`**: los pedidos de barra con todos ítems de despacho directo no deben aparecer en cocina. Este filtro depende del campo computado por `enrichPedido`. No usar `solo_despacho` para filtrar cobros — los pedidos de despacho directo también deben cobrarse.

## Bugs corregidos (auditoría agosto 2026)

- **`cobrarPedido()` en index.html — `totalCobrado` para pedidos de barra**: usaba `pedOriginal.total` (pre-descuento) en vez del total real devuelto por el servidor. Corregido a `result.total ?? pedOriginal.total`. Afectaba: `cajaMovimientos` (totales de caja incorrectos), saldo de cuenta corriente en estado de la UI. El servidor siempre devuelve el total correcto — el frontend debe usarlo.
- **`CobrarModal` — aviso cuenta corriente con descuento**: mostraba `pedido.total` (pre-descuento) en el mensaje "Se carga $X a la cuenta". Corregido a `totalFinal`. El operador veía el monto incorrecto antes de confirmar el cobro.
- **`GET /api/pedidos/por-fecha` — timezone**: usaba `setHours(0,0,0,0)` en UTC del servidor para el rango de fechas. Corregido a `new Date(fecha + 'T00:00:00-03:00')`. Afectaba la reconstrucción de cierres históricos (rango corrido 3 horas).

## Filosofía

Priorizar: estabilidad · simplicidad · recovery rápido · offline/LAN · mantenibilidad.

Evitar: complejidad innecesaria · dependencias cloud · reescrituras · features no pedidas.

Analizar antes de cambiar. Preservar el funcionamiento existente.
