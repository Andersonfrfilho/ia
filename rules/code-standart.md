# 📐 Arquitetura e Padrões de Código — Núcleo (V7)

Regras normativas do ecossistema. Bloqueantes em code review.
Detalhamento, exemplos e diagramas: `~/.claude/rules/rules/reference/code-standart.reference.md`.
**Abra o detalhamento quando** for criar um projeto do zero, montar o Makefile/docker-compose,
desenhar a hierarquia de erros de um domínio novo, ou quando uma regra abaixo não bastar para decidir.

## 1. Nomenclatura de arquivos

Sufixo de papel na extensão: `*.use-case.ts`, `*.service.ts`, `*.controller.ts`,
`*.constant.ts`, `*.types.ts` / `*.interface.ts`, `*.schema.ts`, `*.error.ts`.

## 2. Monorepo e stack

- Pastas de execução em `apps/` com prefixo: `api-`, `worker-`, `cron-`, `frontend-`, `mobile-`.
- **api** expõe HTTP/WS e produz mensagens; **worker** só consome fila; **cron** roda agendado;
  micro-serviço só sob necessidade real de isolamento.
- TypeScript em 100%. Runtime **Bun**. Backend com `Bun.serve` — proibido instalar ou importar
  o addon `uWebSockets.js` para Node/V8 em app Bun.
- PostgreSQL com **Drizzle ORM** + Drizzle Kit. Prisma não faz parte da stack.
- Provider consumido por mais de um tipo de projeto vira pacote em `packages/`, configurado
  só por env. **Caminho incerto: parar e perguntar.**

## 3. Código partilhado

- Do domínio: `src/modules/<Modulo>/shared/`.
- Transversal da aplicação: `src/modules/shared/`.

## 4. Ambiente local

- `docker-compose.yml` único na raiz sobe toda a infra. API de terceiro sem sandbox estável
  ganha container de mock.
- Env centralizado em `envs/`: `env.dev`, `env.dev.local`, `env.test`, `env.test.e2e`.
- `Makefile` na raiz abstrai os comandos. Declara `PROJECT_NAME` lido do env do ambiente e
  propaga para todo recurso: `$(PROJECT_NAME)-$(ENV)-<recurso>`. Nome fixo sem prefixo é proibido.

## 5. Seeders

Proibido `INSERT INTO` bruto. Seed instancia e executa os próprios `*.use-case.ts` em sequência.

## 6. Injeção de dependências

Use Cases e Services recebem **interfaces** via construtor. Sem `new` acoplado.

## 7. Erros e exceções

- Códigos centralizados em `shared/errors/codes.ts`, por domínio. Sem código string inline.
- Cada domínio tem hierarquia própria estendendo `DomainError` (que estende `AppError`).
- **Nunca lançar `new AppError(...)` direto** — sempre a classe específica do domínio.
- Erro de domínio pode carregar contexto tipado (ex: `hoursSinceLastMessage`).
- **Use case não faz try/catch.** Controller não captura. Erro propaga para o Exception Filter
  global do Router, que loga e responde.
- Erro desconhecido → 500 genérico, sem stack trace ao cliente, e vai para o Sentry.
- Catch local só para: fallback gracioso, cleanup de recurso, retry com limite.
  Capturar apenas para logar e relançar é proibido — o Router já loga.
- Frontend filtra por código via `getApiErrorCode()`.

## 8. Banco de dados

Proibido ENUM nativo — usar VARCHAR. PK em UUID (v4/v7) para dado público, BigInt sequencial
para contexto interno N:N.

## 9. Complexidade

Máximo 3 níveis de aninhamento lógico por método. Alvo de 50 linhas por método.

## 10. Tipagem de parâmetros e retornos

Função com **mais de um parâmetro** recebe objeto tipado. Tipos com sufixo `Params` e `Result`
nomeados pela função (`ProcessOrderParams`, `ProcessOrderResult`), em `types/*.types.ts` do
mesmo módulo. Mais de 1 parâmetro posicional é proibido.

## 11. Observabilidade

Máscara: `[traceId][timestamp][appName][traceStack...][source][lib][LEVEL] - message - meta`

## 12. Testes

TDD cobrindo caminho feliz e de falha, unitário e E2E, com E2E isolado em `env.test.e2e`.

## 13. Dependências

Antes de adicionar biblioteca: buscar a mais moderna e ativamente mantida, e validar aderência
à arquitetura (compatível com Bun, tipagem nativa, sem I/O bloqueante).

## 14. Documentação viva

Endpoints, payloads e contratos de WebSocket documentados. Regras de domínio complexas
justificadas. **Regra inquebrável:** ao fim de qualquer mudança de arquitetura, rota nova ou
alteração de regra de negócio, atualizar o arquivo de contexto da I.A. na raiz
(`init-claude.md` / `.cursorrules` / `ai-context.md`).

## 15. Auditoria final (go-live)

Ao fim de toda implementação: validar N+1, I/O assíncrono, uso de `Set`/`Map` vs array;
revisar logs sem PII, sanitização de input nas rotas e ausência de stack trace em 500.

## 16. Extração de strings repetidas

String literal que apareça **2 ou mais vezes** vira constante `SCREAMING_SNAKE_CASE` no
`*.constant.ts` do escopo mais próximo. Gatilhos: status e eventos de domínio, nomes de
fila/exchange/tópico, prefixo de cache, níveis de log, rotas internas, mensagens e códigos de erro.

| Repetição ocorre em | Onde declarar |
|---|---|
| um único módulo | `src/modules/<Modulo>/shared/<Modulo>.constant.ts` |
| entre módulos da app | `src/modules/shared/shared.constant.ts` |
| entre apps do monorepo | `packages/<Contexto>/<Contexto>.constant.ts` |

Estrutura de configuração repetida vira função fábrica com prefixo `build` ou `create`, em
`*.constant.ts` ou `*.factory.ts`.

Ao gerar ou revisar código: varrer o escopo por strings equivalentes; achou 2+, **parar e
extrair** antes de continuar; constante já existente em outro módulo se **importa, nunca
redeclara**; literal só permanece se for temporário e de um único teste.

## 17. Copyright

Todo arquivo-fonte abre com cabeçalho de copyright: autor, ano, licença e identificação da
**Ada Technology** (padrão visual em `ada-branding.md`).
