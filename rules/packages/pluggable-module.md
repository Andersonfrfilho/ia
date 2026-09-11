---
paths:
  - "**/packages/**"
  - "**/*-contracts/**"
  - "**/*-module/**"
  - "**/*-ui/**"
---

# 🧩 Módulos Plugáveis de Capacidade (Backend + Frontend + Contracts) — V1

Este documento define o padrão oficial do ecossistema para **capacidades reutilizáveis entre produtos** (ex: WhatsApp, Emissão Fiscal, Open Finance). O objetivo é desenvolver uma capacidade **uma única vez** e plugá-la em qualquer produto, sem compartilhar banco de dados, regras de negócio ou deploy entre projetos — e sem o antipadrão de copy-paste que gera divergência.

Toda I.A. ou desenvolvedor que for criar, evoluir ou consumir um módulo plugável deve seguir rigorosamente estas diretrizes.

---

## 1. Quando Criar um Módulo Plugável (Regra do 2º Uso)

- **Nunca extraia por antecipação.** Uma capacidade só vira módulo plugável quando o **segundo consumidor real** aparece. Antes disso, ela vive dentro do produto que a criou.
- **Candidatos típicos:** integrações com estado, credenciais, webhooks, retries ou processos longos (WhatsApp, fiscal, pagamentos, Open Finance), e as camadas de UI que as acompanham.
- **Não candidatos:** regra de negócio do produto (funil de financiamento, precificação de frete, catálogo). Isso permanece no produto, sempre.

### 📐 Módulo Plugável vs Serviço de Plataforma (Gateway)

| Critério | Módulo plugável (pacote) | Serviço central (gateway) |
|---|---|---|
| Cada produto tem sua própria credencial/número | ✅ natural | funciona, mas multi-tenant |
| Custo operacional | ✅ zero deploys extras | ➖ mais um serviço + banco |
| Upgrade de versão | ➖ bump de pacote em cada produto | ✅ deploy único |
| Consumidores fora da stack Bun/TS | ❌ não atende | ✅ é só HTTP |
| Webhook externo (ex: Meta) | um endpoint por produto | um endpoint central |

**Default do ecossistema: módulo plugável.** O gateway só se justifica com muitos consumidores, necessidade de centralizar credenciais/observabilidade ou consumidores fora da stack. Os dois não se excluem — um gateway futuro nasce hospedando o mesmo módulo.

---

## 2. Anatomia Obrigatória: o Trio de Pacotes

Toda capacidade plugável é publicada como **três pacotes** no registry privado (GitHub Packages), versionados por semver:

```text
packages/
├── <capacidade>-contracts/   ← zod schemas + DTOs (fonte única de tipos)
├── <capacidade>-module/      ← backend plugável (schema, migrations, rotas, worker)
└── <capacidade>-ui/          ← frontend plugável (headless hooks + telas default)
```

- **`contracts` é a fonte única da verdade.** Backend valida com ele, frontend tipa queries com ele. Mudança de contrato → bump de versão → os dois lados quebram em compile-time, nunca em produção.
- É **proibido** um produto importar outro produto. Compartilhamento só via pacotes versionados — nunca import relativo atravessando repositórios, nunca git submodule.

### 📐 Nomenclatura — Prefixo do Fornecedor da Plataforma

Capacidades que encapsulam produtos de um fornecedor/plataforma externa carregam o **prefixo do fornecedor** no nome do trio:

- Produtos Meta: `meta-whatsapp-*` (ex: `@ada/meta-whatsapp-module`)
- O mesmo vale para futuros fornecedores (ex: `google-*`, `openfinance-*`)
- Capacidades próprias, sem fornecedor externo, não levam prefixo (ex: `fiscal-*`, `catalog-*`)
- O prefixo se propaga aos identificadores internos: pgSchema `meta_whatsapp`, journal `meta_whatsapp_migrations`

**Teste do prefixo: a capacidade existe sem o fornecedor?** Se sim, ela é própria e o prefixo
mentiria sobre o acoplamento.

- `meta-whatsapp-*` leva prefixo: sem a Graph API da Meta não existe a capacidade — ela É a
  integração.
