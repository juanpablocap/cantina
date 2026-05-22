# TODO Proyecto Cantina POS

## PRIORIDAD ALTA — Estabilidad y Recovery

* [ ] Auditar estructura completa del proyecto
* [ ] Documentar arquitectura actual
* [ ] Verificar flujo completo de inicio del sistema
* [ ] Verificar servicios systemd existentes
* [ ] Confirmar autorestart de backend
* [ ] Confirmar autorestart de nginx
* [ ] Confirmar autorestart kiosk/chromium
* [ ] Revisar manejo de errores críticos
* [ ] Revisar logs del sistema
* [ ] Revisar logs backend
* [ ] Revisar logs nginx
* [ ] Revisar manejo de errores PostgreSQL
* [ ] Crear script restart_backend.sh
* [ ] Crear script restart_all.sh
* [ ] Crear script backup.sh
* [ ] Crear script restore.sh
* [ ] Crear script healthcheck.sh
* [ ] Verificar recuperación tras reinicio del servidor
* [ ] Verificar funcionamiento offline/LAN
* [ ] Revisar manejo de pérdida de red local
* [ ] Verificar arranque automático completo tras reboot

## Backend

* [ ] Revisar estructura del backend
* [ ] Detectar código duplicado
* [ ] Detectar rutas innecesarias
* [ ] Revisar middlewares
* [ ] Revisar validaciones
* [ ] Revisar manejo de errores
* [ ] Revisar seguridad básica
* [ ] Revisar queries PostgreSQL
* [ ] Revisar performance general
* [ ] Revisar variables de entorno
* [ ] Limpiar código no utilizado
* [ ] Revisar manejo de sesiones
* [ ] Revisar flujo de pedidos
* [ ] Revisar lógica de caja
* [ ] Revisar lógica de cocina
* [ ] Revisar manejo de estado tiempo real
* [ ] Revisar estabilidad websocket/socket.io
* [ ] Crear documentación técnica backend

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

* [ ] Revisar configuración nginx
* [ ] Revisar reverse proxy
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
