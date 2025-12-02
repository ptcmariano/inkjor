-- CreateTable
CREATE TABLE "tattoos" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "foto_url" TEXT NOT NULL,
    "localizacao_corpo" TEXT NOT NULL,
    "data_aproximada" TIMESTAMP(3),
    "significado" TEXT,
    "data_criacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "data_atualizacao" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tattoos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pontos_transacoes" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "tipo_acao" TEXT NOT NULL,
    "quantidade" INTEGER NOT NULL,
    "descricao" TEXT,
    "data_hora" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "tattoo_id_ref" UUID,

    CONSTRAINT "pontos_transacoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "parceiros" (
    "id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "tipo" TEXT NOT NULL,
    "logo_url" TEXT,
    "descricao" TEXT,
    "contato" TEXT,
    "data_criacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "parceiros_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recompensas" (
    "id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "descricao" TEXT,
    "tipo" TEXT NOT NULL,
    "custo_pontos" INTEGER NOT NULL,
    "parceiro_id" UUID NOT NULL,
    "estoque" INTEGER NOT NULL DEFAULT 0,
    "data_criacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ativa" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "recompensas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recompensas_usuario" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "recompensa_id" UUID NOT NULL,
    "data_resgate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" TEXT NOT NULL DEFAULT 'pendente',
    "codigo_voucher" TEXT,
    "data_expiracao" TIMESTAMP(3),

    CONSTRAINT "recompensas_usuario_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "creditos" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "saldo" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "data_atualizacao" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "creditos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "creditos_transacoes" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "tipo" TEXT NOT NULL,
    "valor" DECIMAL(10,2) NOT NULL,
    "metodo_pagamento" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pendente',
    "data_hora" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "creditos_transacoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "missoes" (
    "id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "descricao" TEXT,
    "tipo_acao" TEXT NOT NULL,
    "quantidade_requerida" INTEGER NOT NULL,
    "recompensa_pontos" INTEGER NOT NULL,
    "data_inicio" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "data_fim" TIMESTAMP(3),
    "ativa" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "missoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "missoes_usuario" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "missao_id" UUID NOT NULL,
    "progresso" INTEGER NOT NULL DEFAULT 0,
    "data_inicio" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "data_conclusao" TIMESTAMP(3),
    "status" TEXT NOT NULL DEFAULT 'em_progresso',

    CONSTRAINT "missoes_usuario_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "campanhas_patrocinadas" (
    "id" UUID NOT NULL,
    "parceiro_id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "descricao" TEXT,
    "data_inicio" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "data_fim" TIMESTAMP(3),
    "ativa" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "campanhas_patrocinadas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "metricas_diarias" (
    "id" UUID NOT NULL,
    "data" DATE NOT NULL,
    "total_usuarios_ativos" INTEGER NOT NULL DEFAULT 0,
    "total_pontos_distribuidos" INTEGER NOT NULL DEFAULT 0,
    "total_recompensas_resgatadas" INTEGER NOT NULL DEFAULT 0,
    "total_tattoos_registradas" INTEGER NOT NULL DEFAULT 0,
    "total_creditos_adquiridos" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "total_missoes_concluidas" INTEGER NOT NULL DEFAULT 0,
    "data_criacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "metricas_diarias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "_CampanhaMissoes" (
    "campanha" UUID NOT NULL,
    "missao" UUID NOT NULL,

    CONSTRAINT "_CampanhaMissoes_pkey" PRIMARY KEY ("campanha","missao")
);

-- CreateIndex
CREATE INDEX "tattoos_user_id_idx" ON "tattoos"("user_id");

-- CreateIndex
CREATE INDEX "tattoos_data_criacao_idx" ON "tattoos"("data_criacao");

-- CreateIndex
CREATE INDEX "pontos_transacoes_user_id_idx" ON "pontos_transacoes"("user_id");

-- CreateIndex
CREATE INDEX "pontos_transacoes_data_hora_idx" ON "pontos_transacoes"("data_hora");

-- CreateIndex
CREATE INDEX "pontos_transacoes_tipo_acao_idx" ON "pontos_transacoes"("tipo_acao");

-- CreateIndex
CREATE INDEX "parceiros_tipo_idx" ON "parceiros"("tipo");

-- CreateIndex
CREATE INDEX "recompensas_ativa_idx" ON "recompensas"("ativa");

-- CreateIndex
CREATE INDEX "recompensas_tipo_idx" ON "recompensas"("tipo");

-- CreateIndex
CREATE INDEX "recompensas_parceiro_id_idx" ON "recompensas"("parceiro_id");

-- CreateIndex
CREATE UNIQUE INDEX "recompensas_usuario_codigo_voucher_key" ON "recompensas_usuario"("codigo_voucher");

-- CreateIndex
CREATE INDEX "recompensas_usuario_user_id_idx" ON "recompensas_usuario"("user_id");

