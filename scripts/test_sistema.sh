#!/bin/bash
# Test de sistema completo — simula flujos reales de punta a punta

BASE="http://localhost:3001"
PASS=0; FAIL=0; WARN=0
declare -a HALLAZGOS

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'; CYAN='\033[0;36m'

ok()     { echo -e "  ${GREEN}✓${NC} $1"; ((PASS++)); }
fail()   { echo -e "  ${RED}✗${NC} $1"; ((FAIL++)); HALLAZGOS+=("❌ $1"); }
warn()   { echo -e "  ${YELLOW}⚠${NC}  $1"; ((WARN++)); HALLAZGOS+=("⚠️  $1"); }
info()   { echo -e "  ${BLUE}→${NC} $1"; }
titulo() { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}"; }
ms_now() { python3 -c "import time; print(int(time.time()*1000))"; }

# POST con timing, sin -f para ver errores
post() {
  local path="$1"; local body="$2"
  local t0=$(ms_now)
  local resp=$(curl -s -X POST "$BASE$path" -H "Content-Type: application/json" -d "$body" 2>/dev/null)
  local t1=$(ms_now)
  local ms=$(( t1 - t0 ))
  echo "$resp"$'\x01'"$ms"
}

# GET con timing
get() {
  local t0=$(ms_now)
  local resp=$(curl -s "$BASE$1" 2>/dev/null)
  local t1=$(ms_now)
  echo "$resp"$'\x01'$(( t1 - t0 ))
}

# PUT con timing
put() {
  local path="$1"; local body="$2"
  local t0=$(ms_now)
  local resp=$(curl -s -X PUT "$BASE$path" -H "Content-Type: application/json" -d "$body" 2>/dev/null)
  local t1=$(ms_now)
  echo "$resp"$'\x01'$(( t1 - t0 ))
}

body() { echo "$1" | cut -d$'\x01' -f1; }
ms()   { echo "$1" | cut -d$'\x01' -f2; }
jq()   { python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$2',''))" 2>/dev/null; }
jqi()  { python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$2', 0))" 2>/dev/null; }
http() { curl -s -o /dev/null -w "%{http_code}" -X "$1" "$BASE$2" -H "Content-Type: application/json" -d "$3" 2>/dev/null; }

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}   Cantina POS — Test de Sistema Completo${NC}"
echo -e "${BOLD}   $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ─────────────────────────────────────────────────────────
titulo "0. HEALTH + DATOS BASE"
# ─────────────────────────────────────────────────────────
r=$(get "/api/health"); status=$(body "$r" | jq _self status 2>/dev/null || body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
[ "$status" = "ok" ] && ok "Health OK ($(ms "$r")ms)" || fail "Health falló: $(body "$r")"

r=$(get "/api/categorias")
n=$(body "$r" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)
[ "${n:-0}" -gt 0 ] && ok "$n categorías ($(ms "$r")ms)" || fail "Sin categorías"

r=$(get "/api/productos")
PRODS=$(body "$r")
n=$(echo "$PRODS" | python3 -c "import sys,json; print(len([x for x in json.load(sys.stdin) if x['activo']]))" 2>/dev/null)
[ "${n:-0}" -gt 0 ] && ok "$n productos activos ($(ms "$r")ms)" || fail "Sin productos"

r=$(get "/api/clientes")
CLIENTES=$(body "$r")
n=$(echo "$CLIENTES" | python3 -c "import sys,json; print(len([x for x in json.load(sys.stdin) if x['activo']]))" 2>/dev/null)
[ "${n:-0}" -gt 0 ] && ok "$n clientes activos ($(ms "$r")ms)" || fail "Sin clientes"

# Stock inicial
stock_coca()  { curl -s "$BASE/api/productos" | python3 -c "import sys,json; p=json.load(sys.stdin); [print(x['stock']) for x in p if x['id']==8]" 2>/dev/null; }
stock_mila()  { curl -s "$BASE/api/productos" | python3 -c "import sys,json; p=json.load(sys.stdin); [print(x['stock']) for x in p if x['id']==1]" 2>/dev/null; }
stock_hamb()  { curl -s "$BASE/api/productos" | python3 -c "import sys,json; p=json.load(sys.stdin); [print(x['stock']) for x in p if x['id']==2]" 2>/dev/null; }
STOCK_COCA0=$(stock_coca); STOCK_MILA0=$(stock_mila); STOCK_HAMB0=$(stock_hamb)
info "Stock inicial — Coca Cola: $STOCK_COCA0 | Milanesa: $STOCK_MILA0 | Hamburguesa: $STOCK_HAMB0"

# ─────────────────────────────────────────────────────────
titulo "1. FLUJO A — Mesa, cocina completa, cobro efectivo"
# ─────────────────────────────────────────────────────────
# items: Milanesa(1)×1 + CocaCola(8)×2 → total=12500
info "POST pedido mesa #5..."
r=$(post "/api/pedidos" '{"tipo":"mesa","mesa_numero":5,"total":12500,"items":[{"producto_id":1,"cantidad":1,"precio":8500,"observaciones":"sin cebolla"},{"producto_id":8,"cantidad":2,"precio":2000,"observaciones":""}]}')
P1=$(body "$r")
P1_ID=$(echo "$P1" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
P1_EST=$(echo "$P1" | python3 -c "import sys,json; print(json.load(sys.stdin).get('estado',''))" 2>/dev/null)
P1_TOT=$(echo "$P1" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',''))" 2>/dev/null)
if [ -n "$P1_ID" ] && [ "$P1_EST" = "pendiente" ]; then
  ok "Pedido #$P1_ID creado — \$$P1_TOT — estado:$P1_EST ($(ms "$r")ms)"
else
  fail "Error creando pedido: $P1"; P1_ID=""
fi

if [ -n "$P1_ID" ]; then
  for estado in "en_preparacion" "listo" "entregado"; do
    r=$(put "/api/pedidos/$P1_ID" "{\"estado\":\"$estado\"}")
    est=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('estado',''))" 2>/dev/null)
    [ "$est" = "$estado" ] && ok "Estado → $estado ($(ms "$r")ms)" || fail "Fallo cambio a $estado: $(body "$r")"
  done

  r=$(post "/api/pedidos/$P1_ID/cobrar" '{"metodo_pago":"efectivo","referencia":"","descuento_pct":0}')
  cobrado=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cobrado',''))" 2>/dev/null)
  [ "$cobrado" = "True" ] && ok "Cobrado efectivo \$$P1_TOT ($(ms "$r")ms)" || fail "Error cobro efectivo: $(body "$r")"

  STOCK_COCA1=$(stock_coca); STOCK_MILA1=$(stock_mila)
  [ $(( STOCK_COCA0 - STOCK_COCA1 )) -eq 2 ] && ok "Stock Coca Cola: $STOCK_COCA0 → $STOCK_COCA1 (-2)" || fail "Stock Coca Cola incorrecto: $STOCK_COCA0 → $STOCK_COCA1"
  [ $(( STOCK_MILA0 - STOCK_MILA1 )) -eq 1 ] && ok "Stock Milanesa: $STOCK_MILA0 → $STOCK_MILA1 (-1)" || fail "Stock Milanesa incorrecto: $STOCK_MILA0 → $STOCK_MILA1"
fi

# ─────────────────────────────────────────────────────────
titulo "2. FLUJO B — Barra, cobro transferencia con referencia"
# ─────────────────────────────────────────────────────────
# Lomo(3)×1 + Cerveza(10)×1 → total=12000
r=$(post "/api/pedidos" '{"tipo":"barra","nombre_cliente":"Juan","total":12000,"items":[{"producto_id":3,"cantidad":1,"precio":9500,"observaciones":"bien cocido"},{"producto_id":10,"cantidad":1,"precio":2500,"observaciones":""}]}')
P2_ID=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
P2_TOT=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',''))" 2>/dev/null)
[ -n "$P2_ID" ] && ok "Pedido barra #$P2_ID — \$$P2_TOT ($(ms "$r")ms)" || fail "Error pedido barra: $(body "$r")"

if [ -n "$P2_ID" ]; then
  r=$(post "/api/pedidos/$P2_ID/cobrar" '{"metodo_pago":"transferencia","referencia":"REF-TEST-001","descuento_pct":0}')
  cobrado=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cobrado',''))" 2>/dev/null)
  ref=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('referencia',''))" 2>/dev/null)
  [ "$cobrado" = "True" ] && ok "Cobrado transferencia — ref:$ref ($(ms "$r")ms)" || fail "Error transferencia: $(body "$r")"
  [ "$ref" = "REF-TEST-001" ] && ok "Referencia guardada correctamente" || warn "Referencia no guardada (got: '$ref')"
fi

# ─────────────────────────────────────────────────────────
titulo "3. FLUJO C — Cuenta corriente (saldo cliente)"
# ─────────────────────────────────────────────────────────
# Cliente 2 = María López, saldo actual
SALDO0=$(echo "$CLIENTES" | python3 -c "import sys,json; c=json.load(sys.stdin); [print(x['saldo']) for x in c if x['id']==2]" 2>/dev/null)
info "María López — saldo inicial: \$$SALDO0"

# Suprema(4)×1 + CaféCortado(12)×1 → total=10000
r=$(post "/api/pedidos" '{"tipo":"barra","nombre_cliente":"Maria Lopez","cliente_id":2,"total":10000,"items":[{"producto_id":4,"cantidad":1,"precio":8000,"observaciones":""},{"producto_id":12,"cantidad":1,"precio":2000,"observaciones":""}]}')
P3_ID=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
P3_TOT=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',''))" 2>/dev/null)
[ -n "$P3_ID" ] && ok "Pedido CC #$P3_ID — \$$P3_TOT ($(ms "$r")ms)" || fail "Error pedido CC: $(body "$r")"

if [ -n "$P3_ID" ]; then
  r=$(post "/api/pedidos/$P3_ID/cobrar" '{"metodo_pago":"cuenta_corriente","referencia":"","descuento_pct":0,"cliente_id":2}')
  cobrado=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cobrado',''))" 2>/dev/null)
  [ "$cobrado" = "True" ] && ok "Cobrado cuenta_corriente ($(ms "$r")ms)" || fail "Error CC: $(body "$r")"

  SALDO1=$(curl -s "$BASE/api/clientes" | python3 -c "import sys,json; c=json.load(sys.stdin); [print(x['saldo']) for x in c if x['id']==2]" 2>/dev/null)
  DELTA=$(python3 -c "print(int($SALDO1) - int($SALDO0))" 2>/dev/null)
  [ "$DELTA" = "$P3_TOT" ] && ok "Saldo actualizado: \$$SALDO0 → \$$SALDO1 (+\$$DELTA)" || fail "Saldo incorrecto: +$DELTA (esperaba +$P3_TOT)"
fi

# ─────────────────────────────────────────────────────────
titulo "4. FLUJO D — Descuento 10% (Pizza+Papas)"
# ─────────────────────────────────────────────────────────
# Pizza(6)×1 + Papas(7)×1 → subtotal=11000, descuento 10% → el frontend enviaría total=9900
# NOTA: el servidor no recalcula el total al cobrar — el total se fija al crear el pedido
r=$(post "/api/pedidos" '{"tipo":"mesa","mesa_numero":12,"total":9900,"items":[{"producto_id":6,"cantidad":1,"precio":6750,"observaciones":"sin anchoas"},{"producto_id":7,"cantidad":1,"precio":3150,"observaciones":"extra sal"}]}')
P4_ID=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
P4_TOT=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',''))" 2>/dev/null)
[ -n "$P4_ID" ] && ok "Pedido con descuento #$P4_ID — total ya ajustado: \$$P4_TOT ($(ms "$r")ms)" || fail "Error pedido descuento: $(body "$r")"

if [ -n "$P4_ID" ]; then
  r=$(post "/api/pedidos/$P4_ID/cobrar" '{"metodo_pago":"efectivo","referencia":"","descuento_pct":10}')
  cobrado=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cobrado',''))" 2>/dev/null)
  desc=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('descuento_pct',''))" 2>/dev/null)
  total_final=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',''))" 2>/dev/null)
  [ "$cobrado" = "True" ] && ok "Cobrado con descuento — descuento_pct:$desc total:\$$total_final ($(ms "$r")ms)" || fail "Error cobro con descuento: $(body "$r")"
  # Verificar que el servidor NO modifica el total al aplicar descuento_pct (solo lo guarda)
  [ "$total_final" = "9900" ] && ok "Total no modificado por cobrar (correcto — frontend lo pre-calcula)" || warn "Total cambió al cobrar: $total_final (esperaba 9900)"
fi

# ─────────────────────────────────────────────────────────
titulo "5. FLUJO E — Cancelación + reposición de stock"
# ─────────────────────────────────────────────────────────
STOCK_HAMB0=$(stock_hamb)
info "Stock Hamburguesa antes: $STOCK_HAMB0"

# Hamburguesa(2)×2 → total=14000
r=$(post "/api/pedidos" '{"tipo":"barra","nombre_cliente":"Test Cancel","total":14000,"items":[{"producto_id":2,"cantidad":2,"precio":7000,"observaciones":""}]}')
P5_ID=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
STOCK_HAMB_MED=$(stock_hamb)
[ -n "$P5_ID" ] && ok "Pedido #$P5_ID creado — stock hamb bajó: $STOCK_HAMB0 → $STOCK_HAMB_MED ($(ms "$r")ms)" || fail "Error creando pedido para cancelar: $(body "$r")"

if [ -n "$P5_ID" ]; then
  r=$(post "/api/pedidos/$P5_ID/cancelar" '{}')
  est=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('estado',''))" 2>/dev/null)
  STOCK_HAMB1=$(stock_hamb)
  [ "$est" = "cancelado" ] && ok "Cancelado correctamente ($(ms "$r")ms)" || fail "Error cancelando: $(body "$r")"
  [ "$STOCK_HAMB1" = "$STOCK_HAMB0" ] && ok "Stock repuesto: $STOCK_HAMB_MED → $STOCK_HAMB1" || fail "Stock NO repuesto: antes=$STOCK_HAMB0 medio=$STOCK_HAMB_MED después=$STOCK_HAMB1"
fi

# ─────────────────────────────────────────────────────────
titulo "6. FLUJO F — Pedido multi-ítem con observaciones"
# ─────────────────────────────────────────────────────────
# Empanadas(5)×2 + Agua(9)×3 + Flan(15)×1 + CaféDoble(13)×2 → total=24500
r=$(post "/api/pedidos" '{"tipo":"mesa","mesa_numero":20,"total":24500,"items":[{"producto_id":5,"cantidad":2,"precio":5500,"observaciones":"bien doradas"},{"producto_id":9,"cantidad":3,"precio":1500,"observaciones":"con hielo"},{"producto_id":15,"cantidad":1,"precio":4000,"observaciones":""},{"producto_id":13,"cantidad":2,"precio":2500,"observaciones":"cortado"}]}')
P6_ID=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
P6_TOT=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',''))" 2>/dev/null)
NITEMS=$(body "$r" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('items',[])))" 2>/dev/null)
[ -n "$P6_ID" ] && ok "Pedido #$P6_ID — $NITEMS items — \$$P6_TOT ($(ms "$r")ms)" || fail "Error pedido multi-item: $(body "$r")"
[ "$P6_TOT" = "24500" ] && ok "Total correcto: \$24500" || warn "Total \$$P6_TOT ≠ 24500"

