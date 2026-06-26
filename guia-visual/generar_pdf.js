const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const CHROMIUM = '/snap/bin/chromium';
const SCREENSHOTS = path.join(__dirname, 'screenshots');
const OUT_PDF = path.join(__dirname, 'guia_cantina_pos.pdf');

const IP = '&lt;IP-DEL-SERVIDOR&gt;'; // placeholder genérico — reemplazar según instalación

function imgBase64(filename) {
  const data = fs.readFileSync(path.join(SCREENSHOTS, filename));
  return 'data:image/png;base64,' + data.toString('base64');
}

const secciones = [
  {
    titulo: 'Acceso al sistema',
    subtitulo: 'http://${IP}/ — Pantalla de inicio',
    imagen: '01_login.png',
    pasos: [
      'Abrir el navegador y escribir la dirección: <strong>http://${IP}/</strong>',
      'Ingresar el PIN de 4 dígitos según el rol (cajero, admin, cocina)',
      'El sistema reconoce el usuario automáticamente',
    ],
    nota: null,
  },
  {
    titulo: 'Pantalla Venta',
    subtitulo: 'http://${IP}/ — Tab Venta',
    imagen: '02_venta.png',
    pasos: [
      'Tocar los productos del menú para agregarlos al carrito (derecha)',
      'Elegir destino: <strong>Mesa</strong> (seleccionar número) o <strong>Barra</strong>',
      'Revisar el total y tocar <strong>ENVIAR A COCINA</strong>',
      'Si son solo bebidas: tocar <strong>DESPACHAR Y COBRAR</strong> directamente',
    ],
    nota: 'Los productos con "SIN STOCK" se muestran en rojo — se pueden agregar igual.',
  },
  {
    titulo: 'Pantalla Pedidos',
    subtitulo: 'http://${IP}/ — Tab Pedidos',
    imagen: '03_pedidos.png',
    pasos: [
      'Ver todos los pedidos activos agrupados por estado',
      'Tocar <strong>💰 Cobrar</strong> cuando el pedido está Listo o Entregado',
      'Tocar <strong>✏️</strong> para editar un pedido ya enviado a cocina',
      'Tocar <strong>❌</strong> para cancelar (requiere PIN de autorización)',
    ],
    nota: null,
  },
  {
    titulo: 'Pantalla Mesas',
    subtitulo: 'http://${IP}/ — Tab Mesas',
    imagen: '04_mesas.png',
    pasos: [
      'Ver de un vistazo qué mesas están ocupadas (borde naranja = pedidos activos)',
      'Tocar una mesa para ver sus pedidos y cobrar',
      'Asignar mozo a la mesa desde el detalle',
    ],
    nota: null,
  },
  {
    titulo: 'Caja — Resumen del día',
    subtitulo: 'http://${IP}/ — Tab Caja › Hoy',
    imagen: '05_caja_hoy.png',
    pasos: [
      'Ver el total recaudado en el día por método de pago',
      'Ingresar el efectivo contado en el arqueo',
      'Tocar <strong>Cerrar Caja</strong> al finalizar el turno',
    ],
    nota: null,
  },
  {
    titulo: 'Caja — Historial de cierres',
    subtitulo: 'http://${IP}/ — Tab Caja › Historial',
    imagen: '06_caja_historial.png',
    pasos: [
      'Consultar cualquier cierre anterior',
      'Tocar <strong>Ver</strong> para ver el detalle de productos vendidos',
      'Tocar <strong>Descargar</strong> para guardar el resumen en .txt',
    ],
    nota: null,
  },
  {
    titulo: 'Caja — Estadísticas',
    subtitulo: 'http://${IP}/ — Tab Caja › Estadísticas',
    imagenes: [
      { archivo: '07a_estadisticas_hoy.png',        label: 'Hoy' },
      { archivo: '07b_estadisticas_semana.png',     label: 'Esta semana' },
      { archivo: '07c_estadisticas_mes.png',        label: 'Este mes' },
      { archivo: '07d_estadisticas_ultimo_mes.png', label: 'Último mes' },
      { archivo: '07e_estadisticas_todo.png',       label: 'Todo el período' },
    ],
    pasos: [
      'Seleccionar el rango en la barra superior: Hoy / Esta semana / Este mes / Último mes / Todo',
      'Ver el gráfico de torta con los productos más vendidos (TOP 8)',
      'Consultar el ranking por ganancia con cantidad y porcentaje de ingreso',
      'Métricas clave: total ventas, ticket promedio, total pedidos, horario pico',
    ],
    nota: null,
  },
  {
    titulo: 'Administrar Productos',
    subtitulo: 'http://${IP}/ — Más › Productos',
    imagen: '08_productos.png',
    pasos: [
      'Tocar <strong>+ Nuevo Producto</strong> para agregar un ítem al menú',
      'Tocar <strong>✏️</strong> para editar precio, stock o nombre',
      'Gestionar categorías con <strong>+ Nueva Categoría</strong>',
      'Indicar si el producto va a cocina o es despacho directo (bebidas)',
    ],
    nota: null,
  },
  {
    titulo: 'Clientes con Cuenta Corriente',
    subtitulo: 'http://${IP}/ — Más › Clientes',
    imagen: '09_clientes.png',
    pasos: [
      'Ver el saldo de cada cliente en la lista',
      'Al cobrar un pedido en <strong>Fiado</strong>, el saldo se acumula automáticamente',
      'Tocar un cliente → <strong>Registrar Pago</strong> para saldar deuda',
    ],
    nota: null,
  },
  {
    titulo: 'Sistema y Monitoreo',
    subtitulo: 'http://${IP}/ — Más › Sistema',
    imagen: '10_sistema.png',
    pasos: [
      'Ver estado de servicios (PostgreSQL, API, Frontend)',
      'Monitorear CPU, RAM, disco y red en tiempo real con gráficos',
      'Hacer backup de la base de datos con un toque',
      'Gestionar imágenes del carrusel de TV (importar desde pendrive)',
      'Reiniciar o apagar el servidor desde los botones de la parte inferior',
    ],
    nota: 'Para monitoreo avanzado: tocar el botón 📊 Monitor — abre <strong>http://${IP}/monitor/</strong> (Netdata).',
  },
  {
    titulo: 'Pantalla Cocina',
    subtitulo: 'http://${IP}/cocina.html',
    imagen: '11_cocina.png',
    pasos: [
      'Abrir en el navegador: <strong>http://${IP}/cocina.html</strong>',
      '<strong>Borde rojo pulsando</strong>: pedido nuevo — pendiente de preparar',
      'Tocar <strong>🔥 EMPEZAR A PREPARAR</strong> para indicar que está en proceso',
      'Tocar <strong>✅ LISTO PARA ENTREGAR</strong> cuando esté terminado',
      'Tocar <strong>📦 ENTREGADO</strong> para sacarlo de la pantalla',
    ],
    nota: 'Si un pedido fue modificado desde caja, aparece el banner azul ✏️ PEDIDO MODIFICADO — tocar ✓ VISTO para confirmar.',
  },
  {
    titulo: 'Autoservicio (Kiosko)',
    subtitulo: 'http://${IP}/autoservicio.html',
    imagen: '12_autoservicio.png',
    pasos: [
      'Abrir en el navegador: <strong>http://${IP}/autoservicio.html</strong>',
      'El cliente elige productos tocando las cards',
      'Completa su nombre y envía el pedido',
      'El pedido llega automáticamente a la pantalla de cocina',
    ],
    nota: 'Esta pantalla está pensada para una tablet en el mostrador que usen los propios clientes.',
  },
  {
    titulo: 'TV Promociones',
    subtitulo: 'http://${IP}/promo.html',
    imagen: '13_promo_tv.png',
    pasos: [
      'Abrir en el navegador del TV: <strong>http://${IP}/promo.html</strong>',
      'Las imágenes rotan automáticamente cada 8 segundos',
      'Para cargar nuevas imágenes: ir a <strong>http://${IP}/</strong> → Sistema → importar desde pendrive',
      'El TV se actualiza solo en menos de 30 segundos',
    ],
    nota: 'El TV debe tener abierta la página <strong>http://${IP}/promo.html</strong> en pantalla completa.',
  },
].map(s => ({
  ...s,
  subtitulo: s.subtitulo.replace(/\$\{IP\}/g, IP),
  pasos: s.pasos.map(p => p.replace(/\$\{IP\}/g, IP)),
  nota: s.nota ? s.nota.replace(/\$\{IP\}/g, IP) : null,
}));

