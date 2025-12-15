import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServer } from '@/lib/supabaseserver';
import { prisma } from '@/lib/prisma';
import { generateIdempotencyHash } from '@/lib/utils/idempotency';

const POINTS_PER_TATTOO = 100;

interface CreateTattooBody {
  fotoUrl: string;
  localizacaoCorpo: string;
  dataAproximada?: string;
  significado?: string;
}

export async function GET(request: NextRequest) {
  try {
    const supabase = await createSupabaseServer();
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Não autenticado' },
        { status: 401 }
      );
    }

    const tattoos = await prisma.tattoo.findMany({
      where: {
        userId: user.id,
      },
      orderBy: {
        dataCriacao: 'desc',
      },
      select: {
        id: true,
        fotoUrl: true,
        localizacaoCorpo: true,
        dataAproximada: true,
        significado: true,
        dataCriacao: true,
        dataAtualizacao: true,
      },
    });

    return NextResponse.json({
      tattoos,
      total: tattoos.length,
    });

  } catch (error) {
    console.error('Erro ao listar tattoos:', error);
    return NextResponse.json(
      { error: 'Erro interno do servidor' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const supabase = await createSupabaseServer();
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Não autenticado' },
        { status: 401 }
      );
    }

    const body: CreateTattooBody = await request.json();

    if (!body.fotoUrl || !body.localizacaoCorpo) {
      return NextResponse.json(
        { error: 'fotoUrl e localizacaoCorpo são obrigatórios' },
        { status: 400 }
      );
    }

    const dataAproximada = body.dataAproximada 
      ? new Date(body.dataAproximada) 
      : null;

    const idempotencyHash = generateIdempotencyHash(
      user.id,
      body.localizacaoCorpo,
      dataAproximada
    );

    const existingTattoo = await prisma.tattoo.findFirst({
      where: {
        userId: user.id,
        idempotencyHash: idempotencyHash,
      },
    });

    if (existingTattoo) {
      const userRecord = await prisma.user.findUnique({
        where: { id: user.id },
        select: { xpTotal: true },
      });

      return NextResponse.json({
        tattoo_id: existingTattoo.id,
        points_awarded: 0,
        xp_total: userRecord?.xpTotal || 0,
        is_duplicate: true,
      });
    }

    const result = await prisma.$transaction(async (tx) => {
      const tattoo = await tx.tattoo.create({
        data: {
          userId: user.id,
          fotoUrl: body.fotoUrl,
          localizacaoCorpo: body.localizacaoCorpo,
          dataAproximada: dataAproximada,
          significado: body.significado || null,
          idempotencyHash: idempotencyHash,
        },
      });

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: {
          xpTotal: {
            increment: POINTS_PER_TATTOO,
          },
        },
        select: { xpTotal: true },
      });

      await tx.pontosTransacao.create({
        data: {
          userId: user.id,
          tipoAcao: 'registro_tattoo',
          quantidade: POINTS_PER_TATTOO,
          descricao: `Pontos por registrar tattoo em ${body.localizacaoCorpo}`,
          tattooIdRef: tattoo.id,
        },
      });

      return {
        tattoo,
        xpTotal: updatedUser.xpTotal,
      };
    });

    return NextResponse.json({
      tattoo_id: result.tattoo.id,
      points_awarded: POINTS_PER_TATTOO,
      xp_total: result.xpTotal,
      is_duplicate: false,
    });

  } catch (error) {
    console.error('Erro ao criar tattoo:', error);
    return NextResponse.json(
      { error: 'Erro interno do servidor' },
      { status: 500 }
    );
  }
}
