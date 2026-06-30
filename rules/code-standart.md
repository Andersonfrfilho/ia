# 📐 Diretrizes de Arquitetura, Padrões de Código e Regras para I.A. (V7 - Versão Definitiva Completa)

Este documento estabelece as regras estritas de codificação, nomenclatura, arquitetura, infraestrutura local, documentação e qualidade que devem ser seguidas em todo o ciclo de desenvolvimento deste repositório. Toda inteligência artificial (I.A.) ou desenvolvedor atuando nesta base de código deve respeitar rigorosamente estas diretrizes.

---

## 1. Convenção de Nomenclatura e Extensões de Arquivos

Para garantir consistência visual e facilidade de busca no projeto, todos os ficheiros criados devem adotar explicitamente os seus sufixos de papel/responsabilidade na extensão:

- **Casos de Uso / Regras de Negócio:** `*.use-case.ts`
- **Serviços / Integrações:** `*.service.ts`
- **Controladores / Portas de Entrada:** `*.controller.ts`
- **Constantes Globais/Locais:** `*.constant.ts`
- **Tipos e Interfaces de Domínio:** `*.types.ts` ou `*.interface.ts`
- **Esquemas de Validação:** `*.schema.ts`
- **Classes de Erro Customizadas:** `*.error.ts`

---

## 2. Divisão de Projetos, Ecossistema Tecnológico e Monorepo

O ecossistema deve ser planejado de forma segregada e escalável, separando os pontos de entrada e processamento do sistema. Sempre avalie a necessidade de dividir a arquitetura nos seguintes escopos:

### 🚀 Divisão de Camadas e Projetos

- **api (Aplicações Principais):** Responsável por expor endpoints HTTP/WebSocket. Atua como produtora de mensagens sempre que houver necessidade de processamento assíncrono.
- **worker (Mensageria):** Consumidor exclusivo de filas/tópicos (ex: RabbitMQ, Kafka, Redis Streams) para processamento em background de tarefas pesadas.
- **cron (Tarefas Agendadas):** Projetos dedicados a rodar rotinas temporizadas ou agendadas (ex: limpezas de banco, relatórios diários).
- **micro-services:** Criados apenas sob real necessidade de isolamento de domínio ou escalabilidade extrema de carga.
- **frontend / mobile:** Interfaces de usuário totalmente desacopladas do backend.

### 🏷️ Nomenclatura Padrão de Pastas/Projetos

Todos os projetos de escopo de execução dentro da pasta `apps/` devem seguir o prefixo da sua responsabilidade por hífen:

- `apps/api-...` (ex: `apps/api-principal`, `apps/api-checkout`)
- `apps/worker-...` (ex: `apps/worker-pagamentos`)
- `apps/cron-...` (ex: `apps/cron-notificacoes`)
- `apps/frontend-...` ou `apps/mobile-...`

### 🛠️ Stack Tecnológica Obrigatória

A stack inteira prioriza a tipagem estática e máxima performance em tempo de execução:

- **Linguagem Principal:** TypeScript em 100% dos projetos.
- **Ambiente de Execução (Runtime):** **Bun** como runtime nativo e gerenciador de pacotes para máxima velocidade.
- **Backend:** Construído sobre **uWebSockets.js** rodando no Bun para conexões de ultra-alta performance e baixa latência (HTTP e WebSockets).
- **Frontend:** **React** atualizado com o que há de mais moderno na comunidade (ecossistema Bun, Server Components quando aplicável, Vite/Bun build tooling).
- **Pacotes Dinâmicos (Packages/Ex-libs):** Se um Provedor de Serviço for consumido por mais do que um tipo de projeto (ex: `api` e `worker`), ele deve ser encapsulado em um pacote independente em `packages/` e configurado estritamente por variáveis de ambiente (`process.env`). Se o caminho for incerto, a I.A. deve **parar e perguntar**.

---

## 3. Estrutura Modular e Localização do Código Partilhado (Shared)

- **Shared de Módulo:** Elementos que servem apenas àquele domínio específico residem em `src/modules/<Modulo>/shared/`.
- **Shared Global do Projeto:** Elementos técnicos transversais pertencentes a uma aplicação específica ficam em `src/modules/shared/`.

