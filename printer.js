// printer.js — Impresora térmica Epson TM-T88 / M244A vía /dev/usb/lp*
// ESC/POS raw (sin dependencias nativas). Encoding CP858 vía iconv-lite.
// 70mm = 40 caracteres por línea @ font A (con márgenes seguros).

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFile } = require('child_process');
const iconv = require('iconv-lite');

const CANDIDATES = ['/dev/usb/lp0', '/dev/usb/lp1', '/dev/usb/lp2', '/dev/lp0', '/dev/lp1'];
const WIDTH = 42;
const CODEPAGE = 'cp858';
const NAME_MAX = 24;   // caracteres máximos del nombre de un item antes de truncar

const ESC = 0x1B, GS = 0x1D;
const C = {
  init:          Buffer.from([ESC, 0x40]),
  cp858:         Buffer.from([ESC, 0x74, 19]),   // charset PC858 Multilingual + Euro
  align_l:       Buffer.from([ESC, 0x61, 0]),
  align_c:       Buffer.from([ESC, 0x61, 1]),
  align_r:       Buffer.from([ESC, 0x61, 2]),
  bold_on:       Buffer.from([ESC, 0x45, 1]),
  bold_off:      Buffer.from([ESC, 0x45, 0]),
  underline_on:  Buffer.from([ESC, 0x2D, 1]),
  underline_off: Buffer.from([ESC, 0x2D, 0]),
  size_normal:   Buffer.from([GS, 0x21, 0x00]),
  size_dbl_h:    Buffer.from([GS, 0x21, 0x01]),
  size_dbl_w:    Buffer.from([GS, 0x21, 0x10]),
  size_dbl_wh:   Buffer.from([GS, 0x21, 0x11]),
  feed:          (n) => Buffer.from([ESC, 0x64, n]),
  // Corte parcial con feed de 120 dots (~15mm) — asegura que el papel pase la cuchilla
  cut:           Buffer.from([GS, 0x56, 66, 120]),

  // Oscurecimiento (universal ESC/POS)
  double_strike_on:  Buffer.from([ESC, 0x47, 1]),  // cada punto disparado dos veces → texto más oscuro
  double_strike_off: Buffer.from([ESC, 0x47, 0]),
  // Comando específico Epson TM: GS ( E fn=5 (densidad de impresión), valor máximo
  epson_density_max: Buffer.from([GS, 0x28, 0x45, 0x02, 0x00, 0x05, 0x08]),
};

function findPrinterDevice() {
  for (const p of CANDIDATES) {
    try { if (fs.existsSync(p)) return p; } catch (e) {}
  }
  return null;
}

function isConnected() {
  const dev = findPrinterDevice();
  if (!dev) return false;
  try { fs.accessSync(dev, fs.constants.W_OK); return true; }
  catch (e) { return false; }
}

const txt = (s) => iconv.encode(String(s == null ? '' : s), CODEPAGE);
const rule = (ch = '-') => txt(ch.repeat(WIDTH) + '\n');

function pad(s, n) {
  s = String(s);
  return s.length >= n ? s.slice(0, n) : s + ' '.repeat(n - s.length);
}
function padLeft(s, n) {
  s = String(s);
  return s.length >= n ? s.slice(-n) : ' '.repeat(n - s.length) + s;
}
function trunc(s, n) {
  s = String(s || '');
  return s.length > n ? s.slice(0, n - 1) + '…' : s;
}
function money(n) {
  return '$' + Number(n || 0).toLocaleString('es-AR');
}

function writeToPrinter(buf) {
  const dev = findPrinterDevice();
  if (!dev) return Promise.reject(new Error('Impresora no detectada (revisar USB / udev)'));
  // Usamos un proceso hijo (cat tmp > dev) para el write blocking al char device:
  // fs.write con O_NONBLOCK produce escrituras parciales en usblp; blocking está
  // bien en un proceso separado y el timeout lo mata si la impresora no responde.
  const tmp = path.join(os.tmpdir(), `.escpos_${process.pid}_${Date.now()}.bin`);
  return new Promise((resolve, reject) => {
    fs.writeFile(tmp, buf, (wErr) => {
      if (wErr) return reject(wErr);
      execFile('sh', ['-c', `cat -- '${tmp}' > '${dev}'`], { timeout: 10000 }, (err) => {
        fs.unlink(tmp, () => {});
        if (err) {
          const msg = err.killed
            ? 'Timeout: impresora sin respuesta (apagada, sin papel o en error)'
            : err.message;
          reject(new Error(msg));
        } else {
          resolve(dev);
        }
      });
    });
  });
}