- `catalog-*` **não** leva: cadastrar produto, precificar e organizar em catálogo funciona
  inteiro sem a Meta. Publicar na Meta Commerce é integração **opcional e desligada por padrão**,
  atrás de porta (`MetaCatalogSyncPort`); um nome `meta-catalog-module` faria toda vertical que
  não vende por WhatsApp achar que precisa da Meta para gerenciar o próprio catálogo.
- O SDK stateless que fala com o fornecedor mantém o prefixo mesmo quando serve uma capacidade
  própria: `meta-catalog-provider` é cliente da Meta Commerce API e continua se chamando assim.

### 📐 Granularidade — Uma Capacidade por Trio

Cada trio cobre **uma única capacidade**. Funcionalidades que convivem no mesmo fluxo mas não dependem conceitualmente uma da outra são **capacidades separadas, com SDKs separados**.

- **Exemplo canônico: Catálogo ≠ WhatsApp.** Catálogo de produtos (cadastro, precificação, listagem, estoque) é uma capacidade própria — pode ser exibido na web, no PWA ou em outro canal. O trio é `catalog-contracts` / `catalog-module` / `catalog-ui`, independente do trio `meta-whatsapp-*`. Publicar esse catálogo na Meta Commerce é integração opcional do trio de catálogo, atrás de porta, e não muda o nome dele (ver o teste do prefixo acima).
- A integração entre capacidades acontece **no produto** (ou por porta declarada): o produto pluga o `catalog-module` no hook `onMessageReceived` do `meta-whatsapp-module` para responder consultas de produto; o `meta-whatsapp-module` nunca importa o `catalog-module` nem vice-versa.
- **Teste de granularidade:** se a capacidade B pode ser usada sem a capacidade A existir no produto, elas são trios separados. Empacotar as duas juntas força todo consumidor a carregar dependências que não usa e acopla os ciclos de versão.

---

## 3. 🔌 Backend — Regras do `<capacidade>-module`

### 📂 Estrutura

```text
packages/meta-whatsapp-module/
├── src/
│   ├── schema/              ← tabelas Drizzle no pgSchema dedicado
│   ├── migrations/          ← SQL versionadas, geradas pelo drizzle-kit DO PACOTE
│   ├── MetaWhatsAppModule.ts    ← createMetaWhatsAppModule(params)
│   ├── routes.ts            ← registerRoutes({ server, basePath })
│   ├── worker.ts            ← createMetaWhatsAppWorker(params)
│   ├── events.ts            ← eventos de domínio emitidos (pontos de extensão)
│   └── interfaces/          ← portas substituíveis (*.interface.ts)
└── package.json
```

### 📐 Migrations Embarcadas (Journal Próprio)

O módulo carrega suas próprias migrations **e seu próprio journal**, para nunca colidir com as migrations do host:

```ts
export async function runMetaWhatsAppMigrations(params: RunMetaWhatsAppMigrationsParams): Promise<void> {
  await migrate(params.db, {
    migrationsFolder: resolveModuleMigrationsPath(),
    migrationsTable: 'meta_whatsapp_migrations',
  });
}
```

- O host chama `run<Capacidade>Migrations(db)` no startup ou via `make migrate`.
- Migrations do módulo são **append-only**; mudança destrutiva segue expand/contract (ver `database.md`).
- Upgrade de pacote que traz migration nova é aplicado automaticamente no próximo deploy do host.

### 📐 Isolamento de Tabelas

- Tabelas do módulo vivem em um **Postgres schema dedicado** (`pgSchema('meta_whatsapp')`), nunca no schema `public` do produto.
- O banco continua sendo **um por produto** — o módulo apenas ocupa um namespace dentro dele. Nenhum banco é compartilhado entre produtos.

### 📐 Configuração 100% Injetada

O módulo **não lê `process.env`** e **não cria conexões próprias**. Tudo chega por parâmetro, validado por schema do próprio módulo:

```ts
const whatsapp = createMetaWhatsAppModule({
  db,                                      // conexão Drizzle do host
  amqp,                                    // broker do host (se necessário)
  config: { phoneNumberId, accessToken, webhookVerifyToken, appSecret },
  providers: { mediaStorage, configResolver },   // overrides opcionais
  hooks: { onMessageReceived, onSessionExpired }, // extensão do produto
});

whatsapp.registerRoutes({ server, basePath: '/whatsapp' });
```

