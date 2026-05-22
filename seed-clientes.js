const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ datasourceUrl: 'postgresql://cantina:cantina2025@localhost:5432/cantina_pos' });

const nombres = [
  ["Miguel", "Fernández", "Migue", "Planta"],
  ["Laura", "Martínez", "Lau", "Oficina"],
  ["Diego", "Sánchez", "Dieguito", "Depósito"],
  ["Valentina", "Romero", "Vale", "Ventas"],
  ["Martín", "Herrera", "Tín", "Planta"],
  ["Camila", "Torres", "Cami", "Oficina"],
  ["Facundo", "Álvarez", "Facu", "Depósito"],
  ["Luciana", "Acosta", "Lu", "Ventas"],
  ["Nicolás", "Gutiérrez", "Nico", "Planta"],
  ["Florencia", "Castro", "Flor", "Oficina"],
  ["Tomás", "Morales", "Tomy", "Depósito"],
  ["Sofía", "Jiménez", "Sofi", "Ventas"],
  ["Joaquín", "Molina", "Joaco", "Planta"],
  ["Agustina", "Medina", "Agus", "Oficina"],
  ["Matías", "Suárez", "Mati", "Depósito"],
  ["Julieta", "Pereyra", "Juli", "Ventas"],
  ["Ezequiel", "García", "Eze", "Planta"],
  ["Milagros", "Ruiz", "Mili", "Oficina"],
  ["Lautaro", "Flores", "Lauta", "Depósito"],
  ["Candela", "Benítez", "Cande", "Ventas"],
  ["Gonzalo", "Cabrera", "Gonza", "Planta"],
  ["Rocío", "Aguirre", "Ro", "Oficina"],
  ["Sebastián", "Navarro", "Seba", "Depósito"],
  ["Aldana", "Domínguez", "Alda", "Ventas"],
  ["Franco", "Ortiz", "Fran", "Planta"],
  ["Brenda", "Sosa", "Bre", "Oficina"],
  ["Ramiro", "Paz", "Rami", "Depósito"],
  ["Daniela", "Figueroa", "Dani", "Ventas"],
  ["Leandro", "Córdoba", "Lean", "Planta"],
  ["Antonella", "Vega", "Anto", "Oficina"],
  ["Maximiliano", "Luna", "Maxi", "Depósito"],
  ["Carolina", "Ríos", "Caro", "Ventas"],
  ["Iván", "Rojas", "Iva", "Planta"],
  ["Micaela", "Quiroga", "Mica", "Oficina"],
  ["Santiago", "Villalba", "Santi", "Depósito"],
  ["Natalia", "Ramírez", "Nati", "Ventas"],
  ["Pablo", "Ojeda", "Pablito", "Planta"],
];

async function main() {
  for (const [nombre, apellido, apodo, division] of nombres) {
    const exists = await prisma.cliente.findFirst({ where: { nombre, apellido } });
    if (!exists) {
      await prisma.cliente.create({
        data: { nombre, apellido, apodo, division, whatsapp: "381" + Math.floor(Math.random() * 9000000 + 1000000) }
      });
    }
  }
  const count = await prisma.cliente.count();
  console.log("✅ " + count + " clientes en total");
}

main().catch(e => { console.error(e); process.exit(1) }).finally(() => prisma.$disconnect());