-- CreateIndex
CREATE INDEX "recompensas_usuario_recompensa_id_idx" ON "recompensas_usuario"("recompensa_id");

-- CreateIndex
CREATE INDEX "recompensas_usuario_status_idx" ON "recompensas_usuario"("status");

-- CreateIndex
CREATE INDEX "recompensas_usuario_data_resgate_idx" ON "recompensas_usuario"("data_resgate");

-- CreateIndex
CREATE UNIQUE INDEX "creditos_user_id_key" ON "creditos"("user_id");

-- CreateIndex
CREATE INDEX "creditos_user_id_idx" ON "creditos"("user_id");

-- CreateIndex
CREATE INDEX "creditos_transacoes_user_id_idx" ON "creditos_transacoes"("user_id");

-- CreateIndex
CREATE INDEX "creditos_transacoes_status_idx" ON "creditos_transacoes"("status");

-- CreateIndex
CREATE INDEX "creditos_transacoes_data_hora_idx" ON "creditos_transacoes"("data_hora");

-- CreateIndex
CREATE INDEX "creditos_transacoes_tipo_idx" ON "creditos_transacoes"("tipo");

-- CreateIndex
CREATE INDEX "missoes_ativa_idx" ON "missoes"("ativa");

-- CreateIndex
CREATE INDEX "missoes_tipo_acao_idx" ON "missoes"("tipo_acao");

-- CreateIndex
CREATE INDEX "missoes_data_inicio_idx" ON "missoes"("data_inicio");

-- CreateIndex
CREATE INDEX "missoes_data_fim_idx" ON "missoes"("data_fim");

-- CreateIndex
CREATE INDEX "missoes_usuario_user_id_idx" ON "missoes_usuario"("user_id");

-- CreateIndex
CREATE INDEX "missoes_usuario_missao_id_idx" ON "missoes_usuario"("missao_id");

-- CreateIndex
CREATE INDEX "missoes_usuario_status_idx" ON "missoes_usuario"("status");

-- CreateIndex
CREATE UNIQUE INDEX "missoes_usuario_user_id_missao_id_key" ON "missoes_usuario"("user_id", "missao_id");

-- CreateIndex
CREATE INDEX "campanhas_patrocinadas_parceiro_id_idx" ON "campanhas_patrocinadas"("parceiro_id");

-- CreateIndex
CREATE INDEX "campanhas_patrocinadas_ativa_idx" ON "campanhas_patrocinadas"("ativa");

-- CreateIndex
CREATE INDEX "campanhas_patrocinadas_data_inicio_idx" ON "campanhas_patrocinadas"("data_inicio");

-- CreateIndex
CREATE INDEX "campanhas_patrocinadas_data_fim_idx" ON "campanhas_patrocinadas"("data_fim");

-- CreateIndex
CREATE UNIQUE INDEX "metricas_diarias_data_key" ON "metricas_diarias"("data");

-- CreateIndex
CREATE INDEX "metricas_diarias_data_idx" ON "metricas_diarias"("data");

-- CreateIndex
CREATE INDEX "_CampanhaMissoes_missao_index" ON "_CampanhaMissoes"("missao");

-- AddForeignKey
ALTER TABLE "tattoos" ADD CONSTRAINT "tattoos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pontos_transacoes" ADD CONSTRAINT "pontos_transacoes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pontos_transacoes" ADD CONSTRAINT "pontos_transacoes_tattoo_id_ref_fkey" FOREIGN KEY ("tattoo_id_ref") REFERENCES "tattoos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recompensas" ADD CONSTRAINT "recompensas_parceiro_id_fkey" FOREIGN KEY ("parceiro_id") REFERENCES "parceiros"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recompensas_usuario" ADD CONSTRAINT "recompensas_usuario_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recompensas_usuario" ADD CONSTRAINT "recompensas_usuario_recompensa_id_fkey" FOREIGN KEY ("recompensa_id") REFERENCES "recompensas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "creditos" ADD CONSTRAINT "creditos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "creditos_transacoes" ADD CONSTRAINT "creditos_transacoes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "missoes_usuario" ADD CONSTRAINT "missoes_usuario_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "missoes_usuario" ADD CONSTRAINT "missoes_usuario_missao_id_fkey" FOREIGN KEY ("missao_id") REFERENCES "missoes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campanhas_patrocinadas" ADD CONSTRAINT "campanhas_patrocinadas_parceiro_id_fkey" FOREIGN KEY ("parceiro_id") REFERENCES "parceiros"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_CampanhaMissoes" ADD CONSTRAINT "_CampanhaMissoes_campanha_fkey" FOREIGN KEY ("campanha") REFERENCES "campanhas_patrocinadas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_CampanhaMissoes" ADD CONSTRAINT "_CampanhaMissoes_missao_fkey" FOREIGN KEY ("missao") REFERENCES "missoes"("id") ON DELETE CASCADE ON UPDATE CASCADE;
