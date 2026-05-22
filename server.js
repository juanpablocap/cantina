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

app.use(cors());
app.use(express.json());
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

    // Printer & scanner detection
    let printerOk = false, scannerOk = false;
    try {
      const lsusb = execSync('lsusb 2>/dev/null', { timeout: 2000 }).toString();
      printerOk = /printer|thermal|receipt|0483|1a86/i.test(lsusb) || fs.existsSync('/dev/usb/lp0');
      scannerOk = /barcode|scanner|hid/i.test(lsusb);
    } catch(e) {}

    res.json({
      cpu: parseInt(cpu) || 0,
      ram: { used: parseInt(ramUsed) || 0, total: parseInt(ramTotal) || 0 },
      disk: { pct: parseInt(diskPct) || 0, used: diskUsed, total: diskTotal },
      temp, uptime, ip, connections: wsConns,
      services: { postgresql: pgOk, api: apiOk, printer: printerOk, scanner: scannerOk },
      lastBackup,
    });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
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
  const users = await prisma.usuario.findMany({ where: { activo: true } });
  res.json(users);
});
app.post('/api/usuarios', async (req, res) => {
  try {
    const user = await prisma.usuario.create({ data: req.body });
    res.json(user);
  } catch(e) { res.status(400).json({ error: e.message }); }
});
app.put('/api/usuarios/:id', async (req, res) => {
  const user = await prisma.usuario.update({ where: { id: Number(req.params.id) }, data: req.body });
  res.json(user);
});
app.delete('/api/usuarios/:id', async (req, res) => {
  await prisma.usuario.update({ where: { id: Number(req.params.id) }, data: { activo: false } });
  res.json({ deleted: true });
});
app.post('/api/login', async (req, res) => {
  const user = await prisma.usuario.findUnique({ where: { pin: req.body.pin } });
  if (user && user.activo) res.json(user);
  else res.status(401).json({ error: 'PIN incorrecto' });
});

// ============================================
// CATEGORIAS
// ============================================
app.get('/api/categorias', async (req, res) => {
  const cats = await prisma.categoria.findMany({ orderBy: { orden: 'asc' } });
  res.json(cats);
});

// ============================================
// PRODUCTOS
// ============================================
app.get('/api/productos', async (req, res) => {
  const prods = await prisma.producto.findMany({ where: { activo: true }, include: { categoria: true } });
  res.json(prods);
});
app.post('/api/productos', async (req, res) => {
  try {
    const prod = await prisma.producto.create({ data: req.body, include: { categoria: true } });
    res.json(prod);
  } catch(e) { res.status(400).json({ error: e.message }); }
});
app.put('/api/productos/:id', async (req, res) => {
  const prod = await prisma.producto.update({ where: { id: Number(req.params.id) }, data: req.body, include: { categoria: true } });
  res.json(prod);
});
app.get('/api/productos/barcode/:code', async (req, res) => {
  const prod = await prisma.producto.findUnique({ where: { codigo: req.params.code }, include: { categoria: true } });
  if (prod) res.json(prod);
  else res.status(404).json({ error: 'No encontrado' });
});

// ============================================
// CLIENTES
// ============================================
app.get('/api/clientes', async (req, res) => {
  const clients = await prisma.cliente.findMany({ where: { activo: true }, include: { pagos: { orderBy: { fecha: 'desc' }, take: 20 } } });
  res.json(clients);
});
app.post('/api/clientes', async (req, res) => {
  try {
    const client = await prisma.cliente.create({ data: { nombre: req.body.nombre, apellido: req.body.apellido || '', apodo: req.body.apodo || '', division: req.body.division || '', whatsapp: req.body.whatsapp || '' } });
    res.json(client);
  } catch(e) { res.status(400).json({ error: e.message }); }
});
app.put('/api/clientes/:id', async (req, res) => {
  const client = await prisma.cliente.update({ where: { id: Number(req.params.id) }, data: req.body });
  res.json(client);
});
app.post('/api/clientes/:id/pago', async (req, res) => {
  const { monto } = req.body;
  const cliente = await prisma.cliente.findUnique({ where: { id: Number(req.params.id) } });
  if (!cliente) return res.status(404).json({ error: 'Cliente no encontrado' });
  await prisma.clientePago.create({ data: { cliente_id: cliente.id, monto } });
  const updated = await prisma.cliente.update({ where: { id: cliente.id }, data: { saldo: Math.max(0, cliente.saldo - monto) } });
  res.json(updated);
});

