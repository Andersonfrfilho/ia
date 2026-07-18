# Banco de dados — PostgreSQL e Drizzle

## Stack obrigatória

- PostgreSQL é o banco relacional padrão.
- Drizzle ORM é o acesso tipado padrão e Drizzle Kit gerencia migrations.
- Aplicações Bun podem usar o driver PostgreSQL nativo do Bun quando a versão
  instalada do Drizzle declarar suporte; qualquer outro driver deve ser
  justificado no ADR da aplicação.
- Prisma não deve ser introduzido em projetos novos.

## Schema e migrations

- Schema é código TypeScript estrito, sem `any`.
- Toda alteração persistente gera migration SQL versionada e revisável.
- `drizzle-kit push` é permitido apenas em ambiente local descartável; CI,
  staging e produção aplicam migrations versionadas.
- Migration destrutiva, alteração de tipo com perda ou remoção de constraint
  exige plano de expansão/contração, rollback e aprovação humana.
- Dinheiro usa `numeric`/decimal e nunca `real`, `double precision` ou `number`
  como representação persistente de valor monetário.

## Consistência e multiempresa

- Operações concorrentes e efeitos externos usam transação, constraint e chave
  de idempotência apropriadas.
- Entidades multiempresa carregam `companyId` e índices/uniques incluem o tenant
  quando a regra for por empresa.
- `companyId` vem do contexto autenticado; nunca de um valor livre do cliente.
- Queries de negócio devem filtrar o tenant por construção e possuir testes
  negativos de isolamento.
- SQL manual só é permitido via template parametrizado do Drizzle, com motivo
  documentado e teste de integração.

## Separação de aplicações

- Cada aplicação continua publicável e executável de forma independente.
- Schema ou adapters compartilhados entre API e worker devem ser uma biblioteca
  versionada; não use import relativo atravessando diretórios de aplicações.
- Bibliotecas reutilizáveis do ecossistema devem ser publicadas no repositório
  oficial de packages, conforme a regra local da organização.
