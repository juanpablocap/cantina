# Instalación en un nuevo lugar

Guía completa para instalar el servidor Cantina POS en una red nueva.

---

## Lo que necesitás antes de empezar

- El servidor (PC/NUC/mini-PC con Ubuntu Server instalado y el proyecto en `/home/cantina/cantina-pos/`)
- Un router con LAN (cualquier marca/modelo)
- La IP que querés asignar al servidor (ej: `192.168.1.50`)
- La IP del router/gateway (ej: `192.168.1.1` — normalmente es la .1 de la red)
- Un cable de red conectado del servidor al router
- Teclado + monitor enchufados al servidor (solo para el primer paso)

---

## Paso 1 — Configurar IP estática en el servidor

Conectate al servidor con teclado y monitor (o por SSH si todavía tenés acceso).

```bash
sudo bash /home/cantina/cantina-pos/scripts/configurar_ip_estatica.sh
```

El script te va a pedir:
- **IP a asignar** — la que elegiste para este lugar (ej: `192.168.1.50`)
- **Máscara** — dejá el default `24` (equivale a `255.255.255.0`, sirve para el 99% de las redes hogareñas/de oficina)
- **Gateway** — la IP del router (ej: `192.168.1.1`)
- **DNS** — dejá los defaults (`8.8.8.8` y `1.1.1.1`)

> ⚠️ Si estás conectado por SSH, la sesión se va a cortar al aplicar. Reconectate con `ssh cantina@<nueva-ip>`.

---

## Paso 2 — Verificar que el servidor levantó bien

Desde cualquier PC en la misma red, abrir el navegador y entrar a:

```
http://<ip-del-servidor>/
```

Debe aparecer la pantalla de login con PIN.

Si no carga, desde el servidor correr:

```bash
bash /home/cantina/cantina-pos/scripts/healthcheck.sh
```

---

## Paso 3 — Configurar las tablets y pantallas

En cada tablet/PC que use el sistema, abrir el navegador y apuntarlo a:

| Pantalla | URL |
|---|---|
| POS principal (caja) | `http://<ip-del-servidor>/` |
| Cocina | `http://<ip-del-servidor>/cocina.html` |
| Autoservicio (kiosko) | `http://<ip-del-servidor>/autoservicio.html` |
| TV Promociones | `http://<ip-del-servidor>/promo.html` |
| Monitor técnico | `http://<ip-del-servidor>/monitor/` |

Reemplazá `<ip-del-servidor>` con la IP que configuraste en el Paso 1.

> 💡 **Tip:** En cada dispositivo, crear un marcador/favorito en el navegador para no tener que tipear la IP cada vez.

---

## Paso 4 — Verificar autorestart (servicios al encender)

Todos los servicios están configurados para arrancar solos al encender el servidor. Para verificarlo:

```bash
sudo systemctl status cantina-api nginx postgresql
```

Los tres deben mostrar `active (running)`.

---

## Resolución de problemas comunes

### La página no carga desde las tablets

1. Verificar que la tablet está en la **misma red WiFi** que el servidor
2. Verificar que el servidor está encendido
3. Desde el servidor: `ping <ip-del-router>` — si no responde, verificar cable de red
4. Correr `bash scripts/healthcheck.sh` y revisar qué servicio falla

### El servidor no arranca con la IP nueva después de reiniciar

```bash
sudo netplan apply
sudo systemctl restart systemd-networkd
```

### Necesito cambiar la IP nuevamente

Simplemente volvé a correr el script:

```bash
sudo bash /home/cantina/cantina-pos/scripts/configurar_ip_estatica.sh
```

Hace un backup automático del netplan anterior antes de sobrescribir.

### Error 502 Bad Gateway en el navegador

El backend todavía está iniciando. Esperar 15-20 segundos y recargar. Si persiste:

```bash
bash scripts/restart_all.sh
```

---

## Datos a anotar para este lugar

Completar después de la instalación:

```
IP del servidor  : ________________
Gateway (router) : ________________
Red WiFi nombre  : ________________
Red WiFi clave   : ________________
Fecha instalación: ________________
```