### 📂 Mapa de Pastas Padrão do Monorepo

```text
meu-monorepo/
├── apps/
│   ├── api-principal/                       <-- Prefixo "api-..."
│   │   └── src/
│   │       ├── modules/
│   │       │   ├── Order/
│   │       │   │   ├── controllers/
│   │       │   │   │   └── Order.controller.ts
│   │       │   │   ├── services/
│   │       │   │   │   └── Order.service.ts
│   │       │   │   ├── use-cases/
│   │       │   │   │   └── ProcessOrder.use-case.ts
│   │       │   │   └── shared/
│   │       │   │       ├── Order.constant.ts
│   │       │   │       └── errors/
│   │       │   │           └── OrderNotFound.error.ts
│   │       │   └── shared/
│   │       │       ├── errors/
│   │       │       │   └── BaseError.ts
│   │       │       └── modules.shared.ts
│   │       └── server.ts                    <-- Usando uWebSockets.js no Bun
│   │
│   ├── worker-pagamentos/                   <-- Prefixo "worker-..."
│   └── frontend-cliente/                    <-- Prefixo "frontend-..."
│
├── packages/                                <-- Módulos autônomos Node.js
│   └── CryptoProvider/
│       ├── CryptoProvider.interface.ts
│       └── implementations/
│           └── BcryptCryptoProvider.ts
│
├── docker-compose.yml
├── Makefile
├── init-claude.md                           <-- Arquivo de Contexto para a I.A. (Sempre Atualizado)
└── envs/                                    <-- Isolamento central de Variáveis de Ambiente
    ├── env.dev
    ├── env.dev.local
    ├── env.test
    └── env.test.e2e
```

---

## 4. Ambiente de Desenvolvimento Local Automatizado (DevOps Local)

Toda a infraestrutura para rodar e testar o projeto localmente deve ser encapsulada, isolada e orquestrada de forma simples.

### 🐳 Docker Compose e Serviços de Mocks

- Um arquivo unificado `docker-compose.yml` na raiz do monorepo deve subir todas as dependências de infraestrutura necessárias (Banco de Dados, Brokers de Mensageria como RabbitMQ, Redis, etc.).
- **Serviços de Mocks:** Se o projeto depender de APIs de terceiros que cobram por chamada ou não possuem ambiente de sandbox estável, deve ser configurado um container de mock dentro do docker-compose para simular essas respostas localmente.

### 🔐 Gestão Estrita de Configurações (.env)

Todas as variáveis de ambiente devem ser centralizadas e segregadas em arquivos específicos na raiz ou em uma pasta dedicada (`envs/`):

- `env.dev`, `env.dev.local`, `env.test`, `env.test.e2e`.

### 🛠️ Makefile Descritivo com Emojis

A raiz do projeto deve conter um arquivo `Makefile` documentado e utilizando emojis para identificação visual rápida, abstraindo comandos complexos (ex: `make up`, `make test-unit`).

---

## 5. Seeders Baseados em Casos de Uso

- **Proibido SQL Direto em Seeds:** Os arquivos de seed do banco de dados não devem realizar inserts brutos (`INSERT INTO...`).
- **Simulação de Jornadas Reais:** Os seeders devem instanciar e executar os próprios **Casos de Uso (`*.use-case.ts`)** da aplicação de forma sequencial para testar todas as validações, filas e logs organicamente.

---

## 6. Injeção de Dependências Explícita

- **Injeção via Construtor:** Use Cases e Serviços dependem de **Interfaces** (`*.interface.ts`) passadas via construtor, eliminando o acoplamento pelo operador `new`.

---

## 7. Tratamento de Exceções, Erros e Validações

- **Erros Semânticos e Customizados:** Toda falha deve estender uma `BaseError`, carregar um código de rastreio exclusivo e, em cenários de validação, expor um array contendo os campos, as regras violadas e parâmetros contextuais informados.

---

## 8. Diretrizes de Banco de Dados e Migrações

- **VARCHAR sobre ENUMs:** Proibido uso de ENUM nativo de banco de dados.
- **Largura de Strings e Chaves:** Chaves primárias usam UUID (v4/v7) para dados públicos e BigInt sequencial para contextos internos N:N.