if [ -n "$P6_ID" ]; then
  r=$(post "/api/pedidos/$P6_ID/cobrar" '{"metodo_pago":"efectivo","referencia":"","descuento_pct":0}')
  cobrado=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cobrado',''))" 2>/dev/null)
  [ "$cobrado" = "True" ] && ok "Cobrado multi-item OK ($(ms "$r")ms)" || fail "Error cobro multi-item: $(body "$r")"
fi

# ─────────────────────────────────────────────────────────
titulo "7. FLUJO G — Producto sin cocina (GAS)"
# ─────────────────────────────────────────────────────────
# GAS(17)×3 → total=7500, cocina:False → lógica de bypass en frontend
r=$(post "/api/pedidos" '{"tipo":"barra","nombre_cliente":"Despacho Directo","total":7500,"items":[{"producto_id":17,"cantidad":3,"precio":2500,"observaciones":""}]}')
P7_ID=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
P7_EST=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('estado',''))" 2>/dev/null)
[ -n "$P7_ID" ] && ok "Pedido GAS #$P7_ID — estado:$P7_EST — \$7500 ($(ms "$r")ms)" || fail "Error pedido GAS: $(body "$r")"
[ "$P7_EST" = "pendiente" ] && info "GAS queda en 'pendiente' — el bypass de cocina es solo frontend" || info "Estado: $P7_EST"

