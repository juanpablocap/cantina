const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const { PrismaClient } = require('@prisma/client');
const path = require('path');
const { execSync, exec } = require('child_process');
const fs = require('fs');
const os = require('os');

const prisma = new PrismaClient();
const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

// Medianoche en Argentina (UTC-3, sin DST) como objeto Date en UTC
function midnightAR() {
  const dateStr = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Argentina/Tucuman' });
  return new Date(dateStr + 'T00:00:00-03:00');
}

// Circular buffer for system metrics history (last 120 samples @ 5s = 10 min)
const METRICS_HISTORY_MAX = 120;
const metricsHistory = [];
let lastNetSample = null; // { ts, rx, tx } for rate calculation

app.use(cors());
app.use(express.json({ limit: '15mb' }));
app.use('/images', express.static(path.join(__dirname, 'images')));

// ============================================
// PRINTER (módulo separado — ver printer.js)
// ============================================
const printer = require('./printer');

// ============================================
// HEALTH & SYSTEM
// ============================================
app.get('/api/health', (req, res) => res.json({ status: 'ok', timestamp: Date.now() }));

app.get('/api/system', async (req, res) => {
  try {
    // CPU usage
    let cpu = '0';
    try { cpu = execSync("top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}'", { timeout: 3000 }).toString().trim().split('.')[0]; } catch(e) {}

    // RAM
    let ramTotal = '0', ramUsed = '0';
    try {
      ramTotal = execSync("free -m | awk '/Mem:/ {print $2}'", { timeout: 2000 }).toString().trim();
      ramUsed = execSync("free -m | awk '/Mem:/ {print $3}'", { timeout: 2000 }).toString().trim();
    } catch(e) {}

    // Disk
    let diskPct = '0', diskUsed = '0', diskTotal = '0';
    try {
      diskPct = execSync("df / | awk 'NR==2 {print $5}' | tr -d '%'", { timeout: 2000 }).toString().trim();
      diskUsed = execSync("df -h / | awk 'NR==2 {print $3}'", { timeout: 2000 }).toString().trim();
      diskTotal = execSync("df -h / | awk 'NR==2 {print $2}'", { timeout: 2000 }).toString().trim();
    } catch(e) {}

    // Temperature
    let temp = null;
    try {
      if (fs.existsSync('/sys/class/thermal/thermal_zone0/temp')) {
        temp = Math.floor(parseInt(fs.readFileSync('/sys/class/thermal/thermal_zone0/temp', 'utf8')) / 1000);
      }
    } catch(e) {}

    // Uptime
    let uptime = '';
    try { uptime = execSync("uptime -p", { timeout: 2000 }).toString().trim().replace('up ', ''); } catch(e) {}

    // IP
    const ip = Object.values(os.networkInterfaces()).flat().find(i => i.family === 'IPv4' && !i.internal)?.address || '?';

    // WebSocket connections
    const wsConns = io.engine.clientsCount || 0;

    // Services
    let pgOk = false, apiOk = true;
    try { await prisma.$queryRaw`SELECT 1`; pgOk = true; } catch(e) {}

    // Last backup
    let lastBackup = null;
    const backupDir = path.join(__dirname, 'backups');
    if (fs.existsSync(backupDir)) {
      const files = fs.readdirSync(backupDir).filter(f => f.startsWith('cantina_') && f.endsWith('.sql')).sort().reverse();
      if (files.length > 0) {
        const stat = fs.statSync(path.join(backupDir, files[0]));
        lastBackup = { file: files[0], date: stat.mtime, size: (stat.size / 1024).toFixed(0) + ' KB' };
      }
    }

    // Network throughput (KB/s) from /proc/net/dev
    let net = { rx_kbps: 0, tx_kbps: 0, iface: '' };
    try {
      const netRaw = fs.readFileSync('/proc/net/dev', 'utf8');
      const lines = netRaw.split('\n').slice(2).filter(l => l.includes(':') && !l.includes('lo:'));
      if (lines.length > 0) {
        const parts = lines[0].trim().split(/[\s:]+/);
        const iface = parts[0];
        const rx = parseInt(parts[1]) || 0;
        const tx = parseInt(parts[9]) || 0;
        const now = Date.now();
        if (lastNetSample && lastNetSample.iface === iface) {
          const dtSec = (now - lastNetSample.ts) / 1000;
          if (dtSec > 0) {
            net.rx_kbps = Math.round((rx - lastNetSample.rx) / 1024 / dtSec);
            net.tx_kbps = Math.round((tx - lastNetSample.tx) / 1024 / dtSec);
          }
        }
        net.iface = iface;
        lastNetSample = { ts: now, rx, tx, iface };
      }
    } catch(e) {}

    // Printer & scanner detection
    let printerOk = false, scannerOk = false;
    try {
      printerOk = printer.isConnected();
      const lsusb = execSync('lsusb 2>/dev/null', { timeout: 2000 }).toString();
      scannerOk = /barcode|scanner|hid/i.test(lsusb);
    } catch(e) {}

    const payload = {
      cpu: parseInt(cpu) || 0,
      ram: { used: parseInt(ramUsed) || 0, total: parseInt(ramTotal) || 0 },
      disk: { pct: parseInt(diskPct) || 0, used: diskUsed, total: diskTotal },
      net, temp, uptime, ip, connections: wsConns,
      services: { postgresql: pgOk, api: apiOk, printer: printerOk, scanner: scannerOk },
      lastBackup,
    };

    // Store in metrics history circular buffer
    metricsHistory.push({
      t: Date.now(),
      cpu: payload.cpu,
      ram: payload.ram.total > 0 ? Math.round(payload.ram.used / payload.ram.total * 100) : 0,
      disk: payload.disk.pct,
      rx: Math.max(0, net.rx_kbps),
      tx: Math.max(0, net.tx_kbps),
    });
    if (metricsHistory.length > METRICS_HISTORY_MAX) metricsHistory.shift();

    res.json(payload);
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/system/history', (req, res) => {
  res.json(metricsHistory);
});

// Restart a service (postgresql, nginx — no cantina-api, ese usa /restart)
app.post('/api/system/restart/:service', (req, res) => {
  const allowed = { 'cantina-api': true, 'postgresql': true };
  if (!allowed[req.params.service]) return res.status(400).json({ error: 'Not allowed' });
  exec(`sudo -n systemctl restart ${req.params.service} 2>&1`, { timeout: 15000 }, (err, _out, stderr) => {
    if (err) {
      console.error(`[system] restart ${req.params.service} FAILED:`, stderr || err.message);
      if (!res.headersSent) return res.status(500).json({ restarted: false, service: req.params.service, error: stderr || err.message });
    }
    if (!res.headersSent) res.json({ restarted: true, service: req.params.service });
  });
});

// Restart the main app service — responder ANTES de morir; systemd nos levanta de vuelta
app.post('/api/system/restart', (req, res) => {
  res.json({ ok: true, restarting: true });
  setTimeout(() => exec('sudo -n systemctl restart cantina-api 2>&1', (_err, _o, se) => {
    if (_err) console.error('[system] restart self FAILED:', se || _err.message);
    else console.log('[system] reinicio en curso...');
  }), 300);
});

// Shutdown the server — detectar falla real antes de responder éxito
app.post('/api/system/shutdown', (req, res) => {
  exec('sudo -n shutdown -h now 2>&1', { timeout: 5000 }, (err, _out, stderr) => {
    if (err) {
      console.error('[system] shutdown FAILED:', stderr || err.message);
      return res.status(500).json({ ok: false, error: stderr || err.message });
    }
    if (!res.headersSent) res.json({ ok: true });
  });
});

// Clear RAM cache
app.post('/api/system/clear-cache', (req, res) => {
  try {
    execSync('sync; echo 3 | sudo -n tee /proc/sys/vm/drop_caches', { timeout: 5000 });
    res.json({ cleared: true });
  } catch(e) {
    res.json({ cleared: false, error: e.message });
  }
});

// Backup database
app.post('/api/system/backup', async (req, res) => {
  try {
    const backupDir = path.join(__dirname, 'backups');
    if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });
    const filename = `cantina_${new Date().toISOString().slice(0,19).replace(/[:-]/g,'')}.sql`;
    const filepath = path.join(backupDir, filename);
    execSync(`PGPASSWORD=cantina2025 pg_dump -U cantina -h localhost cantina_pos > ${filepath}`, { timeout: 30000 });
    // Keep only last 30 backups
    const files = fs.readdirSync(backupDir).filter(f => f.endsWith('.sql')).sort();
    while (files.length > 30) { fs.unlinkSync(path.join(backupDir, files.shift())); }
    const stat = fs.statSync(filepath);
    res.json({ success: true, file: filename, size: (stat.size / 1024).toFixed(0) + ' KB' });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// Reset a producción — borra todos los datos de prueba, conserva usuarios
app.post('/api/system/reset-produccion', async (req, res) => {
  try {
    const backupDir = path.join(__dirname, 'backups');
    if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });

    // 1. Backup de seguridad pre-reset
    const filename = `pre_reset_${new Date().toISOString().slice(0,19).replace(/[:-]/g,'')}.sql`;
    const filepath = path.join(backupDir, filename);
    execSync(`PGPASSWORD=cantina2025 pg_dump -U cantina -h localhost cantina_pos > ${filepath}`, { timeout: 30000 });

    // 2. Truncar en orden FK correcto
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE "PedidoItem" RESTART IDENTITY CASCADE`);
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE "Pedido" RESTART IDENTITY CASCADE`);
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE "CierreCaja" RESTART IDENTITY CASCADE`);
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE "ClientePago" RESTART IDENTITY CASCADE`);
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE "Cliente" RESTART IDENTITY CASCADE`);
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE "Producto" RESTART IDENTITY CASCADE`);
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE "Categoria" RESTART IDENTITY CASCADE`);
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE "CarouselImage" RESTART IDENTITY CASCADE`);

    // 3. Borrar backups viejos (conservar solo el pre-reset recién creado)
    fs.readdirSync(backupDir)
      .filter(f => f.endsWith('.sql') && f !== filename)
      .forEach(f => fs.unlinkSync(path.join(backupDir, f)));

    res.json({ ok: true, backup: filename });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================
