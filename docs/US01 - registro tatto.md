Vou refazer o planejamento considerando **exatamente** essas tabelas e o contexto Next.js + Supabase, focando na US01.1.

Vou estruturar como documento de refinamento + lista de tarefas.

---

### 1. Contexto da US

**US01.1 – Ganhar Pontos ao Registrar Nova Tattoo**

- Ao registrar uma nova tattoo com:
  - `foto_url` (foto),
  - `localizacao_corpo`,
  - `data_aproximada`,
- o usuário ganha **50 pontos** (vamos assumir fixo por enquanto).
- Precisamos:
  - Atualizar `xp_total` do usuário na tabela `users`.
  - Registrar transação em `pontos_transacoes` (auditoria).
  - Garantir **idempotência** (mesma tattoo na mesma localização: pontua uma vez só).
  - Disparar notificação visual no front:  
    `"Parabéns! Você ganhou 50 pontos"` (toast).

Obs: tabelas de `creditos` e `creditos_transacoes` **não participam** desta US (só XP/pontos).

---

### 2. Modelagem usando as tabelas existentes

#### 2.1. Tabelas relevantes

- **users**
  - `id` (UUID) – PK
  - `email`
  - `nome`
  - `foto`
  - `nivel` (gamificação futura)
  - `xp_total` (vai ser nosso “saldo de pontos”)

- **tattoos**
  - `id` (UUID) – PK
  - `user_id` (FK → users.id)
  - `foto_url`
  - `localizacao_corpo`
  - `data_aproximada`
  - `significado`
  - `data_criacao`
  - `data_atualizacao`
  - **Falta apenas algo para idempotência** → vamos propor extensão abaixo.

- **pontos_transacoes**
  - `id` (UUID) – PK
  - `user_id` (FK → users.id)
  - `tipo_acao` (TEXT)
  - `quantidade` (INTEGER) – positivo (ganho) ou negativo (perda)
  - `descricao`
  - `data_hora`
  - `tattoo_id_ref` (UUID, FK → tattoos.id) – referência para auditoria.

As tabelas `creditos` e `creditos_transacoes` não são usadas nesta história.

---

### 3. Ajuste mínimo de schema (idempotência)

Para garantir o critério:

> Idempotência: se a mesma tattoo for "salva" mais de uma vez na mesma localização, pontos são creditados apenas uma vez;

Precisamos de uma “chave” para identificar “mesma tattoo” por usuário.

Sugestão de **migração simples** na tabela `tattoos`:

- Adicionar coluna:
  - `idempotency_hash TEXT NULL`
- Criar índice/unique:
  - Unique combinando `user_id` + `idempotency_hash`
    - Ou apenas unique em `idempotency_hash` se o hash já incluir o `user_id`.

**Regra para gerar `idempotency_hash` (primeira versão):**

```text
idempotency_hash = hash( user_id + "|" + normalizar(localizacao_corpo) + "|" + data_aproximada (YYYY-MM-DD) )
```

- `normalizar(localizacao_corpo)`:
  - `trim`, `toLowerCase`,
  - remover acentos se possível.
- Isso garante que tentar registrar a “mesma tattoo” (mesma localização e mesma data) não vai gerar pontuação em duplicidade.

---

### 4. Fluxo de UX / Telas

#### 4.1. Tela “Minhas Tattoos” – `/tattoos`

Objetivo: CRUD básico, mas para esta US focar em **Create** e exibição simples.

Componentes:

1. **Header**
   - Título: `Minhas Tattoos`.
   - Badge com XP do usuário:
     - “XP total: 150” (leitura de `users.xp_total`).
   - Botão `+ Nova Tattoo` → navega para `/tattoos/nova`.

2. **Lista de tattoos**
   - Chamar Supabase (ou API) para listar `tattoos` do `user_id` logado.
   - Cada card:
     - Foto (`foto_url`).
     - `localizacao_corpo`.
     - `data_aproximada` formatada.
     - (Ações de editar/excluir podem ficar para outra US, mas já prever layout).

