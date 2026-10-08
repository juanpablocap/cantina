# Recuperación del sistema — Cantina POS

Guía de qué hacer cuando algo falla. Empezar siempre por el diagnóstico antes de actuar.

---

## 1. Diagnóstico rápido

```bash
bash scripts/healthcheck.sh
```

Muestra el estado de todos los servicios. Si algo tiene ✗, ese es el problema.

O desde el dashboard interactivo:

```bash
bash scripts/dashboard.sh
```

---

## 2. La app no responde / página en blanco

**Síntomas:** Las tablets no cargan la página, o da error de conexión.

### Paso 1 — verificar nginx

```bash
systemctl status nginx
```

Si está caído:
```bash
sudo systemctl restart nginx
```

### Paso 2 — verificar el backend

```bash
systemctl status cantina-api
curl http://localhost:3001/api/health
```

Si está caído:
```bash
bash scripts/restart_backend.sh
```

### Paso 3 — reinicio completo ordenado

Si los pasos anteriores no funcionan:
```bash
bash scripts/restart_all.sh
```

Reinicia en el orden correcto: PostgreSQL → cantina-api → nginx.

---

## 3. El backend se cae solo / se reinicia seguido

Revisar los logs para ver el error:

```bash
journalctl -u cantina-api -n 50 --no-pager
```

Causas comunes:
- **Error de base de datos**: PostgreSQL no está corriendo o hay un error de conexión
- **Puerto 3001 ocupado**: otro proceso usa el puerto (`lsof -i :3001`)
- **Error de código**: ver el mensaje de error en los logs

---

## 4. La base de datos no levanta

```bash
systemctl status postgresql
journalctl -u postgresql -n 30 --no-pager
```

Intentar reiniciar:
```bash
sudo systemctl restart postgresql
```

Si persiste el error, puede ser corrupción de datos. Ver sección **Restaurar backup**.

---

## 5. Se perdieron datos / hay que revertir

### Listar backups disponibles

```bash
ls -lh backups/*.sql
```

### Restaurar un backup

```bash
bash scripts/restore.sh backups/cantina_YYYYMMDDTHHMMSS.sql
```

El script hace un backup del estado actual antes de restaurar, por seguridad.

---

## 6. El servidor se reinició solo

Los servicios están configurados para levantarse solos tras un reboot. Si no levantaron:

```bash
# Ver qué está caído
bash scripts/healthcheck.sh

# Reiniciar todo en orden
bash scripts/restart_all.sh

# Si sigue sin funcionar, habilitar manualmente
sudo systemctl enable --now postgresql cantina-api nginx
```

---

## 7. Error 502 Bad Gateway en nginx

El backend todavía no levantó cuando nginx intentó conectarse.

```bash
bash scripts/restart_backend.sh   # espera hasta que el backend responda
sudo systemctl restart nginx
```

---

## 8. El sistema está muy lento

```bash
# Ver uso de recursos
bash scripts/healthcheck.sh

# Limpiar caché de RAM (no afecta datos)
curl -X POST http://localhost:3001/api/system/clear-cache
```

Si el disco está casi lleno (>85%):
```bash
# Ver qué ocupa espacio
du -sh /home/cantina/cantina-pos/backups/*
# Borrar backups viejos manualmente si es necesario
```

---

## 9. Restauración completa desde cero

Si el servidor muere y hay que levantar todo en hardware nuevo, usar el backup completo del sistema:

```bash
# Extraer el último backup de sistema
tar -xzf backups/sistema/cantina_sistema_YYYYMMDDTHHMMSS.tar.gz
cat cantina_sistema_YYYYMMDDTHHMMSS/RESTORE.md
```

El `RESTORE.md` tiene los pasos exactos para reinstalar todo desde cero.

---

## 10. Cambio de router / reubicación del servidor

### Reubicación octubre 2026 — completada

El servidor fue reubicado físicamente en octubre 2026. La red cambió de `192.168.100.x` a `192.168.1.x`.

| | Antes | Ahora |
|---|---|---|
| IP servidor | `192.168.100.54` | `192.168.1.54` (estática) |
| Router | `192.168.100.101` | `192.168.1.1` |

---

### Situación: servidor conectado a un router nuevo sin saber su rango IP

**El servidor ya está configurado en DHCP** (`/etc/netplan/00-installer-config.yaml`). Al conectarlo al nuevo router, obtiene IP automáticamente.

#### Ver la IP asignada

```bash
ip addr show enp0s31f6
```

Buscar la línea `inet X.X.X.X/24 scope global dynamic`.

#### Después — asignar IP fija

Una vez decidida la IP definitiva, usar el script (hace backup automático del netplan anterior):

```bash
sudo bash /home/cantina/cantina-pos/scripts/configurar_ip_estatica.sh
```

O editar manualmente `/etc/netplan/00-installer-config.yaml`:

```yaml
network:
  version: 2
  ethernets:
    enp0s31f6:
      addresses: [192.168.X.Y/24]
      routes:
        - to: default
          via: 192.168.X.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

Aplicar:

```bash
sudo netplan apply
```

> ⚠️ Si estás conectado por SSH, la sesión se va a cortar al aplicar. Reconectate con `ssh cantina@<nueva-ip>`.

#### Después de confirmar la IP fija — checklist completo

Actualizar la IP en **todos** los archivos del proyecto que la referencian (buscar con `grep -rn "192\.168\." . --include="*.md" --include="*.sh"`):

| Archivo | Qué cambiar |
|---|---|
| `CLAUDE.md` | línea `**Server:**` |
| `SERVER_INFO.md` | tabla IP local y acceso SSH |
| `MASTER_CONTEXT.md` | todas las URLs y línea `**Servidor:**` |
| `ARCHITECTURE.md` | sección Netdata |
| `OPERACION.md` | tabla de URLs de pantallas (×2) |
| `PROJECT_TODO.md` | item de Netdata |
| `scripts/monitor.sh` | variables `ROUTER=` y `SERVER=` |
| `guia-visual/generar_pdf.js` | comando scp de ejemplo |

Ejemplo para hacer el reemplazo en masa (ajustar IPs):
```bash
grep -rn "192\.168\.100\.54" . --include="*.md" --include="*.sh" --include="*.js" | grep -v node_modules
sed -i 's/192\.168\.100\.54/192.168.X.Y/g' CLAUDE.md SERVER_INFO.md MASTER_CONTEXT.md ARCHITECTURE.md OPERACION.md PROJECT_TODO.md scripts/monitor.sh guia-visual/generar_pdf.js
```

---

## Contactos de soporte técnico

> Completar con datos del técnico responsable.
