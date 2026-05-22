#!/bin/bash
set -e

echo "Configurando autorestart para nginx y PostgreSQL..."

# nginx override
mkdir -p /etc/systemd/system/nginx.service.d
cat > /etc/systemd/system/nginx.service.d/restart.conf << 'EOF'
[Service]
Restart=always
RestartSec=5
EOF

# postgresql override
mkdir -p /etc/systemd/system/postgresql@18-main.service.d
cat > /etc/systemd/system/postgresql@18-main.service.d/restart.conf << 'EOF'
[Service]
Restart=on-failure
RestartSec=10
EOF

systemctl daemon-reload

echo ""
echo "Verificando..."
echo -n "  nginx Restart="; systemctl show nginx --property=Restart | cut -d= -f2
echo -n "  postgresql Restart="; systemctl show postgresql@18-main --property=Restart | cut -d= -f2
echo ""
echo "Listo."
