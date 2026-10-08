#!/bin/bash
# IP estatica 192.168.1.54 — generado oct 2026
set -e
NETPLAN=/etc/netplan/00-installer-config.yaml
cp "$NETPLAN" "${NETPLAN}.bak.$(date +%Y%m%dT%H%M%S)"
tee "$NETPLAN" > /dev/null << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s31f6:
      dhcp4: no
      addresses:
        - 192.168.1.54/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOF
echo "Aplicando... la sesion SSH se va a cortar."
netplan apply
