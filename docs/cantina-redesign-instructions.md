# Cantina POS — Rediseño UI para Tablet

## Contexto
El POS corre en tablets Samsung ~10" con Android. La barra del sistema de Android ocupa espacio abajo.
El diseño actual está pensado para monitor grande. Necesitamos optimizar para touch en pantalla chica
SIN romper la funcionalidad existente.

**Regla de oro:** Esto es un tercer tema llamado `tablet` que se agrega al objeto `THEMES`.
Los temas `modern` y `classic` NO se tocan. El usuario puede volver a cualquier tema anterior.

---

## CAMBIO 1 — Agregar tema "tablet" al objeto THEMES

Agregar una tercera entrada al objeto `THEMES` (línea ~74 de index.html):

```javascript
tablet: {
  bg:           "#070A12",
  surface:      "#0D1120",
  surfaceHover: "#131829",
  border:       "#1A2140",
  text:         "#EAF0FF",
  muted:        "#4A5578",
  accent:       "#6366F1",   // mismo indigo que modern
  accentHover:  "#4F52D8",
  success:      "#10B981",
  warning:      "#F59E0B",
  danger:       "#EF4444",
  info:         "#3B82F6",
  tabBg:        "transparent",
  tabActive:    "#6366F1",
  tabBadge:     "solid",
},
```

Los colores son iguales a `modern`. La diferencia está en el LAYOUT y TAMAÑOS, no en los colores.

Cambiar el toggle de tema para que cicle entre los 3:
```javascript
const themeOrder = ['modern', 'classic', 'tablet'];
const next = themeOrder[(themeOrder.indexOf(theme) + 1) % themeOrder.length];
```

Y el label del botón:
- modern → "☀️ Clásico"
- classic → "📱 Tablet"  
- tablet → "🌙 Moderno"

---

## CAMBIO 2 — Tamaños base para tema tablet

Cuando `theme === 'tablet'`, aplicar estos overrides de tamaño globalmente:

```
Textos generales:        +2px respecto al tema modern
Nombres de productos:    18px → 20px, font-weight 500
Precios:                 16px → 20px, font-weight 600
Botones touch target:    mínimo 48px de alto
Números de mesa:         mínimo 48x48px touch target
Badges (COCINA/DIRECTO): 12px → 14px, padding 4px 10px
```

---

## CAMBIO 3 — Pantalla MESAS (rediseño completo)

### Actual
Cuadraditos de 48px con solo el número. Sin info.

### Nuevo (solo en tema tablet, los otros temas mantienen el diseño actual)
Cada mesa es una CARD que muestra:

**Layout de la card:**
```
┌─────────────────────────┐
│ 1          ● Preparando │  ← número grande (20px bold) + badge estado
│                         │
│ 1× Lomo completo       │  ← items del pedido activo (color #E2E6F0)
│ 2× Cerveza Quilmes     │
│ +1 item                │  ← si hay más de 3 items, colapsar
│─────────────────────────│
│ ⏱ 12:34        $14,500 │  ← timer + total
└─────────────────────────┘
```

