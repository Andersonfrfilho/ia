## 5. ⚡ BullMQ (Filas Leves sobre Redis)

O **RabbitMQ** continua sendo o broker padrão e preferencial do ecossistema (ver `worker.md`) para
mensageria entre serviços. O **BullMQ** é uma exceção deliberada e restrita a um cenário específico:
filas de job leves rodando sobre uma instância de **Redis que já existe no projeto** por outro motivo
(cache, sessões, rate limiting), onde subir um RabbitMQ dedicado só para um ou dois tipos de job seria
overhead desproporcional de operação.

### 📐 Quando usar BullMQ em vez de RabbitMQ

- **Redis já está rodando no projeto** por outra razão (cache, `CacheProvider`, sessões) — reaproveitar
  a mesma infraestrutura em vez de introduzir um broker novo.
- **Volume de jobs pequeno a médio** — dezenas a poucos milhares de jobs/dia, não milhões.
- **Topologia simples** — fila direta produtor → worker, sem necessidade de roteamento avançado por
  Exchange (Direct/Topic/Fanout). No momento em que o roteamento avançado ou múltiplos bindings por
  mensagem se tornam necessários, é sinal de migrar para RabbitMQ.
- **Não é a escolha padrão.** Se o projeto ainda não tem Redis rodando, ou se o volume/roteamento
  justificam uma Exchange, use RabbitMQ conforme `worker.md`. BullMQ é reuso oportunista de
  infraestrutura existente, não uma alternativa geral ao RabbitMQ.

### 📐 Conexão dedicada

- O client Redis usado pelo BullMQ **deve ser uma instância `ioredis` separada** de qualquer client já
  usado para cache/sessão, configurada com `maxRetriesPerRequest: null` — BullMQ exige isso e valores
  padrão de retry usados pelo client de cache quebram o comportamento de bloqueio interno da lib.
- Se o processo também precisa fazer `subscribe` (ex.: relay de eventos entre processos), use uma
  **terceira** conexão dedicada ao modo subscriber — uma conexão em modo subscribe não pode executar
  outros comandos.

### 📐 Bull Board — Observabilidade Obrigatória

- Todo uso de BullMQ **deve** vir acompanhado do **Bull Board** (`@bull-board/api` +
  adapter correspondente ao framework HTTP do projeto) para inspeção visual de filas, jobs
  pendentes/falhos e retries.
- Expor o dashboard em porta própria, **nunca** no domínio público do serviço principal, protegido por
  autenticação básica (usuário/senha via variáveis de ambiente). Tratar como ferramenta interna de
  operação, acessível apenas via rede privada do cluster ou ambiente local — mesmo espírito de
  endpoints internos como `/metrics`.

### 📐 Retenção e Limpeza — Sempre Limitada, Nunca Ilimitada

É **proibido** deixar `removeOnComplete`/`removeOnFail` sem limite (`true` sem bounds, ou omitidos —
o que faz o Redis acumular jobs indefinidamente). Toda `Queue` deve declarar `defaultJobOptions` com
limites explícitos de idade **e** contagem, calibrados por queue conforme o perfil do job:

```ts
// Job de alta frequência, baixo valor de auditoria (ex.: processamento de mídia recebida)
{
  removeOnComplete: { age: 24 * 3600, count: 500 },       // horas a poucos dias
  removeOnFail:     { age: 7 * 24 * 3600, count: 1000 },  // falhas vivem mais que sucessos
}

// Job de baixa frequência, relevante para auditoria (ex.: envio de documento, cobrança)
{
  removeOnComplete: { age: 7 * 24 * 3600, count: 2000 },   // 1–4 semanas
  removeOnFail:     { age: 30 * 24 * 3600, count: 2000 },
}
```

### 📐 Regra de Calibração por Contexto

| Perfil do job | Retenção de sucesso | Retenção de falha |
|---|---|---|
| Alta frequência / baixo valor de auditoria | Horas a poucos dias | Alguns dias a 1 semana |
| Baixa frequência / relevante para auditoria (envios, cobranças, integrações externas) | 1 a 4 semanas | Sempre maior que a de sucesso — falhas devem sobreviver mais tempo para investigação |

- **Falhas sempre vivem mais que sucessos** da mesma queue — um job falho é evidência de um problema
  não resolvido e não deve desaparecer antes de ser investigado.
- Além dos `removeOn*` por job, manter um job de limpeza periódico (`queue.clean(...)` agendado, ou um
  repeatable job do próprio BullMQ) como *backstop* — garante retenção correta mesmo se as opções de
  um job específico forem configuradas incorretamente no futuro.

### 📐 Idempotência e Confirmação

- Assim como no RabbitMQ (`worker.md`), processors do BullMQ podem receber o mesmo job mais de uma vez
  em cenários de retry/instabilidade. Todo processor deve verificar se o efeito já foi aplicado (ex.:
  checar se o registro-alvo já existe) antes de reprocessar.
- BullMQ confirma sucesso automaticamente quando o processor retorna sem lançar exceção, e falha
  automaticamente (acionando retry, conforme `attempts`/`backoff` configurados na `Queue`) quando o
  processor lança. Nunca engolir erros dentro do processor apenas para evitar o retry — se o erro é
  transitório, deixe o BullMQ re-tentar; se é fatal, deixe o job ir para `failed` para aparecer no
  Bull Board.
