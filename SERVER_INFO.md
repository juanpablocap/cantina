# Información del servidor — Cantina POS

## Datos de acceso

| | |
|---|---|
| **IP local** | 192.168.100.54 |
| **Hostname** | cantina-server |
| **OS** | Ubuntu 26.04 LTS |
| **Usuario** | cantina |
| **Acceso SSH** | `ssh cantina@192.168.100.54` |

## Hardware

| Recurso | Valor |
|---|---|
| RAM | 7.1 GB |
| Disco | 98 GB |

## Servicios

| Servicio | Puerto | Estado | Restart |
|---|---|---|---|
| `cantina-api` | 3001 | enabled | always (5s) |
| `nginx` | 80 | enabled | always (5s) |
| `postgresql@18-main` | 5432 | enabled | on-failure (10s) |

## Rutas importantes

| Qué | Ruta |
|---|---|
| Proyecto | `/home/cantina/cantina-pos/` |
| Backend | `/home/cantina/cantina-pos/server.js` |
| Frontend | `/home/cantina/cantina-pos/client/dist/` |
| Backups DB | `/home/cantina/cantina-pos/backups/` |
| Backups sistema | `/home/cantina/cantina-pos/backups/sistema/` |
| Scripts | `/home/cantina/cantina-pos/scripts/` |
| Config nginx | `/etc/nginx/sites-enabled/cantina` |
| Service systemd | `/etc/systemd/system/cantina-api.service` |

## Logs

| Servicio | Comando |
|---|---|
| Backend | `journalctl -u cantina-api -f` |
| Nginx acceso | `tail -f /var/log/nginx/cantina.access.log` |
| Nginx errores | `tail -f /var/log/nginx/cantina.error.log` |
| PostgreSQL | `journalctl -u postgresql -f` |

## Base de datos

| | |
|---|---|
| **Motor** | PostgreSQL 18.3 |
| **Base de datos** | `cantina_pos` |
| **Usuario DB** | `cantina` |
| **Contraseña DB** | `cantina2025` |
| **Puerto** | 5432 |
| **Connection string** | `postgresql://cantina:cantina2025@localhost:5432/cantina_pos` |

## Node.js

| | |
|---|---|
| **Versión** | v20.20.2 |
| **Puerto app** | 3001 |
| **Variable de entorno** | `NODE_ENV=production` |

## Versiones de software

```
Node.js  v20.20.2
PostgreSQL 18.3
Nginx (ver: nginx -v)
```

## URLs del sistema

```
App principal:   http://192.168.100.54/
Cocina:          http://192.168.100.54/cocina.html
Autoservicio:    http://192.168.100.54/autoservicio.html
TV Promociones:  http://192.168.100.54/promo.html
Monitor Netdata: http://192.168.100.54/monitor/
API health:      http://192.168.100.54/api/health
```

## Monitoreo — Netdata

Dashboard profesional de métricas del servidor en tiempo real.

- **URL:** `http://192.168.100.54/monitor/`
- **También desde el POS:** pestaña Sistema → botón **📊 Monitor**
- **Instalación:** `sudo bash scripts/setup_netdata.sh` (requiere internet solo la primera vez)
- **Puerto interno:** 19999 (bind a localhost, acceso solo vía nginx)
- **Métricas:** CPU, RAM, disco, red, procesos, temperatura, y más
- **Resolución:** 1 segundo, historial de horas/días incluido

El POS también muestra sparklines inline (CPU, RAM, disco, red RX/TX) con los últimos 10 minutos de historial usando `GET /api/system/history`.

## TV Promociones (carrusel)

La pantalla del TV debe abrir `http://192.168.100.54/promo.html` en modo pantalla completa.

- Las imágenes se gestionan desde la pestaña **Sistema → Imágenes Carrusel** del POS principal
- Se guardan en `/home/cantina/cantina-pos/images/`
- La página del TV se actualiza automáticamente cada 30 segundos
- Cada imagen se muestra durante 8 segundos con transición suave
- Para configurar el TV: apuntarlo siempre a la IP `192.168.100.54` (IP fija del servidor)
