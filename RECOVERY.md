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

## Contactos de soporte técnico

> Completar con datos del técnico responsable.