---

## 9. Clean Code e Limites de Complexidade

- **Complexidade Ciclomática Máxima:** Limite estrito de no máximo **3 níveis de aninhamento** lógico por método. Mantenha os métodos concisos (alvo: 50 linhas).

---

## 15. Tipagem de Parâmetros e Retornos de Funções

Sempre que uma função ou método receber **mais de um parâmetro**, os parâmetros devem ser encapsulados em um objeto tipado. O mesmo se aplica ao retorno quando ele for composto.

### 📐 Regras

- **Parâmetros:** Criar um `type` dedicado com sufixo `Params`, nomeado após a função: `NomeDaFuncaoParams`.
- **Retorno:** Criar um `type` dedicado com sufixo `Result`, nomeado após a função: `NomeDaFuncaoResult`.
- **Localização:** Os tipos devem residir em uma pasta `types/` dentro do mesmo módulo da função, em arquivo com sufixo `*.types.ts`.

```ts
// types/ProcessOrderParams.types.ts
type ProcessOrderParams = {
  readonly orderId: string;
  readonly userId: string;
  readonly amount: number;
};

type ProcessOrderResult = {
  readonly transactionId: string;
  readonly processedAt: Date;
};

// use-cases/ProcessOrder.use-case.ts
function processOrder(params: ProcessOrderParams): ProcessOrderResult {
  // ...
}
```

```text
modules/
└── Order/
    ├── use-cases/
    │   └── ProcessOrder.use-case.ts
    └── types/
        └── ProcessOrder.types.ts   <-- ProcessOrderParams + ProcessOrderResult
```

- **Proibido:** Funções com mais de 1 parâmetro posicional — use sempre o objeto tipado.

---

## 10. Observabilidade e Logs Narrativos

- **Máscara Padronizada:** `[traceId][timestamp][appName][traceStack...][source][lib][LEVEL] - message - meta`

---

## 11. Cultura de Qualidade Automatizada (TDD)

- Cobertura via TDD cobrindo caminhos felizes e de falha nos testes unitários e ponta a ponta (E2E) rodando isoladamente usando `env.test.e2e`.

---

## 12. Curadoria de Bibliotecas e Inovação Tecnológica

Antes de adicionar qualquer nova dependência ou reinventar a roda, a I.A. ou o desenvolvedor deve realizar uma pesquisa proativa:

- **As Melhores e Mais Modernas:** Buscar sempre as bibliotecas mais modernas, seguras e ativamente mantidas pela comunidade para resolver o problema.
- **Compatibilidade Arquitetural:** Avaliar estritamente se a biblioteca escolhida é aderente à arquitetura do ecossistema (compatível com Bun, suporte a alto rendimento, tipagem nativa em TypeScript, sem gargalos de I/O bloqueante).

---

## 13. Documentação Viva e Sincronização com I.A.

Todo projeto dentro do monorepo deve obrigatoriamente manter documentações atualizadas e acessíveis.

- **Documentação de Roteamento:** Cada API deve ter seus endpoints, payloads esperados e contratos de WebSockets rigorosamente documentados (ex: via Swagger/OpenAPI ou arquivos Markdown dedicados na raiz do módulo).
- **Documentação de Negócio:** As regras de domínio complexas e o fluxo de decisão devem estar documentados para justificar o _porquê_ das implementações.
- **Sincronização Contínua com a I.A. (`init-claude.md`):** O projeto deve manter um arquivo de inicialização de contexto na raiz (ex: `init-claude.md`, `.cursorrules` ou `ai-context.md`). **Regra inquebrável:** Ao final de qualquer modificação de arquitetura, adição de nova rota ou alteração em regras de negócio, este arquivo de configuração **deve ser obrigatoriamente atualizado** para refletir o estado atual do projeto, garantindo que as ferramentas de I.A. iniciem as próximas tarefas sempre com o contexto correto e mais recente.

---

## 14. 🛡️ Auditoria Final (Go-Live: Segurança & Performance)

É estritamente obrigatório que a I.A. ou o desenvolvedor, **ao final da implementação de qualquer projeto ou funcionalidade**, execute uma auditoria proativa:

- **Auditoria de Performance:** Validar queries N+1, certificar que todo I/O é assíncrono (não bloqueante) e verificar o uso correto de estruturas otimizadas (`Sets`, `Maps` vs `Arrays`).
- **Auditoria de Segurança:** Revisar a higienização de logs (sem PII), garantir o tratamento rigoroso de inputs na entrada das rotas e confirmar que não há vazamento de Stack Traces HTTP 500 para o cliente.

## 16. Extração de Strings Repetidas em Constantes e Fábricas de Configuração

Toda string literal que aparecer **2 ou mais vezes** no codebase — seja como valor de variável, argumento de função, chave de objeto ou condicional — deve ser extraída para uma constante nomeada (`SCREAMING_SNAKE_CASE`) no arquivo `*.constant.ts` do escopo mais próximo.

### 📐 Gatilhos de Extração

- **Literais de domínio repetidos:** status, eventos, tipos, chaves de roteamento (ex: `'pending'`, `'approved'`, `'order.created'`)
- **Strings de configuração de infraestrutura:** nomes de filas, exchanges, tópicos, prefixos de cache
- **Níveis e categorias de log:** `'info'`, `'error'`, `'warn'`, `'debug'` — nunca literais espalhados no código
- **Rotas e prefixos de URL internos:** `'/v1/orders'`, `'/healthcheck'`
- **Mensagens de erro e códigos de rastreio:** qualquer string passada para `BaseError` ou similar

### 📐 Regra de Escopo da Constante

| Repetição ocorre em...           | Onde declarar                                        |
| -------------------------------- | ---------------------------------------------------- |
| Dentro de um único módulo        | `src/modules/<Modulo>/shared/<Modulo>.constant.ts`   |
| Entre módulos da mesma aplicação | `src/modules/shared/shared.constant.ts`              |
| Entre aplicações do monorepo     | `packages/<ContextoProvider>/<Contexto>.constant.ts` |

### 📐 Fábricas de Configuração Pré-existentes

Quando uma estrutura de configuração se repete em múltiplos pontos (ex: opções de conexão, configuração de canal RabbitMQ, opções do logger), ela deve ser centralizada em uma **função fábrica** nomeada com o prefixo `build` ou `create`, localizada em `*.constant.ts` ou em um arquivo dedicado `*.factory.ts`.

```ts
// shared/Log.constant.ts
export const LOG_LEVEL = {
  INFO: "info",
  ERROR: "error",
  WARN: "warn",
  DEBUG: "debug",
} as const;
export type LogLevel = (typeof LOG_LEVEL)[keyof typeof LOG_LEVEL];

// shared/RabbitMq.constant.ts
export const RABBITMQ_EXCHANGE = {
  ORDER_EVENTS: "order.events",
  PAYMENT_EVENTS: "payment.events",
} as const;

export const RABBITMQ_QUEUE = {
  PROCESS_PAYMENT: "payment.process",
  SEND_EMAIL: "notification.email",
} as const;

// shared/RabbitMqChannel.factory.ts
export function buildChannelOptions(prefetchCount: number) {
  return { prefetch: prefetchCount, noAck: false };
}
```

```ts
// ❌ Errado — literal espalhado em 3 lugares diferentes
logger.log("info", "Pedido criado");
logger.log("info", "Pagamento aprovado");
if (level === "error") notifyOncall();

// ✅ Correto — centralizado e tipado
import { LOG_LEVEL } from "@/modules/shared/Log.constant";

logger.log(LOG_LEVEL.INFO, "Pedido criado");
logger.log(LOG_LEVEL.INFO, "Pagamento aprovado");
if (level === LOG_LEVEL.ERROR) notifyOncall();
```

### 📐 Critério de Decisão para a I.A.

Ao gerar ou revisar código, a I.A. deve:

1. Varrer o escopo atual em busca de strings idênticas ou semanticamente equivalentes já existentes
2. Se encontrar 2+ ocorrências — **parar e extrair** antes de continuar
3. Se a constante já existe em outro módulo — **importar, nunca redeclarar**
4. Se a string é temporária e específica de um único teste — pode permanecer literal

---