// USUARIOS
// ============================================
app.get('/api/usuarios', async (req, res) => {
  try {
    const users = await prisma.usuario.findMany({ where: { activo: true } });
    res.json(users);
  } catch(e) { res.status(500).json({ error: e.message }); }
});
app.post('/api/usuarios', async (req, res) => {
  try {
    const user = await prisma.usuario.create({ data: req.body });
    res.json(user);
  } catch(e) { res.status(400).json({ error: e.message }); }
});
app.put('/api/usuarios/:id', async (req, res) => {
  try {
    const user = await prisma.usuario.update({ where: { id: Number(req.params.id) }, data: req.body });
    res.json(user);
  } catch(e) { res.status(500).json({ error: e.message }); }
});
app.delete('/api/usuarios/:id', async (req, res) => {
  try {
    await prisma.usuario.update({ where: { id: Number(req.params.id) }, data: { activo: false } });
    res.json({ deleted: true });
  } catch(e) { res.status(500).json({ error: e.message }); }
});
app.post('/api/login', async (req, res) => {
  try {
    const user = await prisma.usuario.findUnique({ where: { pin: req.body.pin } });
    if (user && user.activo) res.json(user);
    else res.status(401).json({ error: 'PIN incorrecto' });
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ============================================
// CATEGORIAS
// ============================================
app.get('/api/categorias', async (req, res) => {
  try {
    const cats = await prisma.categoria.findMany({ orderBy: { orden: 'asc' } });
    res.json(cats);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/categorias', async (req, res) => {
  try {
    const { nombre, emoji, color, despacho_directo, orden } = req.body;
    if (!nombre?.trim()) return res.status(400).json({ error: 'nombre requerido' });
    const cat = await prisma.categoria.create({
      data: { nombre: nombre.trim(), emoji: emoji || '📦', color: color || '#6B7080', despacho_directo: !!despacho_directo, orden: orden || 0 }
    });
    res.json(cat);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

app.put('/api/categorias/:id', async (req, res) => {
  try {
    const { nombre, emoji, color, despacho_directo, orden } = req.body;
    if (!nombre?.trim()) return res.status(400).json({ error: 'nombre requerido' });
    const cat = await prisma.categoria.update({
      where: { id: Number(req.params.id) },
      data: { nombre: nombre.trim(), emoji, color, despacho_directo: !!despacho_directo, orden: orden ?? 0 }
    });
    res.json(cat);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ============================================
// PRODUCTOS
// ============================================
app.get('/api/productos', async (req, res) => {
  try {
    const prods = await prisma.producto.findMany({ where: { activo: true }, include: { categoria: true } });
    res.json(prods);
  } catch(e) { res.status(500).json({ error: e.message }); }
});
app.post('/api/productos', async (req, res) => {
  try {
    const prod = await prisma.producto.create({ data: req.body, include: { categoria: true } });
    res.json(prod);
  } catch(e) { res.status(400).json({ error: e.message }); }
});
app.put('/api/productos/:id', async (req, res) => {
  try {
    const prod = await prisma.producto.update({ where: { id: Number(req.params.id) }, data: req.body, include: { categoria: true } });
    res.json(prod);
  } catch(e) { res.status(500).json({ error: e.message }); }
});
app.get('/api/productos/barcode/:code', async (req, res) => {
  try {
    const prod = await prisma.producto.findUnique({ where: { codigo: req.params.code }, include: { categoria: true } });
    if (prod) res.json(prod);
    else res.status(404).json({ error: 'No encontrado' });
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ============================================
// CLIENTES
// ============================================
app.get('/api/clientes', async (req, res) => {
  try {
    const clients = await prisma.cliente.findMany({ where: { activo: true }, include: { pagos: { orderBy: { fecha: 'desc' }, take: 20 } } });
    res.json(clients);
  } catch(e) { res.status(500).json({ error: e.message }); }
});
app.post('/api/clientes', async (req, res) => {
  try {
    const client = await prisma.cliente.create({ data: { nombre: req.body.nombre, apellido: req.body.apellido || '', apodo: req.body.apodo || '', division: req.body.division || '', whatsapp: req.body.whatsapp || '' } });
    res.json(client);
  } catch(e) { res.status(400).json({ error: e.message }); }
});
app.put('/api/clientes/:id', async (req, res) => {
  try {
    const client = await prisma.cliente.update({ where: { id: Number(req.params.id) }, data: req.body });
    res.json(client);
  } catch(e) { res.status(500).json({ error: e.message }); }
});
app.get('/api/clientes/:id/pedidos', async (req, res) => {
  try {
    const pedidos = await prisma.pedido.findMany({
      where: { cliente_id: Number(req.params.id), cobrado: true },
      include: { items: { include: { producto: { select: { nombre: true } } } } },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    res.json(pedidos);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/clientes/:id/pago', async (req, res) => {
  try {
    const { monto } = req.body;
    if (!monto || monto <= 0) return res.status(400).json({ error: 'monto debe ser mayor a 0' });
    const updated = await prisma.$transaction(async (tx) => {
      const cliente = await tx.cliente.findUnique({ where: { id: Number(req.params.id) } });
      if (!cliente) throw Object.assign(new Error('Cliente no encontrado'), { status: 404 });
      await tx.clientePago.create({ data: { cliente_id: cliente.id, monto } });
      return tx.cliente.update({ where: { id: cliente.id }, data: { saldo: Math.max(0, cliente.saldo - monto) } });
    });
    res.json(updated);
  } catch(e) {
    res.status(e.status || 500).json({ error: e.message });
  }
});

// ============================================
// PEDIDOS
// ============================================
app.get('/api/pedidos', async (req, res) => {
  try {
    const today = midnightAR();
    const pedidos = await prisma.pedido.findMany({
      where: { createdAt: { gte: today } },
      include: { items: { include: { producto: true } }, cliente: true },
      orderBy: { createdAt: 'desc' }
    });
    res.json(pedidos);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

app.get('/api/pedidos/all', async (req, res) => {
  try {
    const pedidos = await prisma.pedido.findMany({
      include: { items: { include: { producto: true } }, cliente: true },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
    res.json(pedidos);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// Pedidos cobrados de un día específico (para reconstruir detalle de cierres sin details guardados)
app.get('/api/pedidos/por-fecha', async (req, res) => {
  try {
    const { fecha } = req.query; // YYYY-MM-DD
    if (!fecha) return res.status(400).json({ error: 'fecha requerida' });
    const desde = new Date(fecha);
    desde.setHours(0, 0, 0, 0);
    const hasta = new Date(fecha);
    hasta.setHours(23, 59, 59, 999);
    const pedidos = await prisma.pedido.findMany({
      where: { cobrado: true, estado: { not: 'cancelado' }, createdAt: { gte: desde, lte: hasta } },
      include: { items: { include: { producto: true } }, cliente: true },
      orderBy: { createdAt: 'asc' },
    });
    res.json(pedidos);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/pedidos', async (req, res) => {
  try {
    const { tipo, mesa_numero, nombre_cliente, total, items } = req.body;
    if (!Array.isArray(items) || items.length === 0) return res.status(400).json({ error: 'items requeridos' });
    if (!['mesa', 'barra'].includes(tipo)) return res.status(400).json({ error: 'tipo inválido' });
    if (!total || total <= 0) return res.status(400).json({ error: 'total inválido' });
    if (items.some(i => !Number.isInteger(i.cantidad) || i.cantidad <= 0))
      return res.status(400).json({ error: 'cantidad inválida' });

    const pedido = await prisma.$transaction(async (tx) => {
      const today = midnightAR();
      const lastPedido = await tx.pedido.findFirst({ where: { createdAt: { gte: today } }, orderBy: { numero: 'desc' } });
      const numero = (lastPedido?.numero || 0) + 1;
      const pedido = await tx.pedido.create({
        data: {
          numero, tipo,
          mesa_numero: mesa_numero || null,
          nombre_cliente: nombre_cliente || null,
          total,
          items: {
            create: items.map(i => ({
              producto_id: i.producto_id,
              cantidad: i.cantidad,
              precio: i.precio,
              observaciones: i.observaciones || null,
            }))
          }
        },
        include: { items: { include: { producto: true } } }
      });
      for (const item of items) {
        await tx.producto.update({ where: { id: item.producto_id }, data: { stock: { decrement: item.cantidad } } });
      }
      return pedido;
    });

    io.emit('nuevo-pedido', pedido);
    res.json(pedido);
  } catch(e) {
    console.error('Error creando pedido:', e);
    res.status(500).json({ error: e.message });
  }
});

app.put('/api/pedidos/:id', async (req, res) => {
  try {
    const { estado } = req.body;
    const estadosValidos = ['pendiente', 'en_preparacion', 'listo', 'entregado'];
    if (!estado) return res.status(400).json({ error: 'estado requerido' });
    // 'cancelado' debe ir por /cancelar que restaura el stock
    if (!estadosValidos.includes(estado)) return res.status(400).json({ error: `estado inválido (usar: ${estadosValidos.join(', ')})` });
    const pedido = await prisma.pedido.update({
      where: { id: Number(req.params.id) },
      data: { estado },
      include: { items: { include: { producto: true } } }
    });
    io.emit('pedido-actualizado', pedido);
    res.json(pedido);
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/api/pedidos/:id/items', async (req, res) => {
  try {
    const { items } = req.body;
    if (!Array.isArray(items) || items.length === 0) return res.status(400).json({ error: 'items requeridos' });
    if (items.some(i => !Number.isInteger(i.cantidad) || i.cantidad <= 0)) return res.status(400).json({ error: 'cantidad inválida' });
    const pedidoId = Number(req.params.id);

    const pedido = await prisma.$transaction(async tx => {
      const current = await tx.pedidoItem.findMany({ where: { pedido_id: pedidoId } });

      // Restaurar stock de ítems anteriores
      for (const item of current) {
        await tx.producto.update({ where: { id: item.producto_id }, data: { stock: { increment: item.cantidad } } });
      }

      // Borrar ítems anteriores
      await tx.pedidoItem.deleteMany({ where: { pedido_id: pedidoId } });

      // Calcular nuevo total
      const total = items.reduce((s, i) => s + i.precio * i.cantidad, 0);

      // Crear nuevos ítems y descontar stock
      const updated = await tx.pedido.update({
        where: { id: pedidoId },
        data: {
          total,
          items: {
            create: items.map(i => ({
              producto_id: i.producto_id,
              cantidad: i.cantidad,
              precio: i.precio,
              observaciones: i.observaciones || null,
            }))
          }
        },
        include: { items: { include: { producto: true } } }
      });

      for (const item of items) {
        await tx.producto.update({ where: { id: item.producto_id }, data: { stock: { decrement: item.cantidad } } });
      }

      return updated;
    });

    io.emit('pedido-actualizado', pedido);
    res.json(pedido);
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/pedidos/:id/cobrar', async (req, res) => {
  const { metodo_pago, referencia, descuento_pct, cliente_id } = req.body;
  const metodosValidos = ['efectivo', 'transferencia', 'cuenta_corriente'];
  if (!metodosValidos.includes(metodo_pago)) return res.status(400).json({ error: 'metodo_pago inválido' });

  try {
    const pedido = await prisma.$transaction(async (tx) => {
      const existing = await tx.pedido.findUnique({ where: { id: Number(req.params.id) } });
      if (!existing) throw Object.assign(new Error('Pedido no encontrado'), { status: 404 });
      if (existing.cobrado) throw Object.assign(new Error('Pedido ya cobrado'), { status: 409 });

      const totalConDescuento = descuento_pct
        ? Math.round(existing.total * (1 - descuento_pct / 100))
        : existing.total;
      const data = { cobrado: true, metodo_pago, total: totalConDescuento, estado: 'entregado' };
      if (referencia) data.referencia = referencia;
      if (descuento_pct) data.descuento_pct = descuento_pct;
      if (cliente_id) data.cliente_id = cliente_id;

      // where cobrado:false es el guard atómico: si otra tx cobró mientras esperábamos
      // el UPDATE no encuentra la fila y Prisma lanza P2025 → 409
      const pedido = await tx.pedido.update({
        where: { id: Number(req.params.id), cobrado: false },
        data,
        include: { items: { include: { producto: true } }, cliente: true }
      }).catch(e => {
        if (e.code === 'P2025') throw Object.assign(new Error('Pedido ya cobrado'), { status: 409 });
        throw e;
      });
      if (metodo_pago === 'cuenta_corriente' && cliente_id) {
        await tx.cliente.update({ where: { id: cliente_id }, data: { saldo: { increment: totalConDescuento } } });
      }
      return pedido;
    });
    io.emit('pedido-actualizado', pedido);
    // Imprimir ticket automáticamente (fire-and-forget, no bloquea la respuesta)
    ;(async () => {
      let mozo_nombre = null;
      const mozo_id = mesasMozos[pedido.mesa_numero];
      if (mozo_id) {
        try {
          const u = await prisma.usuario.findUnique({ where: { id: mozo_id }, select: { nombre: true } });
          mozo_nombre = u?.nombre || null;
        } catch {}
      }
      printer.printTicket({ ...pedido, _mozo_nombre: mozo_nombre }).catch(err => console.error('[printer] cobro fail:', err.message));
    })();
    res.json(pedido);
  } catch(e) {
    console.error('Cobro error:', e);
    res.status(e.status || 500).json({ error: e.message });
  }
});

// ============================================
// LIBERAR MESA
// ============================================
app.post('/api/mesas/:num/liberar', async (req, res) => {
  const num = Number(req.params.num);
  if (!num) return res.status(400).json({ error: 'Número de mesa inválido' });
  try {
    const activos = await prisma.pedido.findMany({
      where: { mesa_numero: num, mesa_liberada: false, estado: { not: 'cancelado' } }
    });
    if (activos.length === 0) return res.status(404).json({ error: 'No hay pedidos activos para esta mesa' });
    const allReady = activos.every(p => p.cobrado);
    if (!allReady) return res.status(409).json({ error: 'Hay pedidos sin cobrar en esta mesa' });
    await prisma.pedido.updateMany({
      where: { mesa_numero: num, mesa_liberada: false },
      data: { mesa_liberada: true }
    });
    delete mesasMozos[num];
    io.emit('mesa-liberada', { mesa_numero: num });
    res.json({ ok: true });
  } catch(e) {
    console.error('[mesas/liberar] error:', e);
    res.status(500).json({ error: e.message });
  }
});

// ============================================
// COBRAR MESA (todos los pedidos, un solo ticket)
// ============================================
app.post('/api/mesas/:num/cobrar', async (req, res) => {
  const num = Number(req.params.num);
  if (!num) return res.status(400).json({ error: 'Número de mesa inválido' });
  const { metodo_pago, referencia, cliente_id, descuento_pct } = req.body;
  const metodosValidos = ['efectivo', 'transferencia', 'cuenta_corriente'];
  if (!metodosValidos.includes(metodo_pago)) return res.status(400).json({ error: 'metodo_pago inválido' });

  try {
    const cobrados = await prisma.$transaction(async (tx) => {
      const sinCobrar = await tx.pedido.findMany({
        where: { mesa_numero: num, cobrado: false, estado: { not: 'cancelado' }, mesa_liberada: false },
        include: { items: { include: { producto: true } }, cliente: true }
      });
      if (sinCobrar.length === 0) throw Object.assign(new Error('No hay pedidos sin cobrar en esta mesa'), { status: 404 });

      const resultado = [];
      for (const p of sinCobrar) {
        const totalConDescuento = descuento_pct ? Math.round(p.total * (1 - descuento_pct / 100)) : p.total;
        const data = { cobrado: true, metodo_pago, total: totalConDescuento, estado: 'entregado' };
        if (referencia) data.referencia = referencia;
        if (descuento_pct) data.descuento_pct = descuento_pct;
        if (cliente_id) data.cliente_id = cliente_id;
        const updated = await tx.pedido.update({
          where: { id: p.id, cobrado: false },
          data,
          include: { items: { include: { producto: true } }, cliente: true }
        }).catch(e => {
          if (e.code === 'P2025') throw Object.assign(new Error('Pedido ya cobrado'), { status: 409 });
          throw e;
        });
        resultado.push(updated);
      }

      if (metodo_pago === 'cuenta_corriente' && cliente_id) {
        const totalMesa = resultado.reduce((s, p) => s + p.total, 0);
        await tx.cliente.update({ where: { id: cliente_id }, data: { saldo: { increment: totalMesa } } });
      }
      return resultado;
    });

    for (const p of cobrados) io.emit('pedido-actualizado', p);

    // Un solo ticket combinado
    ;(async () => {
      let mozo_nombre = null;
      const mozo_id = mesasMozos[num];
      if (mozo_id) {
        try {
          const u = await prisma.usuario.findUnique({ where: { id: mozo_id }, select: { nombre: true } });
          mozo_nombre = u?.nombre || null;
        } catch {}
      }
      const totalMesa = cobrados.reduce((s, p) => s + p.total, 0);
      const cliente   = cobrados.find(p => p.cliente)?.cliente || null;
      const mesaTicket = {
        createdAt: new Date(),
        tipo: 'mesa',
        mesa_numero: num,
        _numeros: cobrados.map(p => p.numero),
        id: cobrados[0].id,
        _mozo_nombre: mozo_nombre,
        items: cobrados.flatMap(p => p.items),
        total: totalMesa,
        metodo_pago,
        cliente,
        descuento_pct: descuento_pct || null,
      };
      printer.printTicket(mesaTicket).catch(err => console.error('[printer] cobro-mesa fail:', err.message));
    })();

    res.json({ ok: true, pedidos: cobrados });
  } catch(e) {
    console.error('[mesas/cobrar] error:', e);
    res.status(e.status || 500).json({ error: e.message });
  }
});

// ============================================
// PRINTER endpoints
// ============================================
app.post('/api/print/:pedidoId', async (req, res) => {
  try {
    const pedido = await prisma.pedido.findUnique({
      where: { id: Number(req.params.pedidoId) },
      include: { items: { include: { producto: true } }, cliente: true }
    });
    if (!pedido) return res.status(404).json({ success: false, error: 'Pedido no encontrado' });
    let mozo_nombre = null;
    const mozo_id = mesasMozos[pedido.mesa_numero];
    if (mozo_id) {
      try {
        const u = await prisma.usuario.findUnique({ where: { id: mozo_id }, select: { nombre: true } });
        mozo_nombre = u?.nombre || null;
      } catch {}
    }
    const ok = await printer.printTicket({ ...pedido, _mozo_nombre: mozo_nombre });
    if (ok) res.json({ success: true });
    else res.status(500).json({ success: false, error: 'No se pudo imprimir (revisar conexión/permiso)' });
  } catch(e) {
    console.error('[printer] print pedido error:', e.message);
    res.status(500).json({ success: false, error: e.message });
  }
});

app.get('/api/printer/test', async (req, res) => {
  const r = await printer.printTest();
  if (r.success) res.json(r);
  else res.status(500).json(r);
});

app.get('/api/printer/status', (req, res) => {
  res.json(printer.status());
});

app.post('/api/pedidos/:id/cancelar', async (req, res) => {
  try {
    const updated = await prisma.$transaction(async (tx) => {
      const pedido = await tx.pedido.findUnique({ where: { id: Number(req.params.id) }, include: { items: true } });
      if (!pedido) throw Object.assign(new Error('Pedido no encontrado'), { status: 404 });
      if (pedido.estado === 'cancelado') throw Object.assign(new Error('Pedido ya cancelado'), { status: 409 });
      if (pedido.cobrado) throw Object.assign(new Error('No se puede cancelar un pedido ya cobrado'), { status: 409 });

      for (const item of pedido.items) {
        await tx.producto.update({ where: { id: item.producto_id }, data: { stock: { increment: item.cantidad } } });
      }
      return tx.pedido.update({ where: { id: Number(req.params.id) }, data: { estado: 'cancelado' } });
    });
    io.emit('pedido-actualizado', updated);
    res.json(updated);
  } catch(e) {
    res.status(e.status || 500).json({ error: e.message });
  }
});

// ============================================
// CIERRE DE CAJA
// ============================================
app.post('/api/cierres', async (req, res) => {
  try {
    const { efectivo, transferencia, fiado, totalVentas, cantPedidos } = req.body;
    if ([efectivo, transferencia, fiado, totalVentas, cantPedidos].some(v => v == null))
      return res.status(400).json({ error: 'Campos requeridos: efectivo, transferencia, fiado, totalVentas, cantPedidos' });
    const cierre = await prisma.cierreCaja.create({ data: {
      efectivo: Number(efectivo), transferencia: Number(transferencia), fiado: Number(fiado),
      totalVentas: Number(totalVentas), cantPedidos: Number(cantPedidos),
      arqueo: req.body.arqueo != null ? Number(req.body.arqueo) : null,
      diferencia: req.body.diferencia != null ? Number(req.body.diferencia) : null,
      details: req.body.details ?? null,
    }});
    res.json(cierre);
  } catch(e) { res.status(500).json({ error: e.message }); }
});
app.get('/api/cierres', async (req, res) => {
  try {
    const cierres = await prisma.cierreCaja.findMany({ orderBy: { fecha: 'desc' }, take: 30 });
    res.json(cierres);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

app.get('/api/cierres/:id', async (req, res) => {
  try {
    const cierre = await prisma.cierreCaja.findUnique({ where: { id: Number(req.params.id) } });
    if (!cierre) return res.status(404).json({ error: 'No encontrado' });
    res.json(cierre);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ============================================
// ESTADÍSTICAS — ventas por producto con rango de fechas
// ============================================
app.get('/api/estadisticas', async (req, res) => {
  try {
    const range = req.query.range || 'today';
    const now = new Date();
    let since, until = null;

    if (range === 'week') {
      since = new Date(now); since.setDate(since.getDate() - 6); since.setHours(0, 0, 0, 0);
    } else if (range === 'month') {
      since = new Date(now.getFullYear(), now.getMonth(), 1);
    } else if (range === 'lastmonth') {
      since = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      until = new Date(now.getFullYear(), now.getMonth(), 1);
    } else if (range === 'all') {
      since = new Date(0);
    } else {
      since = midnightAR();
    }

    const dateFilter = { gte: since };
    if (until) dateFilter.lt = until;

    const pedidos = await prisma.pedido.findMany({
      where: { cobrado: true, estado: { not: 'cancelado' }, createdAt: dateFilter },
      include: { items: { include: { producto: true } } },
    });

    // Aggregate sales by product
    const prodMap = {};
    pedidos.forEach(p => {
      p.items.forEach(item => {
        const nombre = item.producto?.nombre || `Producto #${item.producto_id}`;
        const id = item.producto_id;
        if (!prodMap[id]) prodMap[id] = { id, nombre, cantidad: 0, total: 0 };
        prodMap[id].cantidad += item.cantidad;
        prodMap[id].total += item.precio * item.cantidad;
      });
    });

    const totalVentas = pedidos.reduce((s, p) => s + p.total, 0);
    const totalCantidad = Object.values(prodMap).reduce((s, p) => s + p.cantidad, 0);

    const productos = Object.values(prodMap).sort((a, b) => b.cantidad - a.cantidad);
    productos.forEach(p => {
      p.pctCantidad = totalCantidad > 0 ? Math.round(p.cantidad / totalCantidad * 1000) / 10 : 0;
      p.pctTotal = totalVentas > 0 ? Math.round(p.total / totalVentas * 1000) / 10 : 0;
    });

    // Find peak hour
    const horaCounts = {};
    pedidos.forEach(p => {
      const h = new Date(p.createdAt).getHours();
      horaCounts[h] = (horaCounts[h] || 0) + 1;
    });
    const horaEntries = Object.entries(horaCounts);
    const horarioPico = horaEntries.length > 0
      ? horaEntries.reduce((best, [h, c]) => Number(c) > best.cantidad ? { hora: Number(h), cantidad: Number(c) } : best, { hora: 0, cantidad: 0 })
      : null;

    res.json({
      productos,
      pedidosCount: pedidos.length,
      ticketPromedio: pedidos.length > 0 ? Math.round(totalVentas / pedidos.length) : 0,
      horarioPico,
      totalVentas,
    });
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ============================================
// AUTOSERVICIO (pending orders for caja approval)
// ============================================
const mesasMozos = {}; // { [mesa_numero]: usuario_id } — en memoria, se limpia al reiniciar
app.get('/api/mesas/mozos', (req, res) => res.json(mesasMozos));
app.put('/api/mesas/mozos', (req, res) => {
  const { mesa, userId } = req.body;
  if (userId === null || userId === undefined) delete mesasMozos[mesa];
  else mesasMozos[mesa] = userId;
  res.json(mesasMozos);
});

const pendingAutoservicio = [];
app.post('/api/autoservicio/pedido', (req, res) => {
  const pedido = { ...req.body, id: Date.now(), numero: pendingAutoservicio.length + 1 };
  pendingAutoservicio.push(pedido);
  // Broadcast to all connected clients (caja will show notification)
  io.emit('notif-autoservicio', pedido);
  res.json(pedido);
});
app.get('/api/autoservicio/pendientes', (req, res) => {
  res.json(pendingAutoservicio);
});
app.delete('/api/autoservicio/:id', (req, res) => {
  const idx = pendingAutoservicio.findIndex(p => p.id === Number(req.params.id));
  if (idx >= 0) pendingAutoservicio.splice(idx, 1);
  res.json({ deleted: true });
});

// ============================================
// CAROUSEL IMAGES
// ============================================
app.get('/api/carousel', async (req, res) => {
  try {
    const imgs = await prisma.carouselImage.findMany({ where: { activo: true }, orderBy: { orden: 'asc' } });
    res.json(imgs);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/carousel', async (req, res) => {
  try {
    const { filename, data } = req.body;
    if (!filename || !data) return res.status(400).json({ error: 'filename y data requeridos' });
    const ext = path.extname(filename).toLowerCase();
    const allowed = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    if (!allowed.includes(ext)) return res.status(400).json({ error: 'Formato no permitido' });
    const safeName = Date.now() + '_' + filename.replace(/[^a-zA-Z0-9._-]/g, '_');
    const imgPath = path.join(__dirname, 'images', safeName);
    const base64Data = data.replace(/^data:image\/\w+;base64,/, '');
    fs.writeFileSync(imgPath, Buffer.from(base64Data, 'base64'));
    const maxOrden = await prisma.carouselImage.aggregate({ _max: { orden: true } });
    const orden = (maxOrden._max.orden ?? -1) + 1;
    const img = await prisma.carouselImage.create({ data: { filename: safeName, orden, activo: true } });
    res.json(img);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

app.delete('/api/carousel/:id', async (req, res) => {
  try {
    const img = await prisma.carouselImage.findUnique({ where: { id: Number(req.params.id) } });
    if (!img) return res.status(404).json({ error: 'No encontrado' });
    const imgPath = path.join(__dirname, 'images', img.filename);
    if (fs.existsSync(imgPath)) fs.unlinkSync(imgPath);
    await prisma.carouselImage.delete({ where: { id: img.id } });
    res.json({ deleted: true });
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ============================================
// TICKET (generate printable ticket text)
// ============================================
app.get('/api/pedidos/:id/ticket', async (req, res) => {
  try {
    const pedido = await prisma.pedido.findUnique({
      where: { id: Number(req.params.id) },
      include: { items: { include: { producto: true } }, cliente: true }
    });
    if (!pedido) return res.status(404).json({ error: 'No encontrado' });

    const fecha = new Date(pedido.createdAt);
    const fp = new Intl.DateTimeFormat('es-AR', {
      timeZone: 'America/Argentina/Tucuman',
      day: '2-digit', month: '2-digit', year: '2-digit',
      hour: '2-digit', minute: '2-digit', hour12: false,
    }).formatToParts(fecha).reduce((a, p) => { a[p.type] = p.value; return a; }, {});
    const dd = fp.day, mmes = fp.month, yy = fp.year, hh = fp.hour, min = fp.minute;
    const tipo = pedido.tipo === 'mesa' ? `Mesa ${pedido.mesa_numero}` : 'Barra';
    const numero = String(pedido.numero).padStart(3,'0');

    const W = 42;
    let ticket = '';
    ticket += '==========================================\n';
    ticket += '             CANTINA NyG\n';
    ticket += '      Club Natacion y Gimnasia\n';
    ticket += '  Primero el club, siempre el club\n';
    ticket += '==========================================\n';
    ticket += `${dd}/${mmes}/${yy} ${hh}:${min}`.padEnd(W - (`Ticket #${String(pedido.id).padStart(4,'0')}`).length) + `Ticket #${String(pedido.id).padStart(4,'0')}` + '\n';
    ticket += '..........................................\n';
    ticket += `${tipo}`.padEnd(W - (`PEDIDO #${numero}`).length) + `PEDIDO #${numero}` + '\n';
    ticket += '------------------------------------------\n';
    ticket += 'CANT DESCRIPCION               TOTAL\n';
    ticket += '------------------------------------------\n';

    for (const item of pedido.items) {
      const nombre = (item.producto?.nombre || '?').slice(0, 24);
      const subtotal = item.cantidad * item.precio;
      const label = `${item.cantidad}x ${nombre}`.slice(0, 33);
      ticket += label.padEnd(33) + `$${subtotal.toLocaleString('es-AR')}`.padStart(9) + '\n';
      if (item.cantidad > 1) ticket += `      $${item.precio.toLocaleString('es-AR')} c/u\n`;
      if (item.observaciones) ticket += `   >> ${item.observaciones}\n`;
    }

    ticket += '------------------------------------------\n';
    if (pedido.descuento_pct) {
      const totalAntes = Math.round(pedido.total / (1 - pedido.descuento_pct / 100));
      ticket += 'Subtotal'.padEnd(33) + `$${totalAntes.toLocaleString('es-AR')}`.padStart(9) + '\n';
      ticket += `Desc. ${pedido.descuento_pct}%`.padEnd(33) + `-$${(totalAntes - pedido.total).toLocaleString('es-AR')}`.padStart(9) + '\n';
    }
    ticket += '..........................................\n';
    ticket += 'TOTAL'.padEnd(33) + `$${pedido.total.toLocaleString('es-AR')}`.padStart(9) + '\n';

    if (pedido.cobrado) {
      const met = { efectivo: 'Efectivo', transferencia: 'Transferencia', cuenta_corriente: 'Cuenta corriente' }[pedido.metodo_pago] || pedido.metodo_pago;
      ticket += `Pago: ${met}\n`;
      if (pedido.cliente) ticket += `A nombre de: ${pedido.cliente.nombre} ${pedido.cliente.apellido || ''}\n`;
    }

    ticket += '==========================================\n';
    ticket += '       ¡Gracias por su visita!\n';
    ticket += '            @cantinanyg\n';
    ticket += '==========================================\n';

    res.json({ ticket, pedido });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================
// WEBSOCKET
// ============================================
io.on('connection', (socket) => {
  console.log('📱 Dispositivo conectado:', socket.id);
  socket.on('disconnect', () => console.log('📱 Desconectado:', socket.id));

  // Autoservicio sends order for caja approval
  socket.on('pedido-autoservicio', (data) => {
    io.emit('notif-autoservicio', data);
  });

  // Estado changes from cocina
  socket.on('cambiar-estado', async (data) => {
    const estadosValidos = ['pendiente', 'en_preparacion', 'listo', 'entregado'];
    if (!data?.id || !estadosValidos.includes(data?.estado)) return;
    try {
      const pedido = await prisma.pedido.update({
        where: { id: data.id },
        data: { estado: data.estado },
        include: { items: { include: { producto: true } } }
      });
      io.emit('pedido-actualizado', pedido);
    } catch(e) {
      console.error('Error cambiando estado:', e.message);
    }
  });
});

// ============================================
// SERVE FRONTEND
// ============================================
app.use(express.static(path.join(__dirname, 'client', 'dist')));
app.get('/{*path}', (req, res) => {
  res.sendFile(path.join(__dirname, 'client', 'dist', 'index.html'));
});

// ============================================
// START
// ============================================
const PORT = process.env.PORT || 3001;
server.listen(PORT, '127.0.0.1', () => {
  console.log(`🍽️  Cantina POS corriendo en http://127.0.0.1:${PORT}`);
  console.log(`📊 Sistema: http://127.0.0.1:${PORT}/api/system`);
  console.log(`💚 Health: http://127.0.0.1:${PORT}/api/health`);
});
