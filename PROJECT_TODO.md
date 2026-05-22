# TODO Proyecto Cantina POS

## PRIORIDAD ALTA — Estabilidad y Recovery

* [x] Auditar estructura completa del proyecto
* [x] Documentar arquitectura actual — ver ARCHITECTURE.md
* [ ] Verificar flujo completo de inicio del sistema
* [x] Verificar servicios systemd existentes — cantina-api, nginx, postgresql enabled
* [x] Confirmar autorestart de backend — Restart=always
* [x] Confirmar autorestart de nginx — Restart=always (override en /etc/systemd/system/nginx.service.d/)
* [x] Confirmar autorestart postgresql — Restart=on-failure (override en /etc/systemd/system/postgresql@18-main.service.d/)
* [ ] Confirmar autorestart kiosk/chromium
* [x] Revisar manejo de errores críticos — fix sudo -n en restart y clear-cache
* [x] Revisar logs del sistema — sin errores críticos
* [x] Revisar logs backend — fix sudo sin flag -n causaba auth failures silenciosos
* [x] Revisar logs nginx — limpio
* [x] Revisar manejo de errores PostgreSQL — logs limpios, índices FK agregados, startup order correcto
* [x] Crear script restart_backend.sh
* [x] Crear script restart_all.sh
* [x] Crear script backup.sh
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
* [x] Limpiar código no utilizado — dependencias no usadas eliminadas
* [x] Revisar manejo de sesiones — PIN login, aceptable para LAN cerrada
* [x] Revisar flujo de pedidos — transacción atómica pedido+stock, guard doble cancelación
* [x] Revisar lógica de caja — cierre de caja OK
* [x] Revisar lógica de cocina — cambiar-estado via WebSocket OK
* [x] Revisar manejo de estado tiempo real — socket.io emite en todas las mutaciones
* [x] Revisar estabilidad websocket/socket.io — configuración OK
* [x] Crear documentación técnica backend — ver ARCHITECTURE.md

## Frontend / UX

* [ ] Auditar experiencia touchscreen
* [ ] Detectar puntos de fricción
* [ ] Reducir cantidad de clicks necesarios
* [ ] Aumentar tamaño de botones táctiles
* [ ] Mejorar feedback visual
* [ ] Mejorar estados seleccionados
* [ ] Revisar navegación completa
* [ ] Revisar legibilidad general
* [ ] Revisar modo kiosk
* [ ] Revisar responsive tablets
* [ ] Revisar velocidad de uso real
* [ ] Revisar errores visuales
* [ ] Revisar carga inicial
* [ ] Revisar manejo de errores frontend
* [ ] Revisar consistencia visual
* [ ] Revisar accesibilidad básica
* [ ] Revisar flujo de cobro
* [ ] Revisar flujo de cancelación
* [ ] Revisar flujo de cocina
* [ ] Revisar flujo de administración
* [ ] Crear documentación frontend

## PostgreSQL

* [ ] Revisar estructura de base de datos
* [ ] Revisar índices
* [ ] Revisar relaciones
* [ ] Revisar integridad de datos
* [ ] Revisar backups
* [ ] Probar restore completo
* [ ] Revisar usuarios y permisos
* [ ] Revisar tamaño y crecimiento DB
* [ ] Crear documentación DB

## Nginx / Infraestructura

* [x] Revisar configuración nginx — configurado como reverse proxy :80 → :3001
* [x] Revisar reverse proxy — funcionando con soporte WebSocket
* [ ] Revisar puertos abiertos
* [ ] Revisar seguridad básica LAN
* [ ] Revisar manejo de errores nginx
* [ ] Revisar headers
* [ ] Revisar cache
* [ ] Revisar logs nginx
* [ ] Revisar startup order
* [ ] Documentar infraestructura

## Kiosk / Tablets

* [ ] Revisar Chromium kiosk
* [ ] Revisar fullscreen real
* [ ] Revisar reconexión automática
* [ ] Revisar comportamiento touchscreen
* [ ] Revisar manejo de errores visuales
* [ ] Revisar comportamiento tras reboot
* [ ] Revisar estabilidad XRDP
* [ ] Revisar audio/notificaciones
* [ ] Revisar consumo de recursos
* [ ] Crear guía de tablets/kiosk

## Monitoreo y Soporte

* [ ] Crear dashboard SSH/TUI básico
* [ ] Mostrar estado servicios
* [ ] Mostrar estado PostgreSQL
* [ ] Mostrar estado nginx
* [ ] Mostrar estado backend
* [ ] Mostrar uso CPU/RAM/disco
* [ ] Mostrar IP local
* [ ] Mostrar uptime
* [ ] Mostrar último backup
* [ ] Agregar acciones restart rápidas
* [ ] Agregar visualización rápida logs

## Documentación Técnica

* [ ] Crear README principal
* [ ] Crear ARCHITECTURE.md
* [ ] Crear RECOVERY.md
* [ ] Crear BACKUP_GUIDE.md
* [ ] Crear DEPLOYMENT.md
* [ ] Crear SERVER_INFO.md
* [ ] Documentar estructura carpetas
* [ ] Documentar puertos
* [ ] Documentar dependencias
* [ ] Documentar servicios systemd
* [ ] Documentar comandos útiles
* [ ] Documentar troubleshooting

## Manual Cliente / Operación

* [ ] Manual básico de uso
* [ ] Cómo iniciar sistema
* [ ] Cómo reiniciar sistema
* [ ] Qué hacer si falla
* [ ] Cómo usar pedidos
* [ ] Cómo cobrar
* [ ] Cómo cancelar pedidos
* [ ] Cómo administrar productos
* [ ] Cómo revisar cocina
* [ ] Guía visual simple
* [ ] Errores comunes y solución

## Calidad General

* [ ] Detectar deuda técnica
* [ ] Revisar archivos innecesarios
* [ ] Revisar dependencias innecesarias
* [ ] Mejorar estructura general
* [ ] Mejorar mantenibilidad
* [ ] Verificar consistencia completa
* [ ] Validar funcionamiento final completo
* [ ] Verificar que nada importante se haya roto
* [ ] Crear estado “estable y documentado”
