# TODO Proyecto Cantina POS

## UX / Features recientes (julio 2026)

* [x] Cierre de caja bloqueado si hay pedidos sin cobrar: muestra modal de advertencia con lista de pedidos pendientes (número, destino, estado, total) — el cierre solo procede cuando todos están cobrados o cancelados

## UX / Features recientes (junio 2026)

* [x] Pantalla Caja: 3 solapas — Hoy / Historial / Estadísticas
* [x] Historial cierres: Ver muestra productos vendidos (usa details JSON o fallback por fecha)
* [x] Historial cierres: Descargar genera .txt con resumen completo
* [x] Estadísticas: gráfico torta + rankings por cantidad/monto + métricas resumen + selector de rango
* [x] Actualización instantánea de Historial y Estadísticas al hacer cierre
* [x] CierreCaja.details: persiste desglose completo de productos en el cierre
* [x] Nuevas rutas: GET /api/cierres/:id, GET /api/estadisticas, GET /api/pedidos/por-fecha
* [x] Sin stock: productos permanecen activos, stock negativo permitido, badge "SIN STOCK" en card
* [x] Validación crítica: POST /api/pedidos rechaza cantidad ≤ 0 o no entero — evita stock corrupto
* [x] Descuento real: POST /api/pedidos/:id/cobrar aplica descuento_pct al total y lo persiste en DB; cuenta corriente usa monto post-descuento
* [x] Botón ticket renombrado a "🧾 Ver ticket" en lista de pedidos

## UX / Features recientes (mayo 2026)