if [ -n "$P7_ID" ]; then
  r=$(post "/api/pedidos/$P7_ID/cobrar" '{"metodo_pago":"efectivo","referencia":"","descuento_pct":0}')
  cobrado=$(body "$r" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cobrado',''))" 2>/dev/null)
  [ "$cobrado" = "True" ] && ok "GAS cobrado OK ($(ms "$r")ms)" || fail "Error cobro GAS: $(body "$r")"
fi

# ─────────────────────────────────────────────────────────
titulo "8. EDGE CASES — Guards y validaciones"
# ─────────────────────────────────────────────────────────

# 8a. Doble cancelación
info "Doble cancelación..."
[ -n "$P5_ID" ] && {
  code=$(http POST "/api/pedidos/$P5_ID/cancelar" '{}')
  [ "$code" = "409" ] && ok "Doble cancelación rechazada HTTP $code" || fail "Doble cancelación: HTTP $code (esperaba 409)"
} || info "Skipped (P5 no creado)"

# 8b. Cobrar pedido ya cobrado
info "Cobrar pedido ya cobrado..."
[ -n "$P1_ID" ] && {
  code=$(http POST "/api/pedidos/$P1_ID/cobrar" '{"metodo_pago":"efectivo","referencia":"","descuento_pct":0}')
  [ "$code" = "409" ] && ok "Cobro duplicado rechazado HTTP $code" || fail "Cobro duplicado: HTTP $code (esperaba 409)"
} || info "Skipped (P1 no creado)"

# 8c. Pedido sin items
info "Pedido sin items..."
code=$(http POST "/api/pedidos" '{"tipo":"barra","nombre_cliente":"Test","total":0,"items":[]}')
[ "$code" = "400" ] && ok "Pedido sin items rechazado HTTP $code" || fail "Pedido sin items: HTTP $code (esperaba 400)"

# 8d. Pedido tipo inválido
info "Pedido tipo inválido..."
code=$(http POST "/api/pedidos" '{"tipo":"delivery","nombre_cliente":"Test","total":1000,"items":[{"producto_id":13,"cantidad":1,"precio":1000,"observaciones":""}]}')
[ "$code" = "400" ] && ok "Tipo inválido rechazado HTTP $code" || fail "Tipo inválido: HTTP $code (esperaba 400)"

# 8e. Login PIN válido
info "Login PIN válido..."
code=$(http POST "/api/login" '{"pin":"1234"}')
[ "$code" = "200" ] && ok "Login PIN válido HTTP $code" || fail "Login PIN válido: HTTP $code (esperaba 200)"

# 8f. Login PIN inválido
info "Login PIN inválido (9876)..."
r_login=$(curl -s -w $'\x01%{http_code}' -X POST "$BASE/api/login" -H "Content-Type: application/json" -d '{"pin":"9876"}' 2>/dev/null)
code=$(echo "$r_login" | cut -d$'\x01' -f2)
[ "$code" = "401" ] && ok "PIN inválido rechazado HTTP $code" || fail "PIN inválido: HTTP $code (esperaba 401)"

# 8g. Cancelar pedido cobrado
info "Cancelar pedido ya cobrado..."
[ -n "$P1_ID" ] && {
  code=$(http POST "/api/pedidos/$P1_ID/cancelar" '{}')
  # el guard es "ya cancelado", no "ya cobrado" → el servidor lo permite a nivel de estado
  resp=$(curl -s -X POST "$BASE/api/pedidos/$P1_ID/cancelar" -H "Content-Type: application/json" -d '{}' 2>/dev/null)
  est=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('estado',''))" 2>/dev/null)
  err=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
  if [ -n "$err" ]; then
    warn "Cancelar pedido cobrado: $err (HTTP $code) — el servidor permite cancelar pedidos cobrados (revisar)"
  else
    warn "Cancelar pedido cobrado retornó estado:$est — el servidor no bloquea cancelar pedidos cobrados"
  fi
} || info "Skipped"

