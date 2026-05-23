# Cantina POS

Sistema de punto de venta para cantina. Corre 100% en red local (LAN), sin dependencia de internet.

## Stack

| Componente | Tecnología |
|---|---|
| Backend | Node.js 20 + Express + Socket.io |
| Base de datos | PostgreSQL 18 + Prisma ORM |
| Frontend | React (Babel in-browser) + Vite (dev) |
| Servidor web | Nginx (reverse proxy :80 → :3001) |
| OS | Ubuntu 26.04 LTS |

## Vistas

| URL | Pantalla |
|---|---|
| `http://<IP>/` | POS principal — caja, cocina, admin, clientes, reportes |
| `http://<IP>/cocina.html` | Vista cocina — pantalla grande, sin mouse |
| `http://<IP>/autoservicio.html` | Autoservicio — tablets de clientes |
| `http://<IP>/promo.html` | TV promociones — carrusel fullscreen para el salón |

## Documentación

| Archivo | Contenido |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Arquitectura técnica completa |
| [SERVER_INFO.md](SERVER_INFO.md) | Datos del servidor, rutas, servicios |
| [RECOVERY.md](RECOVERY.md) | Qué hacer cuando algo falla |
| [BACKUP_GUIDE.md](BACKUP_GUIDE.md) | Cómo funcionan los backups |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Instalación desde cero |
| [OPERACION.md](OPERACION.md) | Manual de uso para operadores |

## Comandos rápidos

```bash
# Dashboard interactivo
bash scripts/dashboard.sh

# Estado del sistema
bash scripts/healthcheck.sh

# Reiniciar todo
bash scripts/restart_all.sh

# Backup de la base de datos
bash scripts/backup.sh

# Backup completo del sistema
bash scripts/backup_sistema.sh
```

## Estructura del proyecto

```
cantina-pos/
├── server.js          # Backend (Express + Socket.io + Prisma)
├── client/dist/       # Frontend compilado (producción)
├── prisma/            # Schema y migraciones de DB
├── scripts/           # Scripts de mantenimiento
└── backups/           # Backups de la base de datos
```

Ver [ARCHITECTURE.md](ARCHITECTURE.md) para detalles completos.