function buildTicketBuffer(pedido) {
  const fecha = new Date(pedido.createdAt || Date.now());
  // Siempre mostrar en horario de Argentina (UTC-3, sin DST)
  const fp = new Intl.DateTimeFormat('es-AR', {
    timeZone: 'America/Argentina/Tucuman',
    day: '2-digit', month: '2-digit', year: '2-digit',
    hour: '2-digit', minute: '2-digit', hour12: false,
  }).formatToParts(fecha).reduce((a, p) => { a[p.type] = p.value; return a; }, {});
  const fechaHora = `${fp.day}/${fp.month}/${fp.year} ${fp.hour}:${fp.minute}`;

  const tipo      = pedido.tipo === 'mesa' ? `Mesa ${pedido.mesa_numero}` : 'Barra';
  const _nums     = pedido._numeros;
  const numero    = _nums ? _nums.map(n => String(n).padStart(3,'0')).join('+') : String(pedido.numero || 0).padStart(3, '0');
  const pedidoKey = _nums && _nums.length > 1 ? 'PEDIDOS' : 'PEDIDO';
  const ticketId  = String(pedido.id || 0).padStart(4, '0');
  const mozoRaw   = pedido._mozo_nombre || '';

  const parts = [];
  parts.push(C.init, C.cp858, C.epson_density_max, C.double_strike_on);

  // ── ENCABEZADO ──────────────────────────────────────────
  parts.push(C.align_c, C.size_dbl_wh, C.bold_on);
  parts.push(txt('CANTINA NyG\n'));
  parts.push(C.size_normal, C.bold_off);
  parts.push(txt('Club Natacion y Gimnasia\n'));
  parts.push(txt('Primero el club, siempre el club\n'));
  parts.push(rule('='));

  // ── DATOS DE LA VENTA ───────────────────────────────────
  parts.push(C.align_l);
  // Fila 1: fecha/hora izq — ticket# der
  const ticketLabel = `Ticket #${ticketId}`;
  parts.push(txt(pad(fechaHora, WIDTH - ticketLabel.length) + ticketLabel + '\n'));
  // Mozo (si aplica)
  if (mozoRaw) parts.push(txt(`Mozo: ${trunc(mozoRaw, WIDTH - 6)}\n`));
  // Fila 2: mesa grande izq — pedido# bold der (doble alto)
  const pedidoLabel = `${pedidoKey} #${numero}`;
  parts.push(rule('.'));
  parts.push(C.size_dbl_h, C.bold_on);
  parts.push(txt(pad(tipo, WIDTH - pedidoLabel.length) + pedidoLabel + '\n'));
  parts.push(C.size_normal, C.bold_off);
  parts.push(rule('-'));

  // ── ITEMS ────────────────────────────────────────────────
  parts.push(txt(pad('CANT DESCRIPCION', WIDTH - 9) + padLeft('TOTAL', 9) + '\n'));
  parts.push(rule('-'));

  for (const it of (pedido.items || [])) {
    const nombreRaw = it.nombre || (it.producto && it.producto.nombre) || '?';
    const nombre  = trunc(nombreRaw, NAME_MAX);
    const cant    = it.cantidad || 1;
    const precio  = it.precio || 0;
    const subtotal = cant * precio;
    const label   = `${cant}x ${nombre}`;
    parts.push(txt(pad(label, WIDTH - 9) + padLeft(money(subtotal), 9) + '\n'));
    if (cant > 1) {
      parts.push(txt('      ' + money(precio) + ' c/u\n'));
    }
    if (it.observaciones) {
      const obs = String(it.observaciones);
      const maxLen = WIDTH - 6;
      for (let i = 0; i < obs.length; i += maxLen) {
        parts.push(txt('   >> ' + obs.slice(i, i + maxLen) + '\n'));
      }
    }
  }
  parts.push(rule('-'));

  // ── TOTALES ──────────────────────────────────────────────
  if (pedido.descuento_pct) {
    const totalAntes = Math.round(pedido.total / (1 - pedido.descuento_pct / 100));
    const descMonto  = totalAntes - pedido.total;
    parts.push(txt(pad('Subtotal', WIDTH - 9) + padLeft(money(totalAntes), 9) + '\n'));
    parts.push(txt(pad(`Desc. ${pedido.descuento_pct}%`, WIDTH - 9) + padLeft('-' + money(descMonto), 9) + '\n'));
  }
  parts.push(rule('.'));
  parts.push(C.size_dbl_h, C.bold_on);
  parts.push(txt(pad('TOTAL', WIDTH - 9) + padLeft(money(pedido.total), 9) + '\n'));
  parts.push(C.size_normal, C.bold_off);

  if (pedido.metodo_pago) {
    const met = { efectivo: 'Efectivo', transferencia: 'Transferencia', cuenta_corriente: 'Cuenta corriente' }[pedido.metodo_pago] || pedido.metodo_pago;
    parts.push(txt(`Pago: ${met}\n`));
    if (pedido.cliente) {
      const cNombre = `${pedido.cliente.nombre || ''} ${pedido.cliente.apellido || ''}`.trim();
      if (cNombre) parts.push(txt(`A nombre de: ${trunc(cNombre, WIDTH - 13)}\n`));
    }
  }

  // ── PIE ──────────────────────────────────────────────────
  parts.push(rule('='));
  parts.push(C.align_c);
  parts.push(txt('¡Gracias por su visita!\n'));
  parts.push(txt('@cantinanyg\n'));
  parts.push(C.align_l);
  parts.push(C.double_strike_off);
  parts.push(C.feed(1));      // avance mínimo — el corte ya incluye 120 dots de feed
  parts.push(C.cut);

  return Buffer.concat(parts);
}