function buildHTML() {
  const seccionesHTML = secciones.map((s, i) => {
    const imagenesHTML = s.imagenes
      ? s.imagenes.map(img => `
        <div class="img-bloque">
          <div class="img-label">${img.label}</div>
          <img src="${imgBase64(img.archivo)}" alt="${img.label}" />
        </div>`).join('\n')
      : `<img src="${imgBase64(s.imagen)}" alt="${s.titulo}" />`;

    return `
    <div class="seccion ${i > 0 ? 'page-break' : ''}">
      <div class="seccion-header">
        <span class="numero">${String(i + 1).padStart(2, '0')}</span>
        <div>
          <h2>${s.titulo}</h2>
          <p class="subtitulo">${s.subtitulo}</p>
        </div>
      </div>
      ${imagenesHTML}
      <div class="pasos">
        <h3>Cómo usarlo</h3>
        <ol>
          ${s.pasos.map(p => `<li>${p}</li>`).join('\n          ')}
        </ol>
        ${s.nota ? `<div class="nota">💡 ${s.nota}</div>` : ''}
      </div>
    </div>`;
  }).join('\n');

  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Segoe UI', Arial, sans-serif; color: #1a1a2e; background: white; }

  /* Portada */
  .portada {
    height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #070A12 0%, #1a1a3e 100%);
    color: white;
    text-align: center;
    padding: 60px;
  }
  .portada .logo { font-size: 72px; margin-bottom: 24px; }
  .portada h1 { font-size: 48px; font-weight: 800; letter-spacing: -1px; margin-bottom: 12px; }
  .portada .bajada { font-size: 20px; color: #a5b4fc; margin-bottom: 48px; }
  .portada .meta { font-size: 14px; color: #64748b; }
  .portada .chips { display: flex; gap: 12px; justify-content: center; margin-bottom: 48px; flex-wrap: wrap; }
  .portada .chip { background: #6366f120; border: 1px solid #6366f140; color: #a5b4fc; padding: 6px 16px; border-radius: 20px; font-size: 14px; }

  /* Índice */
  .indice { padding: 60px; page-break-after: always; }
  .indice h2 { font-size: 28px; font-weight: 700; margin-bottom: 32px; color: #1a1a2e; border-bottom: 3px solid #6366f1; padding-bottom: 12px; }
  .indice-lista { list-style: none; display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
  .indice-lista li { display: flex; align-items: center; gap: 12px; padding: 12px 16px; border-radius: 8px; background: #f8fafc; border-left: 3px solid #6366f1; }
  .indice-lista .num { font-size: 13px; font-weight: 800; color: #6366f1; min-width: 24px; }
  .indice-lista .nom { font-size: 15px; color: #334155; }

  /* Secciones */
  .seccion { padding: 48px 60px; }
  .page-break { page-break-before: always; }
  .seccion-header { display: flex; align-items: flex-start; gap: 20px; margin-bottom: 28px; }
  .numero { font-size: 48px; font-weight: 900; color: #e2e8f0; line-height: 1; min-width: 56px; }
  .seccion-header h2 { font-size: 26px; font-weight: 700; color: #1a1a2e; margin-bottom: 4px; }
  .subtitulo { font-size: 13px; color: #64748b; font-family: monospace; }
  .seccion img { width: 100%; border-radius: 12px; border: 1px solid #e2e8f0; box-shadow: 0 4px 20px rgba(0,0,0,0.1); margin-bottom: 28px; }
  .img-bloque { margin-bottom: 32px; }
  .img-label { display: inline-block; background: #E07A5F; color: white; font-size: 12px; font-weight: 700; padding: 4px 12px; border-radius: 6px; margin-bottom: 8px; letter-spacing: 0.5px; text-transform: uppercase; }
  .img-bloque img { margin-bottom: 0; }
  .pasos h3 { font-size: 14px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: #6366f1; margin-bottom: 12px; }
  .pasos ol { padding-left: 20px; }
  .pasos ol li { font-size: 15px; line-height: 1.7; color: #334155; margin-bottom: 4px; }
  .nota { margin-top: 16px; padding: 12px 16px; background: #fefce8; border-left: 3px solid #fbbf24; border-radius: 6px; font-size: 14px; color: #78350f; }

  /* Pie */
  .pie { padding: 40px 60px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; page-break-before: always; }
</style>
</head>
<body>

<!-- PORTADA -->
<div class="portada">
  <div class="logo">🍽️</div>
  <h1>Cantina POS</h1>
  <p class="bajada">Guía de uso para el personal</p>
  <div class="chips">
    <span class="chip">📱 Pantalla táctil</span>
    <span class="chip">🌐 http://&lt;IP-DEL-SERVIDOR&gt;/</span>
    <span class="chip">📅 Junio 2026</span>
  </div>
  <p class="meta">Sistema de Punto de Venta — Cantina Corporativa</p>
</div>

<!-- ÍNDICE -->
<div class="indice">
  <h2>Contenido</h2>
  <ul class="indice-lista">
    ${secciones.map((s, i) => `
    <li>
      <span class="num">${String(i + 1).padStart(2, '0')}</span>
      <span class="nom">${s.titulo}</span>
    </li>`).join('')}
  </ul>
</div>

<!-- SECCIONES -->
${seccionesHTML}

<!-- PIE -->
<div class="pie">
  <p>Cantina POS — Sistema offline/LAN · Servidor: ${IP} · Problemas: ver RECOVERY.md o llamar al técnico</p>
</div>

</body>
</html>`;
}

(async () => {
  console.log('Generando HTML...');
  const html = buildHTML();
  fs.writeFileSync(path.join(__dirname, 'guia_cantina_pos.html'), html);
  console.log('  ✓ HTML generado');

  console.log('Convirtiendo a PDF con Chromium...');
  const browser = await puppeteer.launch({
    executablePath: CHROMIUM,
    headless: true,
    args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage'],
  });
  const page = await browser.newPage();
  await page.goto('file://' + path.join(__dirname, 'guia_cantina_pos.html'), { waitUntil: 'networkidle0', timeout: 60000 });
  await page.pdf({
    path: OUT_PDF,
    format: 'A4',
    printBackground: true,
    margin: { top: '0', right: '0', bottom: '0', left: '0' },
  });
  await browser.close();

  const size = (fs.statSync(OUT_PDF).size / 1024 / 1024).toFixed(1);
  console.log(`  ✓ PDF generado: guia_cantina_pos.pdf (${size} MB)`);
  console.log('\nPara descargar desde tu PC:');
  console.log('  scp cantina@192.168.100.54:/home/cantina/cantina-pos/guia-visual/guia_cantina_pos.pdf .');
})().catch(e => { console.error('Error:', e.message); process.exit(1); });