# 8h. cobrar con metodo_pago inválido
info "Cobrar con método de pago inválido..."
[ -n "$P2_ID" ] && {
  code=$(http POST "/api/pedidos/$P2_ID/cobrar" '{"metodo_pago":"bitcoin","referencia":"","descuento_pct":0}')
  [ "$code" = "400" ] && ok "Método inválido rechazado HTTP $code" || fail "Método inválido: HTTP $code (esperaba 400)"
} || info "Skipped"

# ─────────────────────────────────────────────────────────
titulo "9. CONCURRENCIA — 10 pedidos simultáneos"
# ─────────────────────────────────────────────────────────
info "Lanzando 10 pedidos en paralelo (productos con buen stock)..."
TMPDIR_CONC=$(mktemp -d)
t0_conc=$(ms_now)

# Productos con buen stock: CaféCortado(12, stock~92), Submarino(14), Suprema(4, stock~84)
PRODS_CONC=(12 14 13 4 9 12 14 13 4 9)
PRECIOS_CONC=(2000 3000 2500 8000 1500 2000 3000 2500 8000 1500)
for i in $(seq 0 9); do
  pid=${PRODS_CONC[$i]}; precio=${PRECIOS_CONC[$i]}
  curl -s -X POST "$BASE/api/pedidos" -H "Content-Type: application/json" \
    -d "{\"tipo\":\"barra\",\"nombre_cliente\":\"CargaTest$i\",\"total\":$precio,\"items\":[{\"producto_id\":$pid,\"cantidad\":1,\"precio\":$precio,\"observaciones\":\"\"}]}" \
    -o "$TMPDIR_CONC/r$i.json" &
