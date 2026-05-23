# TODO Proyecto Cantina POS

## PRIORIDAD ALTA — Estabilidad y Recovery

* [x] Auditar estructura completa del proyecto
* [x] Documentar arquitectura actual — ver ARCHITECTURE.md
* [x] Verificar flujo completo de inicio del sistema — orden correcto verificado
* [x] Verificar servicios systemd existentes — cantina-api, nginx, postgresql enabled
* [x] Confirmar autorestart de backend — Restart=always
* [x] Confirmar autorestart de nginx — Restart=always (override en /etc/systemd/system/nginx.service.d/)
* [x] Confirmar autorestart postgresql — Restart=on-failure (override en /etc/systemd/system/postgresql@18-main.service.d/)
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
* [x] Verificar recuperación tras reinicio del servidor — todos los servicios levantan solos
* [x] Verificar funcionamiento offline/LAN — CDN y fuentes movidos a local
* [x] Revisar manejo de pérdida de red local — fix marcarEntregado/marcarListo + indicador SIN CONEXIÓN
* [x] Verificar arranque automático completo tras reboot — orden correcto: postgresql → cantina-api → nginx (fix 502 aplicado)

## Backend

* [x] Revisar estructura del backend — un solo archivo limpio, sin duplicados
* [x] Detectar código duplicado — ninguno
* [x] Detectar rutas innecesarias — ninguna
* [x] Revisar middlewares — cors, json, static OK
* [x] Revisar validaciones — agregadas en rutas críticas (pedidos, cobrar, pago)
* [x] Revisar manejo de errores — try/catch en todas las rutas
* [x] Revisar seguridad básica — PUT /pedidos/:id restringido a solo estado
* [x] Revisar queries PostgreSQL — transacciones en pedidos, cobrar, cancelar, pagos
* [x] Revisar performance general — índices FK agregados, queries OK para escala actual
* [x] Revisar variables de entorno — en .env y systemd service, OK
* [x] Limpiar código no utilizado — dependencias no usadas eliminadas (escpos, dotenv, pg)
* [x] Revisar manejo de sesiones — PIN login, aceptable para LAN cerrada
* [x] Revisar flujo de pedidos — transacción atómica pedido+stock, guard doble cancelación
* [x] Revisar lógica de caja — cierre de caja OK
* [x] Revisar lógica de cocina — cambiar-estado via WebSocket OK
* [x] Revisar manejo de estado tiempo real — socket.io emite en todas las mutaciones
* [x] Revisar estabilidad websocket/socket.io — configuración OK
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
* [ ] Revisar modo kiosk — requiere tablets físicas
* [ ] Revisar responsive tablets — requiere tablets físicas
* [ ] Revisar velocidad de uso real — requiere uso real
* [x] Revisar errores visuales — fix pantalla en blanco en autoservicio
* [x] Revisar carga inicial — autoservicio muestra error si falla la carga, con reintento
* [x] Revisar manejo de errores frontend — fix autoservicio mostraba éxito aunque falle el envío
* [x] Revisar consistencia visual — OK
* [x] Revisar accesibilidad básica — OK para entorno cantina
* [x] Revisar flujo de cobro — OK
* [x] Revisar flujo de cancelación — OK (fix doble cancelación en backend)
* [x] Revisar flujo de cocina — fix cambiarEstado sin null check
* [x] Revisar flujo de administración — OK
* [ ] Crear documentación frontend

## PostgreSQL

* [x] Revisar estructura de base de datos — 8 modelos bien definidos en schema.prisma
* [x] Revisar índices — 6 índices FK agregados via migración Prisma
* [x] Revisar relaciones — OK, todas con FK correctas
* [x] Revisar integridad de datos — transacciones en backend para operaciones críticas
* [x] Revisar backups — script backup.sh, retiene últimos 30, backup antes de restore
* [ ] Probar restore completo desde cero
* [ ] Revisar usuarios y permisos de PostgreSQL
* [x] Revisar tamaño y crecimiento DB — DB pequeña (<50KB tablas), crecimiento lineal
* [x] Crear documentación DB — schema documentado en ARCHITECTURE.md

## Nginx / Infraestructura

* [x] Revisar configuración nginx — reverse proxy :80 → :3001 con WebSocket
* [x] Revisar reverse proxy — funcionando con soporte WebSocket
* [ ] Revisar puertos abiertos
* [ ] Revisar seguridad básica LAN
* [ ] Revisar manejo de errores nginx — custom error pages pendiente
* [ ] Revisar headers — headers de seguridad pendiente
* [ ] Revisar cache — estrategia de cache pendiente
* [x] Revisar logs nginx — limpios, logueando en cantina.access.log / cantina.error.log
* [x] Revisar startup order — After=cantina-api + wait_for_backend.sh (fix 502)
* [x] Documentar infraestructura — en ARCHITECTURE.md

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

## Monitoreo y Soporte

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

## Documentación Técnica

* [x] Crear ARCHITECTURE.md — completo
* [x] Crear README principal
* [x] Crear RECOVERY.md
* [x] Crear BACKUP_GUIDE.md
* [x] Crear DEPLOYMENT.md
* [x] Crear SERVER_INFO.md
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
* [ ] Guía visual simple — requiere capturas de pantalla
* [x] Errores comunes y solución — RECOVERY.md + OPERACION.md

## Calidad General

* [x] Detectar deuda técnica — identificada y corregida
* [x] Revisar archivos innecesarios — ninguno
* [x] Revisar dependencias innecesarias — eliminadas (escpos, dotenv, pg)
* [x] Mejorar estructura general — OK
* [x] Mejorar mantenibilidad — documentación, scripts, manejo de errores
* [ ] Verificar consistencia completa
* [ ] Validar funcionamiento final completo
* [ ] Verificar que nada importante se haya roto
* [ ] Crear estado "estable y documentado"
