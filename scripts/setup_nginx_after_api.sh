#!/bin/bash
set -e

chmod +x /home/cantina/cantina-pos/scripts/wait_for_backend.sh

cat > /etc/systemd/system/nginx.service.d/restart.conf << 'EOF'
[Unit]
After=cantina-api.service

[Service]
Restart=always
RestartSec=5
ExecStartPre=/home/cantina/cantina-pos/scripts/wait_for_backend.sh
EOF

systemctl daemon-reload

echo "Verificando configuración nginx..."
systemctl show nginx --property=After | grep -o "cantina-api" && echo "  ✓ After=cantina-api OK" || echo "  ✗ After no aplicado"
echo "Listo."