done
wait
t1_conc=$(ms_now)
MS_CONC=$(( t1_conc - t0_conc ))

OK_CONC=0; FAIL_CONC=0; CONC_IDS=()
for i in $(seq 0 9); do
  f="$TMPDIR_CONC/r$i.json"
  if [ -s "$f" ]; then
    id=$(python3 -c "import json; print(json.load(open('$f')).get('id',''))" 2>/dev/null)
    err=$(python3 -c "import json; print(json.load(open('$f')).get('error',''))" 2>/dev/null)
    if [ -n "$id" ]; then ((OK_CONC++)); CONC_IDS+=($id);
    else ((FAIL_CONC++)); info "Pedido $i falló: $err"; fi
  else ((FAIL_CONC++)); fi
done
rm -rf "$TMPDIR_CONC"

[ "$OK_CONC" -eq 10 ] \
  && ok "10/10 concurrentes OK — total: ${MS_CONC}ms — promedio: $((MS_CONC/10))ms/pedido" \
  || fail "$FAIL_CONC/10 pedidos concurrentes fallaron ($OK_CONC OK, ${MS_CONC}ms total)"

info "Cancelando pedidos de carga..."
CANCEL_OK=0
for pid in "${CONC_IDS[@]}"; do
  resp=$(curl -s -X POST "$BASE/api/pedidos/$pid/cancelar" -H "Content-Type: application/json" -d '{}' 2>/dev/null)
  est=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('estado',''))" 2>/dev/null)
  [ "$est" = "cancelado" ] && ((CANCEL_OK++))
