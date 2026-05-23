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

// Circular buffer for system metrics history (last 120 samples @ 5s = 10 min)
const METRICS_HISTORY_MAX = 120;
const metricsHistory = [];
let lastNetSample = null; // { ts, rx, tx } for rate calculation

app.use(cors());
app.use(express.json({ limit: '15mb' }));
app.use('/images', express.static(path.join(__dirname, 'images')));

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
      const files = fs.readdirSync(backupDir).filter(f => f.endsWith('.sql')).sort().reverse();
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
      const lsusb = execSync('lsusb 2>/dev/null', { timeout: 2000 }).toString();
      printerOk = /printer|thermal|receipt|0483|1a86/i.test(lsusb) || fs.existsSync('/dev/usb/lp0');
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

// Restart a service
app.post('/api/system/restart/:service', (req, res) => {
  const allowed = { 'cantina-api': true, 'postgresql': true };
  if (!allowed[req.params.service]) return res.status(400).json({ error: 'Not allowed' });
  try {
    exec(`sudo -n systemctl restart ${req.params.service}`, (err) => {
      res.json({ restarted: true, service: req.params.service, error: err?.message || null });
    });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
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
    execSync(`pg_dump cantina_pos > ${filepath}`, { timeout: 30000 });
    // Keep only last 30 backups
    const files = fs.readdirSync(backupDir).filter(f => f.endsWith('.sql')).sort();
    while (files.length > 30) { fs.unlinkSync(path.join(backupDir, files.shift())); }
    const stat = fs.statSync(filepath);
    res.json({ success: true, file: filename, size: (stat.size / 1024).toFixed(0) + ' KB' });
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
    const today = new Date(); today.setHours(0, 0, 0, 0);
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

app.post('/api/pedidos', async (req, res) => {
  try {
    const { tipo, mesa_numero, nombre_cliente, total, items } = req.body;
    if (!Array.isArray(items) || items.length === 0) return res.status(400).json({ error: 'items requeridos' });
    if (!['mesa', 'barra'].includes(tipo)) return res.status(400).json({ error: 'tipo inválido' });
    if (!total || total <= 0) return res.status(400).json({ error: 'total inválido' });

    const pedido = await prisma.$transaction(async (tx) => {
      const today = new Date(); today.setHours(0, 0, 0, 0);
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
    if (!estado) return res.status(400).json({ error: 'estado requerido' });
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

      const data = { cobrado: true, metodo_pago, estado: 'entregado' };
      if (referencia) data.referencia = referencia;
      if (descuento_pct) data.descuento_pct = descuento_pct;
      if (cliente_id) data.cliente_id = cliente_id;

      const pedido = await tx.pedido.update({
        where: { id: Number(req.params.id) },
        data,
        include: { items: { include: { producto: true } } }
      });
      if (metodo_pago === 'cuenta_corriente' && cliente_id) {
        await tx.cliente.update({ where: { id: cliente_id }, data: { saldo: { increment: pedido.total } } });
      }
      return pedido;
    });
    io.emit('pedido-actualizado', pedido);
    res.json(pedido);
  } catch(e) {
    console.error('Cobro error:', e);
    res.status(e.status || 500).json({ error: e.message });
  }
});

app.post('/api/pedidos/:id/cancelar', async (req, res) => {
  try {
    const updated = await prisma.$transaction(async (tx) => {
      const pedido = await tx.pedido.findUnique({ where: { id: Number(req.params.id) }, include: { items: true } });
      if (!pedido) throw Object.assign(new Error('Pedido no encontrado'), { status: 404 });
      if (pedido.estado === 'cancelado') throw Object.assign(new Error('Pedido ya cancelado'), { status: 409 });

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
    const cierre = await prisma.cierreCaja.create({ data: req.body });
    res.json(cierre);
  } catch(e) { res.status(500).json({ error: e.message }); }
});
app.get('/api/cierres', async (req, res) => {
  try {
    const cierres = await prisma.cierreCaja.findMany({ orderBy: { fecha: 'desc' }, take: 30 });
    res.json(cierres);
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ============================================
// AUTOSERVICIO (pending orders for caja approval)
// ============================================
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
    const fechaStr = fecha.toLocaleDateString('es-AR');
    const horaStr = fecha.toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' });

    let ticket = '';
    ticket += '================================\n';
    ticket += '         CANTINA POS\n';
    ticket += '================================\n';
    ticket += `Fecha: ${fechaStr}  Hora: ${horaStr}\n`;
    ticket += `Pedido: #${String(pedido.numero).padStart(3, '0')}\n`;
    ticket += `Tipo: ${pedido.tipo === 'mesa' ? 'Mesa ' + pedido.mesa_numero : 'Barra'}\n`;
    if (pedido.nombre_cliente) ticket += `Cliente: ${pedido.nombre_cliente}\n`;
    ticket += '--------------------------------\n';

    for (const item of pedido.items) {
      const nombre = item.producto?.nombre || '?';
      const subtotal = item.cantidad * item.precio;
      ticket += `${item.cantidad}x ${nombre}\n`;
      ticket += `   $${item.precio.toLocaleString()} c/u = $${subtotal.toLocaleString()}\n`;
      if (item.observaciones) ticket += `   >> ${item.observaciones}\n`;
    }

    ticket += '--------------------------------\n';
    ticket += `TOTAL: $${pedido.total.toLocaleString()}\n`;

    if (pedido.cobrado) {
      ticket += `Pago: ${pedido.metodo_pago === 'efectivo' ? 'Efectivo' : pedido.metodo_pago === 'transferencia' ? 'Transferencia' : 'Cuenta corriente'}\n`;
      if (pedido.cliente) ticket += `Cliente: ${pedido.cliente.nombre} ${pedido.cliente.apellido || ''}\n`;
    }

    ticket += '================================\n';
    ticket += '       ¡Gracias por su compra!\n';
    ticket += '================================\n';

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
    try {
      const pedido = await prisma.pedido.update({
        where: { id: data.id },
        data: { estado: data.estado }
      });
      io.emit('pedido-actualizado', pedido);
    } catch(e) {
      console.error('Error cambiando estado:', e);
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
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🍽️  Cantina POS corriendo en http://0.0.0.0:${PORT}`);
  console.log(`📊 Sistema: http://0.0.0.0:${PORT}/api/system`);
  console.log(`💚 Health: http://0.0.0.0:${PORT}/api/health`);
});
