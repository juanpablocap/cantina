const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const OUT_DIR = path.join(__dirname, 'screenshots');
fs.mkdirSync(OUT_DIR, { recursive: true });

const CHROMIUM = '/snap/bin/chromium';
const BASE = 'http://localhost';
const PIN = '0000';

async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function screenshot(page, name) {
  await sleep(1500);
  await page.screenshot({ path: path.join(OUT_DIR, name), type: 'png' });
  console.log(`  ✓ ${name}`);
}

async function clickText(page, text) {
  await page.evaluate((t) => {
    const el = [...document.querySelectorAll('button, div')]
      .find(e => e.textContent.trim() === t);
    if (el) el.click();
  }, text);
}

async function clickContains(page, text) {
  await page.evaluate((t) => {
    const el = [...document.querySelectorAll('button')]
      .find(e => e.textContent.includes(t));
    if (el) el.click();
  }, text);
}

(async () => {
  console.log('Iniciando Chromium...');
  const browser = await puppeteer.launch({
    executablePath: CHROMIUM,
    headless: true,
    args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1280,800'],
    defaultViewport: { width: 1280, height: 800 },
  });

  const page = await browser.newPage();

  // ── 1. Login ────────────────────────────────────────────────────────────────
  console.log('\n[1] Login...');
  await page.goto(BASE, { waitUntil: 'networkidle2' });
  await screenshot(page, '01_login.png');

  // Ingresar PIN: 0000
  for (const digit of PIN) {
    await clickText(page, digit);
    await sleep(200);
  }
  await sleep(2500);
  // Cambiar a tema classic
  await page.evaluate(() => localStorage.setItem('posTheme', 'classic'));
  await page.reload({ waitUntil: 'networkidle2' });
  // Re-login tras reload
  for (const digit of PIN) {
    await clickText(page, digit);
    await sleep(200);
  }
  await sleep(2000);
  await screenshot(page, '02_venta.png');
  console.log('  Login OK — tema classic');

  // ── 2. Tab Pedidos ───────────────────────────────────────────────────────────
  console.log('\n[2] Pedidos...');
  await clickContains(page, 'Pedidos');
  await screenshot(page, '03_pedidos.png');

  // ── 3. Tab Mesas ─────────────────────────────────────────────────────────────
  console.log('\n[3] Mesas...');
  await clickContains(page, 'Mesas');
  await screenshot(page, '04_mesas.png');

  // ── 4. Tab Caja ──────────────────────────────────────────────────────────────
  console.log('\n[4] Caja...');
  await clickContains(page, 'Caja');
  await screenshot(page, '05_caja_hoy.png');

  await page.evaluate(() => {
    [...document.querySelectorAll('button')].find(b => b.textContent.trim() === 'Historial')?.click();
  });
  await screenshot(page, '06_caja_historial.png');

  // Estadísticas — captura por cada rango
  console.log('\n[4b] Estadísticas por rango...');
  await page.evaluate(() => {
    [...document.querySelectorAll('button')].find(b => b.textContent.trim() === 'Estadísticas')?.click();
  });
  await sleep(2000);
  await screenshot(page, '07a_estadisticas_hoy.png');

  for (const [label, filename] of [
    ['Esta semana', '07b_estadisticas_semana.png'],
    ['Este mes',    '07c_estadisticas_mes.png'],
    ['Último mes',  '07d_estadisticas_ultimo_mes.png'],
    ['Todo',        '07e_estadisticas_todo.png'],
  ]) {
    await page.evaluate((t) => {
      [...document.querySelectorAll('button')].find(b => b.textContent.trim() === t)?.click();
    }, label);
    await sleep(2000);
    await screenshot(page, filename);
  }

  // ── 5. Drawer Más → Productos ────────────────────────────────────────────────
  console.log('\n[5] Productos...');
  await clickContains(page, 'Más');
  await sleep(600);
  await clickContains(page, 'Productos');
  await screenshot(page, '08_productos.png');

  // ── 6. Drawer Más → Clientes ─────────────────────────────────────────────────
  console.log('\n[6] Clientes...');
  await clickContains(page, 'Más');
  await sleep(600);
  await clickContains(page, 'Clientes');
  await screenshot(page, '09_clientes.png');

  // ── 7. Drawer Más → Sistema ──────────────────────────────────────────────────
  console.log('\n[7] Sistema...');
  await clickContains(page, 'Más');
  await sleep(600);
  await clickContains(page, 'Sistema');
  await sleep(2500); // esperar sparklines
  await screenshot(page, '10_sistema.png');

  // ── 8. Cocina ────────────────────────────────────────────────────────────────
  console.log('\n[8] Cocina...');
  await page.goto(`${BASE}/cocina.html`, { waitUntil: 'networkidle2' });
  await screenshot(page, '11_cocina.png');

  // ── 9. Autoservicio ──────────────────────────────────────────────────────────
  console.log('\n[9] Autoservicio...');
  await page.goto(`${BASE}/autoservicio.html`, { waitUntil: 'networkidle2' });
  await screenshot(page, '12_autoservicio.png');

  // ── 10. TV Promo ─────────────────────────────────────────────────────────────
  console.log('\n[10] TV Promo...');
  await page.goto(`${BASE}/promo.html`, { waitUntil: 'networkidle2' });
  await screenshot(page, '13_promo_tv.png');

  await browser.close();

  const files = fs.readdirSync(OUT_DIR).filter(f => f.endsWith('.png'));
  console.log(`\n✅ Listo — ${files.length} capturas en guia-visual/screenshots/`);
})().catch(e => { console.error('Error:', e.message); process.exit(1); });