// ============================================
// PEDIDOS
// ============================================
app.get('/api/pedidos', async (req, res) => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const pedidos = await prisma.pedido.findMany({
    where: { createdAt: { gte: today } },
    include: { items: { include: { producto: true } }, cliente: true },
    orderBy: { createdAt: 'desc' }
  });
  res.json(pedidos);
});

app.get('/api/pedidos/all', async (req, res) => {
  const pedidos = await prisma.pedido.findMany({
    include: { items: { include: { producto: true } }, cliente: true },
    orderBy: { createdAt: 'desc' },
    take: 200,
  });
  res.json(pedidos);
});

app.post('/api/pedidos', async (req, res) => {
  try {
    const { tipo, mesa_numero, nombre_cliente, total, items } = req.body;
    // Get next number for today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const lastPedido = await prisma.pedido.findFirst({ where: { createdAt: { gte: today } }, orderBy: { numero: 'desc' } });
    const numero = (lastPedido?.numero || 0) + 1;

    const pedido = await prisma.pedido.create({
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

    // Descontar stock
    for (const item of items) {
      await prisma.producto.update({
        where: { id: item.producto_id },
        data: { stock: { decrement: item.cantidad } }
      });
    }

    io.emit('nuevo-pedido', pedido);
    res.json(pedido);
  } catch(e) {
    console.error('Error creando pedido:', e);
    res.status(500).json({ error: e.message });
  }
});

app.put('/api/pedidos/:id', async (req, res) => {
  try {
    const pedido = await prisma.pedido.update({
      where: { id: Number(req.params.id) },
      data: req.body,
      include: { items: { include: { producto: true } } }
    });
    io.emit('pedido-actualizado', pedido);
    res.json(pedido);
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/pedidos/:id/cobrar', async (req, res) => {
  const { metodo_pago, referencia, descuento_pct, cliente_id } = req.body;
  const data = { cobrado: true, metodo_pago, estado: 'entregado' };
  if (referencia) data.referencia = referencia;
  if (descuento_pct) data.descuento_pct = descuento_pct;
  if (cliente_id) data.cliente_id = cliente_id;

  try {
    const pedido = await prisma.pedido.update({
      where: { id: Number(req.params.id) },
      data,
      include: { items: { include: { producto: true } } }
    });
    if (metodo_pago === 'cuenta_corriente' && cliente_id) {
      await prisma.cliente.update({
        where: { id: cliente_id },
        data: { saldo: { increment: pedido.total } }
      });
    }
    io.emit('pedido-actualizado', pedido);
    res.json(pedido);
  } catch(e) {
    console.error('Cobro error:', e);
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/pedidos/:id/cancelar', async (req, res) => {
  try {
    const pedido = await prisma.pedido.findUnique({
      where: { id: Number(req.params.id) },
      include: { items: true }
    });
    if (!pedido) return res.status(404).json({ error: 'No encontrado' });

    // Restore stock
    for (const item of pedido.items) {
      await prisma.producto.update({
        where: { id: item.producto_id },
        data: { stock: { increment: item.cantidad } }
      });
    }

    const updated = await prisma.pedido.update({
      where: { id: Number(req.params.id) },
      data: { estado: 'cancelado' }
    });
    io.emit('pedido-actualizado', updated);
    res.json(updated);
  } catch(e) {
    res.status(500).json({ error: e.message });
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
  const cierres = await prisma.cierreCaja.findMany({ orderBy: { fecha: 'desc' }, take: 30 });
  res.json(cierres);
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
  const imgs = await prisma.carouselImage.findMany({ where: { activo: true }, orderBy: { orden: 'asc' } });
  res.json(imgs);
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
