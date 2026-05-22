const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

async function main() {
  // Usuarios
  await prisma.usuario.createMany({ data: [
    { nombre: "Admin", rol: "admin", pin: "0000" },
    { nombre: "Cajero", rol: "cajero", pin: "1234" },
    { nombre: "Cocina", rol: "cocina", pin: "5678" },
  ]})

  // Categorias
  const platos = await prisma.categoria.create({ data: { nombre: "Platos", emoji: "🍽️", color: "#E07A5F", despacho_directo: false, orden: 1 }})
  const bebidas = await prisma.categoria.create({ data: { nombre: "Bebidas", emoji: "🍺", color: "#6C9BCF", despacho_directo: true, orden: 2 }})
  const cafe = await prisma.categoria.create({ data: { nombre: "Cafetería", emoji: "☕", color: "#C4956A", despacho_directo: false, orden: 3 }})
  const postres = await prisma.categoria.create({ data: { nombre: "Postres", emoji: "🍰", color: "#D4A5D0", despacho_directo: false, orden: 4 }})

  // Productos
  await prisma.producto.createMany({ data: [
    { nombre: "Milanesa napolitana", precio: 8500, stock: 20, stock_min: 5, cat_id: platos.id },
    { nombre: "Hamburguesa completa", precio: 7000, stock: 20, stock_min: 5, cat_id: platos.id },
    { nombre: "Lomo completo", precio: 9500, stock: 15, stock_min: 3, cat_id: platos.id },
    { nombre: "Suprema a caballo", precio: 8000, stock: 15, stock_min: 5, cat_id: platos.id },
    { nombre: "Empanadas x6", precio: 5500, stock: 30, stock_min: 10, cat_id: platos.id },
    { nombre: "Pizza muzzarella", precio: 7500, stock: 10, stock_min: 3, cat_id: platos.id },
    { nombre: "Papas fritas", precio: 3500, stock: 30, stock_min: 5, cat_id: platos.id },
    { nombre: "Coca Cola 500ml", precio: 2000, stock: 50, stock_min: 10, cat_id: bebidas.id },
    { nombre: "Agua mineral", precio: 1500, stock: 50, stock_min: 10, cat_id: bebidas.id },
    { nombre: "Cerveza Quilmes", precio: 2500, stock: 30, stock_min: 8, cat_id: bebidas.id },
    { nombre: "Fernet con Coca", precio: 4500, stock: 20, stock_min: 5, cat_id: bebidas.id, cocina: true },
    { nombre: "Café cortado", precio: 2000, stock: 99, stock_min: 10, cat_id: cafe.id },
    { nombre: "Café doble", precio: 2500, stock: 99, stock_min: 10, cat_id: cafe.id },
    { nombre: "Submarino", precio: 3000, stock: 30, stock_min: 5, cat_id: cafe.id },
    { nombre: "Flan con dulce", precio: 4000, stock: 15, stock_min: 5, cat_id: postres.id },
    { nombre: "Brownie", precio: 3500, stock: 15, stock_min: 3, cat_id: postres.id },
  ]})

  // Clientes
  await prisma.cliente.createMany({ data: [
    { nombre: "Carlos", apellido: "González", apodo: "Carlitos", division: "Planta", whatsapp: "3814001234" },
    { nombre: "María", apellido: "López", apodo: "Mari", division: "Oficina", whatsapp: "3814005678" },
    { nombre: "Roberto", apellido: "Díaz", apodo: "Beto", division: "Depósito", whatsapp: "3814009012" },
  ]})

  console.log("✅ Datos iniciales cargados")
}

main().catch(e => { console.error(e); process.exit(1) }).finally(() => prisma.$disconnect())
