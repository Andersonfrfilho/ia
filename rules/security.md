# 🛡️ Regras de Segurança por Stack

Baseline normativo deste ecossistema. Toda I.A. ou pessoa desenvolvendo deve tratar estas
regras como bloqueantes: um item marcado **OBRIGATÓRIO** reprova o code review.

## 0. Referências normativas (fonte da verdade)

| Assunto | Documento | Uso |
|---|---|---|
| Riscos de aplicação web | [OWASP Top 10:2025](https://owasp.org/Top10/2025/) | Vocabulário de risco; checklist de PR |
| Verificação detalhada | [OWASP ASVS 5.0](https://github.com/OWASP/ASVS) | Nível 2 é o alvo para produto com dado pessoal |
| APIs | [OWASP API Security Top 10 (2023)](https://owasp.org/API-Security/editions/2023/en/0x00-header/) | BOLA/BOPLA são os campeões em API REST |
| Guias práticos | [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/) | Implementação concreta (JWT, logging, senha, CSP) |
| Dado pessoal (BR) | LGPD Lei 13.709/2018 — arts. 6º, 46, 48 | Minimização, segurança, notificação de incidente |
| Node/Bun | [OWASP NodeJS Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Nodejs_Security_CheatSheet.html) | Runtime |
| Supply chain | [SLSA](https://slsa.dev/) + `A03:2025 Software Supply Chain Failures` | Lockfile, pin, provenance |
| Contêiner / infra | [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks) | Docker, Postgres, Redis |
| WhatsApp Cloud API | [Meta — Webhooks Security](https://developers.facebook.com/docs/graph-api/webhooks/getting-started#validate-payloads) | Assinatura `X-Hub-Signature-256` |

Duas mudanças de 2025 que afetam este repositório diretamente:
`A02 Security Misconfiguration` subiu para 2º lugar (defaults inseguros contam como vulnerabilidade),
e `A03 Software Supply Chain Failures` passou a cobrir build e distribuição, não só dependência vulnerável.

---

## 1. Dados pessoais e logs (LGPD) — **OBRIGATÓRIO**

- **Proibido logar PII em qualquer nível**, inclusive `debug`: telefone, CPF, e-mail, nome completo,
  data de nascimento, renda, endereço e **corpo de mensagem de cliente**.
- Telefone, quando indispensável para correlação, entra **mascarado** (`****1234`) por uma função
  central de redação — nunca formatado no call site.
- Identificadores opacos (`conversationId`, `leadId`, `messageId`) são a forma correta de rastrear.
- A redação vive no logger, não na disciplina de quem escreve o log: defesa em profundidade.
- Headers `authorization`, `cookie`, `x-api-key`, `x-hub-signature-256` sempre `[REDACTED]`.
- Stack trace nunca sai na resposta HTTP; só no log de servidor.

## 2. Autenticação e autorização — **OBRIGATÓRIO**

- Access token de vida curta (≤15 min) + refresh rotativo com invalidação do anterior.
- **Nenhum token estático e eterno com permissão curinga (`*:*`).** Integração máquina-a-máquina
  (n8n, worker) recebe escopo enumerado das rotas que realmente usa, e o token é rotacionável.
- Comparação de segredo sempre `timingSafeEqual` sobre digests de tamanho fixo.
- Autorização é verificada **por objeto**, não só por rota (BOLA/API1): checar que o recurso
  pertence ao tenant/usuário do token.
- Painéis operacionais (Bull Board, Adminer, Metabase) nunca sobem com credencial default nem com
  fallback para string vazia — **falha no boot** se a variável não existir.

## 3. Entrada, saída e transporte

- Zod em toda fronteira: body, query, params, headers relevantes, payload de fila e resposta de
  terceiro. Validar resposta de API externa também — ela é entrada não confiável.
- CORS com allowlist explícita de origens; nunca `*` em rota autenticada.
- Headers em toda resposta: `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` restritiva,
  `Strict-Transport-Security`, e CSP sem `unsafe-inline` no frontend.
- Rate limit **global** por IP e por usuário autenticado, com limite mais duro em login, webhook
  público e qualquer rota que dispare custo externo (envio WhatsApp, IA).
- Todo webhook público valida assinatura HMAC com `rawBody`, rejeita timestamp fora da janela e
  guarda nonce para impedir replay. Fail-closed: sem segredo configurado, a rota não sobe.

## 4. Segredos e supply chain (A03:2025)

- Segredo só existe como variável de ambiente validada por schema no boot. Nunca em código,
  commit, log, comentário ou output de terminal.
- **Segredo que apareceu em terminal/CI/log é segredo queimado** — rotacionar, sem exceção.
- `VITE_*` é público por definição: o Vite inlina o literal no bundle. Nenhum segredo com esse prefixo.
- Lockfile commitado e CI com `--frozen-lockfile`. Dependência nova exige justificativa
  (§12 do code-standart) e checagem de manutenção ativa.
- CI roda auditoria de dependência e falha em vulnerabilidade alta/crítica sem exceção registrada.
- Nada de instalar pacote por nome sugerido por I.A. sem conferir que existe e é o oficial
  (slopsquatting).

## 5. Banco de dados (Postgres + Drizzle)

- Query parametrizada sempre; `sql.raw()` só com valor que nunca vem do usuário, e comentado.
- Campo sensível em repouso (CPF, data de nascimento, renda) criptografado com chave de aplicação
  separada da chave do banco.
- Banco sem exposição pública; acesso só pela rede interna.
- Migration é aditiva por padrão; `DROP`/`NOT NULL` retroativo exige plano de rollback escrito.
- Backup criptografado **antes** do upload para o bucket, com a chave fora do bucket.

## 6. Filas (BullMQ + Redis)

- Payload de job carrega **referência**, não dado pessoal: id do lead, chave do objeto no storage.
- Retenção obrigatória (`removeOnComplete` / `removeOnFail`) em toda fila — Redis não é log.
- Job com efeito externo é idempotente (chave de idempotência) e tem `attempts` + backoff exponencial.
- Redis com senha e sem exposição pública; DLQ/falhas com alerta, não só acumulando.

## 7. Storage S3-compatível

- Bucket privado por padrão; entrega por presigned URL de vida curta.
- URL pública só para asset comprovadamente não sensível (logo, ícone).
- Nunca colocar dado pessoal no **nome** da chave do objeto.
- Credencial de bucket por ambiente — staging e produção jamais compartilham chave.

## 8. Frontend (React + Vite)

- Token em memória ou cookie `HttpOnly`+`Secure`+`SameSite`; nunca `localStorage` para refresh token.
- Sem `dangerouslySetInnerHTML` com conteúdo de origem externa; se inevitável, sanitizar.
- Nenhum dado pessoal em query string, `console.log` de produção ou telemetria de terceiro.
- Feature flag não substitui autorização: a API valida sempre, mesmo que a UI esconda.

## 9. n8n e automações

- Workflow não guarda segredo em nó: só credencial do n8n ou variável de ambiente.
- `jsCode` trata payload de webhook como hostil; sem `eval` e sem construir SQL por concatenação.
- Alteração só pelo pipeline CI/CD — edição direta no painel é violação de rastreabilidade (A02).

## 10. Auditoria contínua

- Toda ação sensível (takeover de conversa, envio de template, alteração de configuração, login,
  exportação de dados) grava trilha de auditoria com ator, alvo, IP e timestamp.
- Ao fechar qualquer feature, rodar a auditoria do §14 do `code-standart.md` com esta lista em mãos.
- Achado de segurança vira item priorizado no `docs/SECURITY.md` do projeto, com data — não some
  no histórico do chat.