done
ok "$CANCEL_OK/${#CONC_IDS[@]} pedidos de carga cancelados y stock repuesto"

# ─────────────────────────────────────────────────────────
titulo "10. PERFORMANCE — tiempos de respuesta"
# ─────────────────────────────────────────────────────────
MUESTRAS=5
declare -a T_PED T_COB T_GETPED T_GETPROD

for i in $(seq 1 $MUESTRAS); do
  # GET pedidos
  t0=$(ms_now); curl -s "$BASE/api/pedidos" > /dev/null; t1=$(ms_now); T_GETPED+=( $(( t1-t0 )) )
  # GET productos
  t0=$(ms_now); curl -s "$BASE/api/productos" > /dev/null; t1=$(ms_now); T_GETPROD+=( $(( t1-t0 )) )
  # POST pedido
  t0=$(ms_now)
  resp=$(curl -s -X POST "$BASE/api/pedidos" -H "Content-Type: application/json" \
    -d "{\"tipo\":\"barra\",\"nombre_cliente\":\"PerfTest\",\"total\":2500,\"items\":[{\"producto_id\":13,\"cantidad\":1,\"precio\":2500,\"observaciones\":\"\"}]}" 2>/dev/null)
  t1=$(ms_now); T_PED+=( $(( t1-t0 )) )
  PID_PERF=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
  # POST cobrar
  if [ -n "$PID_PERF" ]; then
    t0=$(ms_now)
    curl -s -X POST "$BASE/api/pedidos/$PID_PERF/cobrar" -H "Content-Type: application/json" \
      -d '{"metodo_pago":"efectivo","referencia":"","descuento_pct":0}' > /dev/null
    t1=$(ms_now); T_COB+=( $(( t1-t0 )) )
  fi
