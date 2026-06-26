#!/bin/bash
# Configura IP estática en Ubuntu Server usando netplan.
# Correr con: sudo bash scripts/configurar_ip_estatica.sh

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ── Verificar root ────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Este script debe correrse como root:${RESET}"
  echo "  sudo bash scripts/configurar_ip_estatica.sh"
  exit 1
fi

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Cantina POS — Configurar IP estática   ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── Detectar interfaz de red ──────────────────────────────────────────────────
IFACE=$(ip route show default 2>/dev/null | awk '{print $5}' | head -1)
if [[ -z "$IFACE" ]]; then
  IFACE=$(ip link show | grep -E "^[0-9]+:" | grep -v lo | awk -F': ' '{print $2}' | head -1)
fi

echo -e "Interfaz detectada: ${BOLD}${IFACE}${RESET}"
echo -e "IP actual:          ${BOLD}$(hostname -I | awk '{print $1}')${RESET}"
echo -e "Gateway actual:     ${BOLD}$(ip route show default | awk '{print $3}' | head -1)${RESET}"
echo ""

# ── Detectar gateway actual como sugerencia ───────────────────────────────────
GATEWAY_ACTUAL=$(ip route show default | awk '{print $3}' | head -1)

# ── Pedir datos al usuario ────────────────────────────────────────────────────
echo -e "${YELLOW}Ingresá los datos para la IP estática:${RESET}"
echo ""

read -rp "  IP a asignar al servidor (ej: 192.168.1.50): " IP_NUEVA
if [[ -z "$IP_NUEVA" ]]; then
  echo -e "${RED}Error: IP no puede estar vacía.${RESET}"; exit 1
fi

read -rp "  Máscara de red en formato CIDR (default: 24 → /24 = 255.255.255.0): " MASCARA
MASCARA=${MASCARA:-24}

read -rp "  Gateway (puerta de enlace, IP del router) [default: $GATEWAY_ACTUAL]: " GATEWAY
GATEWAY=${GATEWAY:-$GATEWAY_ACTUAL}
if [[ -z "$GATEWAY" ]]; then
  echo -e "${RED}Error: gateway no puede estar vacío.${RESET}"; exit 1
fi

read -rp "  DNS primario   [default: 8.8.8.8]: " DNS1
DNS1=${DNS1:-8.8.8.8}

read -rp "  DNS secundario [default: 1.1.1.1]: " DNS2
DNS2=${DNS2:-1.1.1.1}

echo ""
echo -e "${BOLD}Resumen de la configuración:${RESET}"
echo "  Interfaz : $IFACE"
echo "  IP       : ${IP_NUEVA}/${MASCARA}"
echo "  Gateway  : $GATEWAY"
echo "  DNS      : $DNS1, $DNS2"
echo ""
read -rp "¿Confirmar y aplicar? [s/N]: " CONFIRM
if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
  echo "Cancelado."; exit 0
fi

# ── Detectar archivo netplan activo ───────────────────────────────────────────
NETPLAN_FILE=$(ls /etc/netplan/*.yaml 2>/dev/null | head -1)
if [[ -z "$NETPLAN_FILE" ]]; then
  NETPLAN_FILE="/etc/netplan/00-cantina-static.yaml"
fi

# ── Backup del netplan actual ─────────────────────────────────────────────────
BACKUP="${NETPLAN_FILE}.bak.$(date +%Y%m%dT%H%M%S)"
cp "$NETPLAN_FILE" "$BACKUP" 2>/dev/null || true
echo "Backup guardado en: $BACKUP"

# ── Escribir nueva config netplan ─────────────────────────────────────────────
cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${IFACE}:
      dhcp4: no
      addresses:
        - ${IP_NUEVA}/${MASCARA}
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${DNS1}, ${DNS2}]
EOF

echo ""
echo "Archivo netplan actualizado: $NETPLAN_FILE"

# ── Aplicar configuración ─────────────────────────────────────────────────────
echo "Aplicando configuración..."
netplan apply

echo ""
echo -e "${GREEN}${BOLD}✅ IP estática configurada correctamente.${RESET}"
echo ""
echo "  Nueva IP del servidor : ${BOLD}${IP_NUEVA}${RESET}"
echo "  Acceso POS            : ${BOLD}http://${IP_NUEVA}/${RESET}"
echo "  Cocina                : ${BOLD}http://${IP_NUEVA}/cocina.html${RESET}"
echo "  Autoservicio          : ${BOLD}http://${IP_NUEVA}/autoservicio.html${RESET}"
echo "  TV Promociones        : ${BOLD}http://${IP_NUEVA}/promo.html${RESET}"
echo "  Monitor Netdata       : ${BOLD}http://${IP_NUEVA}/monitor/${RESET}"
echo "  SSH                   : ${BOLD}ssh cantina@${IP_NUEVA}${RESET}"
echo ""
echo -e "${YELLOW}⚠️  Si te conectás por SSH, esta sesión puede cortarse.${RESET}"
echo -e "   Reconectate con: ${BOLD}ssh cantina@${IP_NUEVA}${RESET}"
echo ""