3. **Empty state**
   - Se não houver tattoos:
     - Texto: “Você ainda não registrou nenhuma tattoo. Comece documentando sua história!”

---

#### 4.2. Tela “Nova Tattoo” – `/tattoos/nova`

Formulário com:

- Upload de foto (ou seleção da URL se o upload for feito antes).
- Campo `localizacao_corpo` (texto ou select).
- Campo `data_aproximada` (date picker ou input date).
- Campo `significado` (texto longo, opcional).
- Botões:
  - `Salvar Tattoo`
  - `Cancelar` (voltar para `/tattoos`).

**Comportamento:**

1. Validar campos obrigatórios (`foto_url`, `localizacao_corpo`, `data_aproximada`).
2. No submit:
   - Fazer upload da foto (se ainda não estiver em `foto_url`).
   - Chamar `POST /api/tattoos`.
3. Enquanto aguarda:
   - Desabilitar botão, mostrar spinner.
4. Na resposta:
   - Se `points_awarded > 0`:
     - Atualizar XP no contexto (`xp_total`).
     - Mostrar toast:
       - `"Parabéns! Você ganhou 50 pontos"`.
   - Se `points_awarded = 0` e `is_duplicate`:
     - Mostrar toast tipo:
       - `"Essa tattoo já foi registrada. Nenhum ponto adicional foi concedido."`
     - (texto final a alinhar com PO).
   - Redirecionar para `/tattoos`.

---

### 5. Regras de Negócio de Pontos

1. **Valor padrão de pontos**
   - Nova tattoo concluída com campos mínimos válidos → **+50 pontos**.
   - Constante no código: `POINTS_NOVA_TATTOO = 50`.

2. **Atualização de saldo**
   - Saldo de pontos está em `users.xp_total`.
   - Ao registrar nova tattoo:
     - Incrementar `xp_total` em 50.
   - Idempotência garante que não seja incrementado em duplicidade.

3. **Auditoria (`pontos_transacoes`)**

Ao conceder pontos:

- Inserir linha em `pontos_transacoes` com:
  - `id`: uuid.
  - `user_id`: usuário logado.
  - `tipo_acao`: `"registro_nova_tattoo"`.
  - `quantidade`: `50`.
  - `descricao`: ex. `"Pontos por cadastro de nova tattoo"`.
  - `tattoo_id_ref`: `id` da tattoo criada.
  - `data_hora`: default `CURRENT_TIMESTAMP`.

---

### 6. API Next.js – Design / Fluxo

#### 6.1. Rota Principal

- `POST /api/tattoos`

**Payload (proposto):**

```json
{
  "foto_url": "https://.../tattoos/123.jpg",
  "localizacao_corpo": "antebraço direito",
  "data_aproximada": "2024-01-01T00:00:00.000Z",
  "significado": "Minha primeira tattoo"
}
```

**Passos no handler:**

1. **Autenticação**
   - Obter `user_id` da sessão (Supabase Auth ou NextAuth).
   - Se não autenticado → `401`.

2. **Validação mínima**
   - `foto_url`: não vazio.
   - `localizacao_corpo`: não vazio.
   - `data_aproximada`: formato válido (converter para `Date`/`timestamp`).

3. **Gerar `idempotency_hash`**
   - Normalizar `localizacao_corpo`.
   - Normalizar `data_aproximada` para `YYYY-MM-DD` (ignorando hora).
   - Concatenar com `user_id` e gerar hash (ex.: usando `crypto` no Node).
   - Guardar para uso na inserção.

4. **Verificação de idempotência**
   - Query em `tattoos`:
     - `SELECT id FROM tattoos WHERE user_id = $user_id AND idempotency_hash = $hash LIMIT 1;`
   - Se existir:
     - Buscar `users.xp_total`.
     - Retornar 200 com:
       ```json
       {
         "tattoo_id": "existente-id",
         "points_awarded": 0,
         "xp_total": 1234,
         "is_duplicate": true
       }
       ```
     - Não criar transação em `pontos_transacoes`.
     - Não alterar `users.xp_total`.