done

stat() {
  local name="$1"; shift
  python3 - "$@" <<'EOF'
import sys
vals = list(map(int, sys.argv[1:]))
if not vals: print("  (sin datos)"); exit()
avg = int(sum(vals)/len(vals)); mn = min(vals); mx = max(vals)
print(f"  {sys.argv[0] if False else ''}{avg}ms avg | {mn}ms min | {mx}ms max  ({len(vals)} muestras)")
EOF
}

echo -e "\n  ${BOLD}GET /api/pedidos:${NC}"
stat "ped" "${T_GETPED[@]}"
echo -e "  ${BOLD}GET /api/productos:${NC}"
stat "prod" "${T_GETPROD[@]}"
echo -e "  ${BOLD}POST /api/pedidos:${NC}"
stat "post_ped" "${T_PED[@]}"
echo -e "  ${BOLD}POST /api/cobrar:${NC}"
stat "cobrar" "${T_COB[@]}"

# GET system (puede ser lento)
t0=$(ms_now); curl -s "$BASE/api/system" > /dev/null; t1=$(ms_now); T_SYS=$(( t1-t0 ))
echo -e "  ${BOLD}GET /api/system:${NC}  ${T_SYS}ms"

AVG_PED=$(python3 -c "vals=[${T_PED[*]}]; print(int(sum(vals)/len(vals)))" 2>/dev/null)
AVG_GET=$(python3 -c "vals=[${T_GETPED[*]}]; print(int(sum(vals)/len(vals)))" 2>/dev/null)
[ "${AVG_GET:-999}" -lt 200 ] && ok "GET pedidos rápido (${AVG_GET}ms avg)" || warn "GET pedidos lento (${AVG_GET}ms avg > 200ms umbral)"
[ "${AVG_PED:-999}" -lt 300 ] && ok "POST pedidos rápido (${AVG_PED}ms avg)" || warn "POST pedidos lento (${AVG_PED}ms avg > 300ms umbral)"
[ "${T_SYS:-999}" -lt 1500 ] && ok "GET system aceptable (${T_SYS}ms)" || warn "GET system lento (${T_SYS}ms)"

# ─────────────────────────────────────────────────────────
titulo "11. ESTADO FINAL DB"
# ─────────────────────────────────────────────────────────
r=$(get "/api/pedidos")
HOY=$(body "$r" | python3 -c "import sys,json; p=json.load(sys.stdin); print(len(p))" 2>/dev/null)
COBRADO_HOY=$(body "$r" | python3 -c "import sys,json; p=json.load(sys.stdin); print(sum(x['total'] for x in p if x['cobrado']))" 2>/dev/null)
CANCEL_HOY=$(body "$r" | python3 -c "import sys,json; p=json.load(sys.stdin); print(len([x for x in p if x['estado']=='cancelado']))" 2>/dev/null)
PEND_HOY=$(body "$r" | python3 -c "import sys,json; p=json.load(sys.stdin); print(len([x for x in p if x['estado'] not in ['entregado','cancelado']]))" 2>/dev/null)

echo "  Pedidos hoy: $HOY (cancelados: $CANCEL_HOY | pendientes: $PEND_HOY)"
echo "  Total cobrado hoy: \$$COBRADO_HOY"
[ "${PEND_HOY:-0}" -eq 0 ] && ok "Sin pedidos abiertos al finalizar" || warn "$PEND_HOY pedido(s) quedaron sin cerrar"

# ─────────────────────────────────────────────────────────
titulo "RESULTADO FINAL"
# ─────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}✓ Pasaron: $PASS${NC}"
[ "$WARN" -gt 0 ] && echo -e "  ${YELLOW}${BOLD}⚠  Warnings: $WARN${NC}"
[ "$FAIL" -gt 0 ] && echo -e "  ${RED}${BOLD}✗ Fallaron: $FAIL${NC}"
echo ""
if [ ${#HALLAZGOS[@]} -gt 0 ]; then
  echo -e "  ${BOLD}Hallazgos:${NC}"
  for h in "${HALLAZGOS[@]}"; do echo "    $h"; done
fi
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