* [x] Modal cobrar: compactar padding/spacing para que entre sin scroll en pantallas tablet
* [x] Modal cobrar: mostrar destino en el header junto al número (#001 · Mesa 4, Barra, etc.)
* [x] Modal cobrar: botones de descuento más chicos (padding y font-size −25%)
* [x] Ticket post-cobro: cierre automático en 1 segundo (antes 3s)
* [x] Botón pantalla completa: reducido a 2/3 del tamaño original
* [x] Prefix de mozo en número de pedido: A001 / B001 en vez de #001 cuando la mesa tiene mozo asignado
* [x] Panel de detalle de mesa: selector de mozo por iniciales (persistido en servidor, sincroniza cocina)
* [x] cocina.html: muestra initial del mozo en el número grande de cada tarjeta, sincroniza cada 30s

## PRIORIDAD ALTA — Estabilidad y Recovery

* [x] Auditar estructura completa del proyecto
* [x] Documentar arquitectura actual — ver ARCHITECTURE.md
* [x] Verificar flujo completo de inicio del sistema — orden correcto verificado
* [x] Verificar servicios systemd existentes — cantina-api, nginx, postgresql enabled
* [x] Confirmar autorestart de backend — Restart=always
* [x] Confirmar autorestart de nginx — Restart=always (override en /etc/systemd/system/nginx.service.d/)
* [x] Confirmar autorestart postgresql — Restart=on-failure (override en /etc/systemd/system/postgresql@18-main.service.d/)
* [x] Confirmar autorestart netdata — habilitado vía systemctl enable
* [ ] Confirmar autorestart kiosk/chromium — requiere tablets físicas
* [x] Revisar manejo de errores críticos — fix sudo -n en restart y clear-cache
* [x] Revisar logs del sistema — sin errores críticos
* [x] Revisar logs backend — fix sudo sin flag -n causaba auth failures silenciosos
* [x] Revisar logs nginx — limpio
* [x] Revisar manejo de errores PostgreSQL — logs limpios, índices FK agregados, startup order correcto
* [x] Crear script restart_backend.sh
* [x] Crear script restart_all.sh
* [x] Crear script backup.sh
* [x] Crear script backup_sistema.sh — backup completo con DB + proyecto + config nginx/systemd + RESTORE.md
* [x] Crear script restore.sh
* [x] Crear script healthcheck.sh
* [x] Crear script setup_netdata.sh — instala Netdata + configura nginx /monitor/
* [x] Verificar recuperación tras reinicio del servidor — todos los servicios levantan solos
* [x] Verificar funcionamiento offline/LAN — CDN y fuentes movidos a local
* [x] Revisar manejo de pérdida de red local — fix marcarEntregado/marcarListo + indicador SIN CONEXIÓN
* [x] Verificar arranque automático completo tras reboot — orden correcto: postgresql → cantina-api → nginx (fix 502 aplicado)

## Backend

* [x] Revisar estructura del backend — un solo archivo limpio, sin duplicados
* [x] Detectar código duplicado — ninguno
* [x] Detectar rutas innecesarias — ninguna
* [x] Revisar middlewares — cors, json (15mb limit), static OK
* [x] Revisar validaciones — agregadas en rutas críticas (pedidos, cobrar, pago)
* [x] Revisar manejo de errores — try/catch en todas las rutas
* [x] Revisar seguridad básica — PUT /pedidos/:id restringido a solo estado
* [x] Revisar queries PostgreSQL — transacciones en pedidos, cobrar, cancelar, pagos
* [x] Revisar performance general — índices FK agregados, queries OK para escala actual
* [x] Revisar variables de entorno — en .env y systemd service, OK
* [x] Limpiar código no utilizado — dependencias no usadas eliminadas; botón demo autoservicio eliminado
* [x] Revisar manejo de sesiones — PIN login, aceptable para LAN cerrada
* [x] Revisar flujo de pedidos — transacción atómica pedido+stock, guard doble cancelación
* [x] Revisar lógica de caja — cierre de caja OK
* [x] Revisar lógica de cocina — cambiar-estado via WebSocket OK
* [x] Revisar manejo de estado tiempo real — socket.io emite en todas las mutaciones
* [x] Revisar estabilidad websocket/socket.io — configuración OK
* [x] API carrusel TV — POST/DELETE /api/carousel, imágenes en /images/, base64 upload
* [x] API métricas historial — GET /api/system/history, buffer circular 120 registros
* [x] Métricas de red — RX/TX KB/s desde /proc/net/dev en /api/system
* [x] Crear documentación técnica backend — ver ARCHITECTURE.md

## Frontend / UX

* [x] Auditar experiencia touchscreen — botones grandes, tap targets OK en los 3 archivos
* [x] Detectar puntos de fricción — corregidos bugs críticos
* [x] Reducir cantidad de clicks necesarios — flujos existentes son directos
* [x] Aumentar tamaño de botones táctiles — ya tienen padding generoso
* [x] Mejorar feedback visual — indicador SIN CONEXIÓN en index y cocina
* [x] Mejorar estados seleccionados — OK
* [x] Revisar navegación completa — OK en los 3 archivos
* [x] Revisar legibilidad general — fuentes grandes, contraste OK
* [x] Rediseño estructural Modern POS v2 — bottom nav, cards de producto, pedidos agrupados por urgencia
* [x] Sistema dual de temas — modern (default, indigo) / classic (terracota), persistido en localStorage
* [x] TouchNumpad como bottom sheet — botones 68px, blur backdrop
* [x] Chart.js sparklines en Sistema — CPU, RAM, disco, red RX/TX (offline, /vendor/)
* [x] TV carrusel promo — promo.html fullscreen, polling 30s, crossfade 1.2s
* [x] Gestión imágenes carrusel — file picker real, upload base64, delete con API
* [x] Botón 📺 VER TV y 📊 Monitor en pestaña Sistema
* [x] Eliminar botón "Simular pedido autoservicio" (era demo)
* [ ] Revisar modo kiosk — requiere tablets físicas
* [ ] Revisar responsive tablets — requiere tablets físicas
* [x] Revisar velocidad de uso real — tests de sistema completos, performance excelente (30-35ms avg)
* [x] Revisar errores visuales — fix pantalla en blanco en autoservicio
* [x] Revisar carga inicial — autoservicio muestra error si falla la carga, con reintento
* [x] Revisar manejo de errores frontend — fix autoservicio mostraba éxito aunque falle el envío
* [x] Revisar consistencia visual — OK
* [x] Revisar accesibilidad básica — OK para entorno cantina
* [x] Revisar flujo de cobro — OK
* [x] Revisar flujo de cancelación — OK (fix doble cancelación en backend)
* [x] Revisar flujo de cocina — fix cambiarEstado sin null check
* [x] Revisar flujo de administración — OK
* [x] Crear documentación frontend — OPERACION.md, ARCHITECTURE.md, MASTER_CONTEXT.md

## PostgreSQL

* [x] Revisar estructura de base de datos — 9 modelos (incluye CarouselImage)
* [x] Revisar índices — 6 índices FK agregados via migración Prisma
* [x] Revisar relaciones — OK, todas con FK correctas
* [x] Revisar integridad de datos — transacciones en backend para operaciones críticas
* [x] Revisar backups — script backup.sh, retiene últimos 30, backup antes de restore
* [x] Probar restore completo desde cero
* [x] Revisar usuarios y permisos de PostgreSQL
* [x] Revisar tamaño y crecimiento DB — DB pequeña (<50KB tablas), crecimiento lineal
* [x] Crear documentación DB — schema documentado en ARCHITECTURE.md

## Nginx / Infraestructura

* [x] Revisar configuración nginx — reverse proxy :80 → :3001 con WebSocket
* [x] Revisar reverse proxy — funcionando con soporte WebSocket
* [x] Agregar proxy /monitor/ → Netdata :19999
* [x] Revisar puertos abiertos
* [x] Revisar seguridad básica LAN
* [x] Revisar manejo de errores nginx — custom error pages 502/500/503 en español, 404 disponible (SPA usa catch-all)
* [x] Revisar headers — X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy, Permissions-Policy
* [x] Revisar cache — no-store en API, no-cache en HTML, max-age=86400+immutable en vendor/fonts/images
* [x] Revisar logs nginx — limpios, logueando en cantina.access.log / cantina.error.log
* [x] Revisar startup order — After=cantina-api + wait_for_backend.sh (fix 502)
* [x] Documentar infraestructura — en ARCHITECTURE.md

## Monitoreo

* [x] Mostrar estado servicios — healthcheck.sh
* [x] Mostrar estado PostgreSQL — healthcheck.sh
* [x] Mostrar estado nginx — healthcheck.sh
* [x] Mostrar estado backend — healthcheck.sh
* [x] Mostrar uso CPU/RAM/disco — healthcheck.sh
* [x] Mostrar IP local — healthcheck.sh
* [x] Mostrar uptime — healthcheck.sh
* [x] Mostrar último backup — healthcheck.sh
* [x] Crear dashboard SSH/TUI interactivo con acciones rápidas — scripts/dashboard.sh
* [x] Agregar acciones restart rápidas desde dashboard
* [x] Agregar visualización rápida logs desde dashboard
* [x] Instalar Netdata v2.10.3 — dashboard profesional en http://192.168.100.54/monitor/
* [x] Sparklines Chart.js en POS — CPU%, RAM%, disco%, red RX/TX con historial 10 min
* [x] API historial métricas — GET /api/system/history (buffer circular 120 registros)
* [x] Métricas de red en tiempo real — RX/TX KB/s vía /proc/net/dev

## Kiosk / Tablets

* [ ] Revisar Chromium kiosk — requiere acceso físico
* [ ] Revisar fullscreen real — requiere acceso físico
* [ ] Revisar reconexión automática — requiere acceso físico
* [ ] Revisar comportamiento touchscreen — requiere acceso físico
* [ ] Revisar manejo de errores visuales — requiere acceso físico
* [ ] Revisar comportamiento tras reboot — requiere acceso físico
* [ ] Revisar estabilidad XRDP — requiere acceso físico
* [ ] Revisar audio/notificaciones — requiere acceso físico
* [ ] Revisar consumo de recursos — requiere acceso físico
* [ ] Crear guía de tablets/kiosk

## Documentación Técnica

* [x] Crear ARCHITECTURE.md — completo
* [x] Crear README principal
* [x] Crear RECOVERY.md
* [x] Crear BACKUP_GUIDE.md
* [x] Crear DEPLOYMENT.md
* [x] Crear SERVER_INFO.md
* [x] Crear MASTER_CONTEXT.md — contexto técnico completo y actualizado
* [x] Crear CLAUDE.md — contexto para Claude Code: stack, archivos, UI, riesgos vigentes
* [x] Documentar troubleshooting — incluido en RECOVERY.md

## Manual Cliente / Operación

* [x] Manual básico de uso — OPERACION.md
* [x] Cómo iniciar sistema — OPERACION.md + RECOVERY.md
* [x] Cómo reiniciar sistema — RECOVERY.md
* [x] Qué hacer si falla — RECOVERY.md
* [x] Cómo usar pedidos — OPERACION.md
* [x] Cómo cobrar — OPERACION.md
* [x] Cómo cancelar pedidos — OPERACION.md
* [x] Cómo administrar productos — OPERACION.md
* [x] Cómo revisar cocina — OPERACION.md
* [x] Cómo gestionar carrusel TV — OPERACION.md
* [ ] Guía visual simple — requiere capturas de pantalla
* [x] Errores comunes y solución — RECOVERY.md + OPERACION.md

## Calidad General

* [x] Detectar deuda técnica — identificada y corregida
* [x] Revisar archivos innecesarios — ninguno
* [x] Revisar dependencias innecesarias — eliminadas (escpos, dotenv, pg, código demo)
* [x] Mejorar estructura general — OK
* [x] Mejorar mantenibilidad — documentación, scripts, manejo de errores
* [x] Verificar consistencia completa — sistema estable en producción
* [x] Validar funcionamiento final — todos los servicios activos y verificados
* [x] Crear estado "estable y documentado" — ✅ sistema en producción con monitoreo profesional
