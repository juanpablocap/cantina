# Manual de operación — Cantina POS

Guía para el personal que opera el sistema día a día.

---

## Acceso al sistema

Abrir en el navegador: **http://192.168.100.54/**

Al entrar pide un PIN de 4 dígitos según el rol del usuario.

---

## Pantallas disponibles

| Pantalla | URL | Quién la usa |
|---|---|---|
| POS principal | `http://192.168.100.54/` | Cajero, admin, cocina |
| Cocina | `http://192.168.100.54/cocina.html` | Cocineros |
| Autoservicio | `http://192.168.100.54/autoservicio.html` | Clientes (tablet) |
| TV Promociones | `http://192.168.100.54/promo.html` | TV del salón |

---

## Tomar un pedido (tab Venta)

1. Tocar los **productos** del menú para agregarlos al carrito
2. Seleccionar **Mesa** o **Barra**
   - Si es mesa: elegir el número de mesa
   - Si es barra: escribir el nombre del cliente (opcional)
3. Revisar el total abajo a la derecha
4. Tocar **ENVIAR A COCINA** (o **DESPACHAR Y COBRAR** si son solo bebidas)

El pedido aparece automáticamente en la pantalla de cocina.

---

## Cobrar un pedido (tab Pedidos o Mesas)

### Desde Pedidos

1. Ir al tab **Pedidos**
2. Buscar el pedido con estado **Listo** o **Entregado**
3. Tocar **💰 Cobrar**
4. Seleccionar método de pago: Efectivo, Transferencia o Fiado
5. Confirmar

### Desde Mesas

1. Ir al tab **Mesas**
2. Tocar la mesa que tiene pedidos
3. Seleccionar los pedidos a cobrar
4. Tocar **Cobrar seleccionados**

---

## Cancelar un pedido

1. Ir al tab **Pedidos**
2. Tocar el botón **❌** en el pedido a cancelar
3. Ingresar el PIN de autorización
4. Confirmar

El stock se restaura automáticamente.

---

## Editar un pedido ya enviado a cocina

1. Ir al tab **Pedidos**
2. Tocar el botón **✏️** en el pedido (aparece si está pendiente, en preparación o listo)
3. Modificar cantidades con **−** y **+**, o eliminar con **🗑**
4. Agregar productos nuevos desde el catálogo de abajo
5. Tocar **💾 Guardar cambios**

La cocina verá automáticamente el aviso **PEDIDO MODIFICADO** en su pantalla.

---

## Vista de cocina

La pantalla de cocina muestra todos los pedidos activos con un temporizador.

| Color del borde | Estado |
|---|---|
| Rojo (pulsando) | Nuevo pedido — pendiente |
| Amarillo | En preparación |
| Verde | Listo para entregar |

### Acciones

- **🔥 EMPEZAR A PREPARAR** → marca el pedido como en preparación
- **✅ LISTO PARA ENTREGAR** → avisa que el pedido está listo
- **📦 ENTREGADO** → el pedido sale de la pantalla

### Pedido modificado

Si desde caja modificaron un pedido ya enviado, aparece un banner azul **✏️ PEDIDO MODIFICADO**. Leer los cambios y tocar **✓ VISTO** para confirmar.

---

## Cierre de caja

1. Ir al tab **Caja**
2. Revisar el resumen del día
3. Ingresar el **efectivo contado** en el arqueo
4. Tocar **Cerrar Caja**
5. Se genera un reporte que se puede imprimir

---

## Administrar productos (tab Productos)

### Agregar producto

1. Tocar **+ Nuevo Producto**
2. Completar nombre, precio, stock y categoría
3. Indicar si va a cocina o es despacho directo
4. Tocar **💾 Guardar**

### Modificar precio o stock

1. En la lista de productos, tocar **✏️** en el producto
2. Cambiar los datos
3. Tocar **💾 Guardar**

### Agregar categoría

1. Tocar **+ Nueva Categoría**
2. Elegir nombre, emoji y color
3. Indicar si es de despacho directo (ej: bebidas)
4. Tocar **💾 Guardar**

---

## Carrusel de promociones en TV

La pantalla del TV muestra imágenes de promociones en carrusel automático.

### Cargar imágenes desde el pendrive

1. Conectar el pendrive con las fotos al servidor (o a la computadora)
2. Ir al tab **Sistema** en el POS principal
3. En la sección **Imágenes Carrusel**, tocar **📁 Abrir archivos**
4. Seleccionar las imágenes desde el pendrive (JPG, PNG, WEBP)
5. Las imágenes aparecen en la lista de "listas para importar"
6. Tocar **↑** para importar una a la vez, o **📥 Importar todas** para todas
7. Las imágenes quedan en la base de datos y aparecen automáticamente en el TV

### Eliminar una imagen

1. Ir al tab **Sistema**
2. En la lista **EN TV**, tocar el botón **🗑** de la imagen a eliminar

### El TV

- El TV debe tener abierta la página `http://192.168.100.54/promo.html`
- Las imágenes rotan automáticamente cada 8 segundos
- Si se agregan o eliminan imágenes, el TV se actualiza en menos de 30 segundos

---

## Clientes con cuenta corriente (tab Clientes)

- Los clientes con **fiado** acumulan saldo deudor
- En la lista se ve el saldo de cada cliente
- Para registrar un pago: tocar el cliente → **Registrar Pago**
- Al cobrar un pedido en fiado, el saldo se suma automáticamente

---

## Qué hacer si algo falla

Ver [RECOVERY.md](RECOVERY.md) para instrucciones detalladas.

### Resumen rápido

| Problema | Solución |
|---|---|
| La página no carga | Verificar WiFi de la tablet; si hay red, reiniciar la app (`bash scripts/restart_backend.sh`) |
| Aparece "SIN CONEXIÓN" | El servidor no responde — llamar al técnico |
| Un pedido no aparece en cocina | Actualizar la página de cocina (F5 o recargar) |
| Error al cobrar | Verificar conexión; reintentar |

Para problemas graves: `bash scripts/dashboard.sh` o llamar al técnico.