5. **Criar tattoo + pontos (transação)**
   - Idealmente usar uma **função RPC** no Supabase para garantir atomicidade.
   - Fluxo dentro da transação:
     1. Inserir em `tattoos`:
        - Com `user_id`, `foto_url`, `localizacao_corpo`, `data_aproximada`, `significado`, `idempotency_hash`.
     2. Atualizar `users.xp_total`:
        - `UPDATE users SET xp_total = xp_total + 50 WHERE id = user_id RETURNING xp_total;`
     3. Inserir em `pontos_transacoes`:
        - Campos conforme seção 5.3.
   - Retornar dados:
     ```json
     {
       "tattoo_id": "novo-id",
       "points_awarded": 50,
       "xp_total": 1284,
       "is_duplicate": false
     }
     ```

> Observação: se não usar transação no client, fazer isso via **função SQL (RPC)** no Supabase é melhor (BEGIN/COMMIT no backend do Supabase).

---

### 7. Tarefas Detalhadas (para dividir em cards)

#### 7.1. DB / Supabase

1. **[DB] Adicionar campo de idempotência em `tattoos`**
   - Migration:
     - `ALTER TABLE tattoos ADD COLUMN idempotency_hash TEXT;`
     - Criar índice/unique:
       - `CREATE UNIQUE INDEX tattoos_user_id_idempotency_hash_idx ON tattoos (user_id, idempotency_hash);`
   - (Opcional: tornar `idempotency_hash` NOT NULL quando toda aplicação estiver usando).

2. **[DB] Criar função RPC para registrar tattoo + pontos (opcional mas recomendado)**  
   Ex.: `fn_registrar_tattoo_e_pontos(user_id uuid, foto_url text, localizacao_corpo text, data_aproximada timestamptz, significado text, idempotency_hash text, pontos int)`
   - Passos dentro da função:
     - Verifica se já existe `tattoos` com mesmo `user_id` + `idempotency_hash`:
       - Se existir → retorna existente + `points_awarded = 0`.
     - Caso contrário:
       - Insere tattoo.
       - Atualiza `users.xp_total = xp_total + pontos`.
       - Insere em `pontos_transacoes`.
       - Retorna novos valores (id da tattoo, new xp_total, points_awarded).

3. **[DB] Garantir FKs**
   - `tattoos.user_id` → `users.id`.
   - `pontos_transacoes.user_id` → `users.id`.
   - `pontos_transacoes.tattoo_id_ref` → `tattoos.id`.

---

#### 7.2. Backend Next.js (API Routes)

4. **[BE] Criar rota POST `/api/tattoos`**
   - Recuperar `user_id` autenticado.
   - Validar body.
   - Gerar `idempotency_hash`.
   - Chamar **função RPC** do Supabase (se criada) OU:
     - Implementar lógica manual:
       - Verificar duplicidade.
       - Se não duplicado:
         - Inserir tattoo.
         - Atualizar `users.xp_total`.
         - Inserir em `pontos_transacoes`.
   - Retornar JSON com:
     - `tattoo_id`
     - `points_awarded`
     - `xp_total`
     - `is_duplicate`.

5. **[BE] Criar rota GET `/api/tattoos` (lista)**
   - Listar tattoos do `user_id` logado.
   - Retornar dados necessários para a tela.

6. **[BE] (Opcional) Criar rota GET `/api/user/xp`**
   - Para voltar apenas `xp_total`.
   - Ou incluir `xp_total` sempre que buscarmos o user.

---

#### 7.3. Frontend – Páginas e Componentes

7. **[FE] Componente de Toast global**
   - `useToast()` com:
     - `showSuccess(message)`
     - `showError(message)`
   - Usado para:
     - Sucesso com pontos.
     - Tattoo duplicada.
     - Erros.

8. **[FE] Contexto do usuário com XP**
   - Estender contexto atual de usuário logado:
     - `user`, `xpTotal`, `setXpTotal`.
   - Carregar `xpTotal` no login (via API `/me` ou similar).
   - Exibir `xpTotal` no header.