**Estados y colores:**
- `libre` → card opaca (opacity 0.35), colapsada (solo muestra número, 1 línea), sin border-left
- `ocupada/preparando` → border-left 3px warning (#F59E0B), badge "Preparando" bg warning/20
- `lista` → border-left 3px success (#10B981), badge "Listo" bg success/20, número en color success
- `por_cobrar` → border-left 3px accent (#6366F1), badge "Por cobrar" bg accent/20
- `urgente` (>30 min) → border-left 3px danger (#EF4444), badge "+30 min" bg danger/20, timer en rojo

**Grid:** `grid-template-columns: repeat(auto-fill, minmax(148px, 1fr))`, gap 8px

**Ordenamiento:** urgentes primero, luego por cobrar, listas, preparando, libres al final

**Subheader con stats:**
```
MESAS — 6 ocupadas de 40    ● 18 preparando  ● 5 listas  ● 3 por cobrar  ● 2 urgentes
                                                [Todas] [Ocupadas] [Listas] [Cobrar] [Urgentes]
```
- Filtros con contadores: `[Todas 40] [Ocupadas 28] [Listas 5] [Cobrar 3]`
- Filtro "Urgentes" en rojo si hay alguna

**De dónde salen los datos:**
- Items del pedido: del pedido activo asociado a esa mesa (ya existe en el estado)
- Timer: diferencia entre ahora y hora de creación del pedido
- Total: suma de items del pedido
- Estado: derivado del estado del pedido (pendiente→preparando, listo→listo, entregado→por cobrar, sin pedido→libre)

---

## CAMBIO 4 — Pantalla VENTA (optimización tablet)

### Cards de productos
- Grid: `repeat(auto-fill, minmax(140px, 1fr))` (actual es más chico)
- Nombre producto: 16px, color #E2E6F0 (casi blanco, actualmente es grisáceo)
- Precio: 18px bold, color del accent
- Stock: 12px, color muted
- Badge COCINA/DIRECTO: 13px, padding 3px 8px
- Badge ¡POCO!: más visible, 13px bold

### Panel derecho (carrito)
- Números de mesa: mínimo 44x44px para touch, font-size 16px
- Botones Mesa/Barra: más grandes, 44px alto
- Items del carrito: font-size 15px
- Botón ENVIAR A COCINA: 52px alto, font-size 16px bold
- TOTAL: 24px bold

---

## CAMBIO 5 — Pantalla COCINA (optimización densidad)

### Actual
Cards muy altas, con 8+ pedidos hay que scrollear mucho.

### Ajustes
- Reducir padding de las cards: 20px → 14px
- Número de pedido: mantener grande (es lo más importante)
- Items: una sola línea por item, más compacto
- Botón EMPEZAR A PREPARAR: 44px alto (mantener grande para touch)
- Grid: `repeat(auto-fill, minmax(240px, 1fr))` para que entren más cards

---

## CAMBIO 6 — Pantalla PEDIDOS

- Cards de pedido: mantener layout actual, aumentar font-size del # y mesa
- Botones de acción (Cobrar, Entregado, etc.): mínimo 44px alto
- Items del pedido: 14px, color #E2E6F0

---

## CAMBIO 7 — Pantalla CLIENTES

- Mantener layout de lista actual (funciona bien)
- Aumentar font-size nombre: 16px → 18px
- Apodo entre comillas: mantener color accent
- Saldo: 18px bold
- Touch targets de acciones (teléfono, eliminar, fiado): mínimo 44x44px
- Avatar con iniciales: 40px → 44px

---

## CAMBIO 8 — Pantalla PRODUCTOS

- Mantener layout de lista actual
- Nombre producto: 16px → 18px
- Precio: mantener accent color, 16px
- Stock: números más grandes 16px
- Botones +/- stock: mínimo 40x40px touch target
- Stock bajo (resaltado rojo): mantener, border más visible

---

## CAMBIO 9 — Pantalla CAJA

- Cards de resumen (Efectivo, Transferencias, Fiado, Total): mantener layout
- Montos: 28px bold
- Cards de cobros pendientes: mantener layout actual
- Botón "Cobrar ahora": mínimo 48px alto
- Botón "Hacer Cierre de Caja": mantener prominente

---

## CAMBIO 10 — Pantalla SISTEMA

- No tocar. Está perfecta para uso admin desde monitor grande.
- En tablet no se usa Sistema normalmente.

---

## IMPLEMENTACIÓN

### Estrategia
1. El tema `tablet` usa los mismos colores que `modern`
2. La diferencia son clases CSS condicionales: `className={theme === 'tablet' ? 'tablet-mode' : ''}`
3. O mejor: un wrapper div con `data-theme="tablet"` que escala tamaños via CSS
4. Los cambios de MESAS son los más grandes — hacer primero y probar
5. El resto son ajustes de tamaño incrementales

### Orden de implementación
1. Agregar tema al THEMES + cambiar toggle
2. Mesas (rediseño completo)
3. Venta (tamaños + panel carrito)
4. Cocina (compactar cards)
5. Resto de pantallas (ajustes menores)

### Testing
- Probar en tablet Samsung real
- Verificar que temas modern y classic siguen iguales
- Verificar touch targets con dedos reales
- Probar con 0, 5, 20, 40 mesas ocupadas