### 📐 Extensão — as Únicas Portas Permitidas

**Regra inquebrável: o host nunca edita código do módulo.** Customização entra apenas por porta declarada:

1. **Hooks/eventos de domínio** (`message.received`, `session.expired`) — o produto pluga seus use-cases neles; é onde vive a regra de negócio do produto.
2. **Interfaces substituíveis** (`MediaStorageInterface`, `ConfigResolverInterface`) — implementação default no pacote, override pelo host.
3. **Composição via PR no pacote** — funcionalidade genérica (que serviria a todos os produtos) entra no módulo com bump de versão; todos herdam.

Se o produto precisa de uma porta que não existe, o caminho é **abrir a porta no pacote (PR)**, nunca forkar ou editar `node_modules`.

---

## 4. 🎨 Frontend — Regras do `<capacidade>-ui`

Padrão **headless por baixo, UI pronta por cima** (mesmo modelo de Radix/TanStack). Camadas de customização, da mais barata à mais profunda:

1. **Tema e tokens** — o módulo não tem cor própria; consome os design tokens injetados (ver `web.md` seção 8). A mesma tela ganha a cara de cada produto trocando o theme.
2. **Configuração** — `<WhatsAppModuleProvider config={{ apiBasePath, features }} theme={...} locale={...} queryClient={queryClient}>` — usa o TanStack Query **do host**, nunca instancia o próprio.
3. **Slots e overrides** — registry onde o host substitui peças pontuais: `components={{ MessageBubble: LeadScoringBubble }}`.
4. **Camada headless (válvula de escape)** — o pacote exporta hooks/queries separados da UI (`useConversations.query.ts`, `useSendMessage.mutation.ts`). Quando a tela default não serve, o produto monta a própria tela sobre os mesmos hooks — continua herdando upgrades de lógica.
5. **Rotas montáveis** — `createWhatsAppRoutes({ basePath })` devolve definições que o host espalha no router dele.

- Textos do módulo seguem `*.locale.json` próprios, com merge de overrides do host.
- O módulo UI tipa contra o `<capacidade>-contracts`. O BFF do produto pode **decorar** respostas (agregar dados do produto), mas é proibido mutar o shape base.

### 📐 A tela composta é o padrão de consumo — **OBRIGATÓRIO**

Exportar só peças (`MessageBubble`, `Canvas`, `Palette`) não impede divergência: cada produto remonta o
grid à mão, e as telas voltam a andar separadas — exatamente o que aconteceu com fluxograma e
mensagens antes desta regra. **Toda capacidade com tela deve exportar o `<Capacidade>Workspace`
composto**, e o produto consome a tela inteira, não as peças.

- **Ao implementar ou alterar uma dessas telas num produto: puxar o workspace completo do pacote.**
  Se a tela do produto passa de ~150 linhas, ou reimplementa layout, paginação, filtros, seleção em
  lote ou composer, é sinal de que se está remontando o que o pacote já entrega — parar e usar o
  workspace.
- **O workspace aceita customização por contrato, não por fork.** Vocabulário do produto entra por
  `labels`; UI específica entra por slot de render (`renderFilters`, `renderAboveTranscript`,
  `extraUtilitiesFor`); regra de negócio entra por callback.
- **Capacidade é opcional por ausência:** prop não passada não desenha o affordance (sem
  `onRecordAudio`, sem microfone). O produto que não tem a funcionalidade simplesmente omite — nunca
  ganha uma flag `hasX`.
- Copiar a tela do pacote para dentro do produto para "ajustar um detalhe" é rejeitado em code
  review. Falta de porta é motivo de PR no pacote, não de fork.
- A camada headless (§4.4) continua sendo a válvula de escape — mas é exceção justificada no PR, não
  o caminho padrão.

---

## 5. 📦 Versionamento, Publicação e Consumo

- **Registry:** GitHub Packages (npm privado da organização), escopo `@ada/*`.
- **Semver estrito:** breaking change de contrato ou de schema = major. Migration nova sem breaking = minor.
- **Changelog obrigatório** por release (changesets ou equivalente), destacando migrations incluídas e portas novas/alteradas.
- **Consumo:** `bun add @ada/meta-whatsapp-module @ada/meta-whatsapp-contracts` (+ `@ada/meta-whatsapp-ui` no frontend). O produto fixa versão e faz upgrade no seu ritmo.
- Um produto **nunca** depende de branch/commit git do pacote — apenas de versão publicada.

