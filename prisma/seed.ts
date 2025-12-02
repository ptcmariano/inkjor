import { PrismaClient } from '@prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'
import { Pool } from 'pg'
import dotenv from 'dotenv'

dotenv.config()

const connectionString = process.env.DIRECT_URL || process.env.DATABASE_URL

const pool = new Pool({ connectionString })
const adapter = new PrismaPg(pool)
const prisma = new PrismaClient({ adapter })

async function main() {
    console.log('Start seeding ...')

    // 1. Create Users
    const user1 = await prisma.user.upsert({
        where: { email: 'alice@example.com' },
        update: {},
        create: {
            id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
            email: 'alice@example.com',
            nome: 'Alice Wonderland',
            foto: 'https://i.pravatar.cc/150?u=alice',
            nivel: 2,
            xpTotal: 1500,
            creditos: {
                create: {
                    saldo: 100.00
                }
            }
        },
    })

    const user2 = await prisma.user.upsert({
        where: { email: 'bob@example.com' },
        update: {},
        create: {
            id: 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
            email: 'bob@example.com',
            nome: 'Bob Builder',
            foto: 'https://i.pravatar.cc/150?u=bob',
            nivel: 1,
            xpTotal: 500,
            creditos: {
                create: {
                    saldo: 50.00
                }
            }
        },
    })

    console.log({ user1, user2 })

    // 2. Create Parceiros
    const parceiro1 = await prisma.parceiro.create({
        data: {
            nome: 'Tattoo Studio X',
            tipo: 'Studio',
            logoUrl: 'https://placehold.co/200x200?text=StudioX',
            descricao: 'O melhor estúdio da cidade.',
            contato: 'contato@studioc.com'
        }
    })

    console.log({ parceiro1 })

    // 3. Create Recompensas
    const recompensa1 = await prisma.recompensa.create({
        data: {
            nome: 'Desconto de 10%',
            descricao: '10% de desconto na sua próxima tattoo.',
            tipo: 'Desconto',
            custoPontos: 500,
            parceiroId: parceiro1.id,
            estoque: 100
        }
    })

    console.log({ recompensa1 })

    // 4. Create Missoes
    const missao1 = await prisma.missao.create({
        data: {
            nome: 'Primeira Tattoo',
            descricao: 'Registre sua primeira tattoo no app.',
            tipoAcao: 'REGISTRAR_TATTOO',
            quantidadeRequerida: 1,
            recompensaPontos: 100,
            dataInicio: new Date(),
        }
    })

    console.log({ missao1 })

    // 5. Create Tattoos for User 1
    const tattoo1 = await prisma.tattoo.create({
        data: {
            userId: user1.id,
            fotoUrl: 'https://placehold.co/300x400?text=Tattoo1',
            localizacaoCorpo: 'Braço Esquerdo',
            significado: 'Lembrança de viagem',
            dataAproximada: new Date('2023-01-15')
        }
    })

    console.log({ tattoo1 })

    // 6. Create PontosTransacao
    const pontos1 = await prisma.pontosTransacao.create({
        data: {
            userId: user1.id,
            tipoAcao: 'REGISTRO_TATTOO',
            quantidade: 100,
            descricao: 'Pontos por registrar tattoo',
            tattooIdRef: tattoo1.id
        }
    })

    console.log({ pontos1 })

    // 7. Create CreditoTransacao
    const creditoTransacao1 = await prisma.creditoTransacao.create({
        data: {
            userId: user1.id,
            tipo: 'COMPRA',
            valor: 50.00,
            metodoPagamento: 'PIX',
            status: 'concluido'
        }
    })

    console.log({ creditoTransacao1 })

    // 8. Create MetricaDiaria
    const metrica1 = await prisma.metricaDiaria.create({
        data: {
            data: new Date(),
            totalUsuariosAtivos: 2,
            totalPontosDistribuidos: 100,
            totalRecompensasResgatadas: 0,
            totalTattoosRegistradas: 1,
            totalCreditosAdquiridos: 50.00,
            totalMissoesConcluidas: 0
        }
    })

    console.log({ metrica1 })

    console.log('Seeding finished.')
}

main()
    .then(async () => {
        await prisma.$disconnect()
    })
    .catch(async (e) => {
        console.error(e)
        await prisma.$disconnect()
        process.exit(1)
    })
