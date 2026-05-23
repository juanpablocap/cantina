# Guía de backups — Cantina POS

---

## Tipos de backup

| Tipo | Script | Guarda | Retiene |
|---|---|---|---|
| **Base de datos** | `scripts/backup.sh` | Solo los datos (pg_dump) | Últimos 30 |
| **Sistema completo** | `scripts/backup_sistema.sh` | DB + código + configuración | Últimos 10 |

### Cuándo usar cada uno

- **Backup de DB**: uso diario, rápido (~segundos). Solo los datos. Sirve para recuperar datos borrados o corruptos.
- **Backup sistema**: antes de cambios importantes, o semanalmente. Sirve para levantar todo en un servidor nuevo.

---

## Hacer un backup manual

### Desde el dashboard

```bash
bash scripts/dashboard.sh
# Opción [3] Guardar copia de seguridad (datos)
# Opción [4] Guardar copia de seguridad completa
```

### Desde la terminal

```bash
# Solo base de datos
bash scripts/backup.sh

# Sistema completo
bash scripts/backup_sistema.sh
```

### Desde la app web

En el tab **Sistema** de la app → botón **Backup DB**.

---

## Dónde se guardan

```
cantina-pos/
└── backups/
    ├── cantina_20260522T183417.sql      ← backup de DB
    ├── cantina_20260523T090000.sql
    └── sistema/
        └── cantina_sistema_20260523T090000.tar.gz  ← backup completo
```

Los nombres incluyen fecha y hora (`YYYYMMDDTHHMMSS`).

---

## Restaurar un backup de base de datos

```bash
bash scripts/restore.sh backups/cantina_YYYYMMDDTHHMMSS.sql
```

El script automáticamente:
1. Hace un backup del estado actual (por seguridad)
2. Detiene el backend
3. Restaura el backup
4. Reinicia el backend

---

## Restaurar un backup de sistema completo

```bash
# Extraer
tar -xzf backups/sistema/cantina_sistema_YYYYMMDDTHHMMSS.tar.gz -C /tmp/

# Leer instrucciones
cat /tmp/cantina_sistema_YYYYMMDDTHHMMSS/RESTORE.md
```

El `RESTORE.md` tiene los pasos detallados para reinstalar todo en un servidor limpio.

---

## Qué incluye el backup de sistema

```
cantina_sistema_YYYYMMDDTHHMMSS/
├── RESTORE.md                        ← instrucciones de restauración
├── db/
│   └── cantina_pos.sql               ← base de datos completa
├── proyecto/                         ← código fuente (sin node_modules)
└── sistema/
    ├── nginx/cantina                 ← configuración nginx
    └── systemd/
        ├── cantina-api.service
        ├── nginx-restart.conf
        └── postgresql-restart.conf
```

---

## Recomendaciones

- Hacer backup de DB **antes de cualquier cambio importante** (subir precios, agregar productos, etc.)
- Hacer backup de sistema **una vez por semana** o antes de actualizaciones
- Los backups se guardan en el mismo servidor — para mayor seguridad, copiarlos a un pendrive o NAS periódicamente

```bash
# Copiar backup a pendrive (reemplazar /media/... con la ruta del pendrive)
cp backups/cantina_$(date +%Y%m%d)*.sql /media/cantina/backup_pendrive/
```