### ✅ Checklist de Aceite de um Módulo Novo

- [ ] Trio `contracts` / `module` / `ui` publicado com semver
- [ ] Migrations com journal próprio (`<capacidade>_migrations`) e pgSchema dedicado
- [ ] Zero leitura de `process.env` dentro do pacote — config 100% injetada e validada
- [ ] Eventos de domínio documentados (nome, payload tipado no contracts)
- [ ] Interfaces substituíveis com implementação default
- [ ] Frontend com camada headless exportada independente das telas
- [ ] Frontend expondo o `<Capacidade>Workspace` composto, com `labels` e slots de render
- [ ] Nenhuma regra de negócio de produto dentro do módulo
- [ ] README do pacote com: instalação, `create<Capacidade>Module`, portas de extensão, exemplo de host

---

## 6. 🚫 Antipadrões (Rejeitados em Code Review)

| Antipadrão | Por quê |
|---|---|
| Copy-paste do módulo entre produtos "com melhorias locais" | Divergência garantida — é o problema que este padrão elimina |
| Git submodule / import relativo entre repositórios | Acopla deploy e versionamento; quebra silenciosamente |
| Banco compartilhado entre produtos | Acoplamento invisível; qualquer migration quebra todos |
| Módulo lendo `process.env` ou criando conexão própria | Impede o host de controlar ambiente, pool e ciclo de vida |
| Host editando código do pacote (patch em `node_modules`, fork) | Perde upgrades; regra de extensão é porta declarada ou PR |
| Regra de negócio do produto dentro do módulo | O módulo vira fork disfarçado e para de servir aos demais |
| Extrair capacidade antes do 2º consumidor existir | Abstração prematura — custo sem retorno |
| Produto remontar a tela a partir das peças em vez de usar o `<Capacidade>Workspace` | O grid volta a divergir entre produtos; é o que a §4 exige evitar |
| Redeclarar localmente os tipos que vivem no `-contracts` | O contrato evolui e nada quebra em compile-time no produto |

---

## 7. 🤖 Modelos por Etapa (Economia de Modelo)

Segue o protocolo global de `model-economy.md`: **planejar caro, executar barato, revisar caro**. Toda extração/evolução de módulo plugável declara o modelo por etapa:

| Etapa | Modelo | O que faz |
|---|---|---|
| Desenho do módulo (portas, granularidade, contratos, decisão módulo vs gateway) | `opus`/`fable` 🧠 | Decisões estruturais e assinaturas públicas — erro aqui custa uma major |
| Extração do `*-contracts` (mover tipos, zod schemas, eventos) | `haiku` | Mecânico: mover e renomear tipos já existentes, sem decisão de design |
| Implementação do `*-module` (migrations, rotas, refactor de use-cases para portas) | `sonnet` | Execução padrão com critério de aceite verificável |
| Implementação do `*-ui` (componentes, hooks headless, slots, locales) | `sonnet` | Execução padrão; telas e queries seguem contrato pronto |
| Passes mecânicos (renames com prefixo, bumps de versão, changelogs, locales) | `haiku` | Repetitivo e reversível |
| **Revisão final (gate de publicação)** | **`opus` 4.8** | Obrigatória antes de publicar versão: verificar se a entrega atingiu o objetivo, caçar bugs, validar checklist da seção 5, auditoria de segurança/performance |

### 📐 Regras do Gate de Revisão

- **Nenhuma versão é publicada no registry sem o passe de revisão com `opus` 4.8** — a revisão confere: objetivo da task atingido, portas declaradas corretamente, migrations append-only, zero `process.env` no pacote, zero regra de negócio de produto no módulo, e bugs de lógica/concorrência/segurança.
- Etapas executadas com `haiku`/`sonnet` mantêm os guard-rails de `model-economy.md`: `tsc --noEmit`, testes do pacote e commit isolado por task.
- Se a sessão atual estiver num modelo diferente do recomendado para a etapa, **parar e pedir a troca ao usuário** antes de tocar em código (regra inquebrável de `model-economy.md`).