9. **[FE] Página `/tattoos`**
   - Layout:
     - Header: título + badge `XP total: {xpTotal}` + botão “Nova Tattoo”.
     - Lista de tattoos:
       - Chama `/api/tattoos` ou Supabase client.
       - Renderiza cards com foto + localização + data.
     - Empty state.
   - Loading states.

10. **[FE] Página `/tattoos/nova`**
    - Form:
      - Upload de imagem (integrado com Supabase Storage) → produz `foto_url`.
      - `localizacao_corpo`.
      - `data_aproximada`.
      - `significado`.
    - Submissão:
      - POST `/api/tattoos`.
      - Se `response.is_duplicate`:
        - `showInfo("Essa tattoo já foi registrada. Nenhum ponto adicional foi concedido.")`.
      - Se `points_awarded > 0`:
        - `setXpTotal(response.xp_total)`.
        - `showSuccess("Parabéns! Você ganhou 50 pontos")`.
      - Redirecionar para `/tattoos`.

---

#### 7.4. Testes

11. **[TEST] Testes unitários – backend**
   - Função geradora de `idempotency_hash`.
   - Serviço que orquestra:
     - Caso novo:
       - Cria tattoo, cria transação, atualiza xp.
     - Caso duplicado:
       - Não altera xp, não cria nova transação.

12. **[TEST] Testes de integração – API `/api/tattoos`**
   - POST válido (primeira vez):
     - `points_awarded = 50`.
     - `xp_total` aumenta.
     - Existe registro em `pontos_transacoes`.
   - POST idêntico (mesmos campos para mesmo user):
     - `points_awarded = 0`.
     - `is_duplicate = true`.
     - `xp_total` não muda.
     - Não cria novo `pontos_transacoes`.

13. **[TEST] Testes manuais end-to-end**
   - Login.
   - Ver XP inicial.
   - Cadastrar nova tattoo:
     - Ver toast de sucesso com 50 pontos.
     - XP no header aumenta.
   - Registrar a mesma tattoo:
     - Ver toast de duplicidade.
     - XP não muda.
   - Conferir no Supabase:
     - Tattoos: só 1 registro com aquele hash.
     - `pontos_transacoes`: só 1 linha para aquela `tattoo_id_ref`.

14. **[TEST] Testes automatizados end-to-end**
   - Usar playwright para testar:
   - Login.
   - Ver XP inicial.
   - Cadastrar nova tattoo:
     - Ver toast de sucesso com 50 pontos.
     - XP no header aumenta.
   - Registrar a mesma tattoo:
Se você quiser, posso na próxima mensagem:

- Escrever um exemplo de **handler TypeScript** da rota `POST /api/tattoos` com Supabase.
- Ou desenhar a função SQL (RPC) para registrar tattoo + pontos de forma transacional.
     - Ver toast de duplicidade.
     - XP não muda.
   - Conferir (de alguma forma):
     - Tattoos: só 1 registro com aquele hash.
     - `pontos_transacoes`: só 1 linha para aquela `tattoo_id_ref`.

---

### 8. Pontos alinhados com o PO (refinamento)

- **Critério de “mesma tattoo”**:
  - Para essa primeira versão vamos usar:
    - `user_id + localizacao_corpo + data_aproximada` como base para idempotência.
  - o PO concorda com esse critério.

- **Mensagem para duplicidade**:
  - Texto de UX final (para toast).
  - o PO concorda com esse texto para primeira versão: "Parabéns! Você ganhou 50 pontos"
  - o PO concorda com esse texto para duplicidade: "Essa tattoo já foi registrada. Nenhum ponto adicional foi concedido."

- **Valor fixo de 50 pontos**:
  - é fixo para a primeira versão. em outra história, vai variar por campanha mas não faz parte desse escopo.

- **Exclusão/edição de tattoo**:
  - Por agora:
    - Editar não muda pontos.
    - Excluir não devolve pontos.
  - o PO vai pedir comportamento diferente e vira outra US.