function buildTestBuffer() {
  const parts = [];
  parts.push(C.init, C.cp858, C.epson_density_max, C.double_strike_on);
  parts.push(C.align_c, C.size_dbl_wh, C.bold_on);
  parts.push(txt('CANTINA NyG\n'));
  parts.push(C.size_normal, C.bold_off);
  parts.push(txt('Prueba de impresion\n'));
  parts.push(rule('='));
  parts.push(C.align_l);
  parts.push(txt(`Fecha: ${new Date().toLocaleString('es-AR', { timeZone: 'America/Argentina/Tucuman' })}\n`));
  parts.push(txt(`Host:  ${os.hostname()}\n`));
  parts.push(txt(`Nodo:  ${process.version}\n`));
  parts.push(rule('-'));
  parts.push(txt('Acentos: áéíóú ÁÉÍÓÚ ñ Ñ ü Ü\n'));
  parts.push(txt('Símbolos: ¿ ¡ $ 1.234,56 €\n'));
  parts.push(rule('-'));
  parts.push(C.bold_on, txt('Negrita OK\n'), C.bold_off);
  parts.push(C.underline_on, txt('Subrayado OK\n'), C.underline_off);
  parts.push(C.size_dbl_h, txt('Doble alto\n'), C.size_normal);
  parts.push(C.size_dbl_wh, txt('Doble WxH\n'), C.size_normal);
  parts.push(rule('='));
  parts.push(C.align_c);
  parts.push(txt('Impresora funcionando correctamente\n'));
  parts.push(C.align_l);
  parts.push(C.double_strike_off);
  parts.push(C.feed(1));      // avance mínimo — el corte ya incluye 120 dots de feed
  parts.push(C.cut);
  return Buffer.concat(parts);
}

async function printTicket(pedido) {
  try {
    if (!pedido) { console.error('[printer] printTicket recibió pedido null'); return false; }
    if (!isConnected()) {
      const dev = findPrinterDevice();
      console.error('[printer] no imprimible:', dev ? `sin permiso en ${dev}` : 'device no detectado');
      return false;
    }
    const buf = buildTicketBuffer(pedido);
    const dev = await writeToPrinter(buf);
    console.log(`[printer] ticket #${pedido.numero} impreso en ${dev}`);
    return true;
  } catch (e) {
    console.error('[printer] error imprimiendo ticket:', e.message);
    return false;
  }
}

async function printTest() {
  try {
    if (!isConnected()) {
      const dev = findPrinterDevice();
      const error = dev ? `sin permiso en ${dev}` : 'device no detectado (revisar USB)';
      console.error('[printer] test cancelado:', error);
      return { success: false, error };
    }
    const buf = buildTestBuffer();
    const dev = await writeToPrinter(buf);
    console.log(`[printer] test impreso en ${dev}`);
    return { success: true, device: dev };
  } catch (e) {
    console.error('[printer] error test:', e.message);
    return { success: false, error: e.message };
  }
}

function status() {
  const dev = findPrinterDevice();
  return {
    connected: isConnected(),
    device: dev,
    codepage: CODEPAGE,
    width: WIDTH,
  };
}

module.exports = { printTicket, printTest, status, findPrinterDevice, isConnected };
