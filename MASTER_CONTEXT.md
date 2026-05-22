# Cantina POS System

## Objetivo

Sistema POS touchscreen para cantina funcionando en red local/offline.
con una impresora termica para los tickets, tambien un tv que se conecte al servidor y pueda mostrar imagenes de ofertas, noticias etc

## Entorno

* Ubuntu Server
* PostgreSQL
* Node.js backend
* Vite frontend
* Nginx
* Chromium kiosk
* Tablets touchscreen
* Administración por SSH

## Filosofía del proyecto

Priorizar:

* estabilidad
* simplicidad
* claridad
* recovery rápido
* facilidad de soporte
* funcionamiento offline/LAN
* mantenibilidad a largo plazo

## Importante

El sistema YA funciona.
NO queremos una reescritura completa.
Queremos profesionalizar, ordenar y estabilizar el sistema existente.

## Objetivos técnicos

* estructura más limpia
* mejor organización
* documentación completa
* logs claros
* scripts de backup y restore
* autorestart de servicios
* mejor debugging
* mejor UX touchscreen
* reducir errores operativos
* mejorar mantenimiento

## UX Goals

El sistema será usado:

* con tablets touchscreen
* por usuarios no técnicos
* en ambientes rápidos y con presión
* posiblemente con mala iluminación
* con necesidad de velocidad y claridad

La interfaz debe priorizar:

* botones grandes
* pocos clicks
* feedback visual claro
* velocidad de operación
* simplicidad extrema

## Evitar

* complejidad innecesaria
* arquitectura enterprise
* microservicios
* dependencias cloud
* reescrituras innecesarias
* cambios riesgosos sin validación

## Reglas de trabajo

Antes de hacer cambios importantes:

* analizar
* explicar
* validar
* probar

Siempre:

* preservar funcionamiento existente
* verificar que el sistema siga funcionando
* ejecutar tests o validaciones
* documentar cambios
