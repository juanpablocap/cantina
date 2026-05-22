#!/bin/sh
# Espera hasta que el backend responda, máximo 30 segundos
for i in $(seq 1 30); do
  curl -sf http://localhost:3001/api/health > /dev/null 2>&1 && exit 0
  sleep 1
done
exit 1
