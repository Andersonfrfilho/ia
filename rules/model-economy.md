# 🤖 Protocolo de Seleção de Modelos (Custo-Eficiência)

Regra global para toda documentação de execução (specs, `tasks.md`, roadmaps)
e para toda I.A. executando tasks em qualquer projeto.

## 1. Ao documentar (spec-driven development)

Todo documento de tasks/fases (`tasks.md` ou equivalente) **deve** declarar o
**modelo recomendado** por fase (e por task, quando divergir da fase), usando
a tabela de papéis:

| Modelo | Papel |
|---|---|
| `haiku` | Mecânico: traduções, renomes, passes de ícones/tokens, migrações repetitivas de componentes |
| `sonnet` | **Padrão de execução**: CRUDs, bugs, telas, migrations simples, queries com aceite verificável |
| `opus` / `fable` | 🧠 Arquitetura: design docs, modelo de dados novo, integrações entre repos, spikes, decisões estruturais |

Formato padrão sob o título da fase:

```markdown
## Fase N — <nome>
> 🤖 Modelo: `sonnet` (Tx.y é 🧠 — validar com `opus` antes)
```

- Tasks que exigem upgrade pontual dentro de uma fase barata são marcadas
  com **🧠**.
- Racional: planejar caro, executar barato — a spec detalhada (contexto,
  arquivos, critério de aceite) é o que permite usar modelo menor com
  segurança.

## 2. Ao executar tasks

**Regra inquebrável:** ao iniciar uma fase ou task, a I.A. deve comparar o
modelo da sessão atual com o recomendado no documento. Se divergirem:

1. **PARAR antes de tocar em código.**
2. **Perguntar ao usuário** para rodar o comando de troca:
   `Fase N recomenda 'sonnet' — rode /model sonnet e me avise para continuar.`
3. Ao concluir uma task 🧠 dentro de fase barata, pedir a volta ao modelo
   barato da fase.

- A I.A. nunca assume a troca como feita — aguarda confirmação do usuário.
- Exceção: se o usuário disser explicitamente para seguir com o modelo atual,
  registrar isso e continuar sem repetir a pergunta na mesma fase.

## 3. Guard-rails obrigatórios com modelo barato

Executar com `haiku`/`sonnet` exige os gates de qualidade em **toda** task:
- `tsc --noEmit` (ou typecheck equivalente) — runtimes como `tsx` não
  type-checam e escondem erros reais.
- Testes/validação do projeto (`make validate` ou equivalente).
- Commit isolado por task para rollback barato.

## 4. Spec fechada termina com o prompt de autopilot

**Toda sessão que produz ou atualiza uma spec** (`spec.md` + `plan.md` + `tasks.md`, ou
equivalente) termina entregando ao usuário **um prompt pronto para `/oh-my-claudecode:autopilot`**
que execute aquela spec. Planejar caro e executar barato só funciona se a passagem de uma
coisa para a outra não depender de o usuário remontar o contexto de cabeça.

O prompt vai **no fim da resposta**, num bloco de código copiável, e também ao pé do
`tasks.md` numa seção `## Prompt de execução`, para sobreviver ao fim da sessão.

Ele declara, sempre:

- **O caminho da spec** (`specs/NNN-nome/`) e a instrução de ler `spec.md`, `plan.md` e
  `tasks.md` antes de tocar em código.
- **O modelo por fase**, copiado da tabela do `tasks.md` (§1), com as tasks 🧠 nomeadas —
  e a ordem de delegação: fase `sonnet`/`haiku` vai para subagente `executor` com
  `model=<modelo>`; task 🧠 roda com `opus` (ou é validada por `architect`/`critic` em
  `opus` antes de implementar).
- **Os gates do §3** que fecham cada task (typecheck, testes/`make check`, commit isolado)
  e o registro de evidência em `evidence.md`.
- **O que o autopilot não decide sozinho**: deploy, migration destrutiva, `[NEEDS
  CLARIFICATION]` aberto — nesses pontos ele para e pergunta.

Formato:

```text
/oh-my-claudecode:autopilot Execute a spec specs/NNN-nome/ (leia spec.md, plan.md e tasks.md
antes de começar). Uma task por vez, na ordem do tasks.md.
Modelos: Fase 1 → executor model=sonnet · Fase 2 → executor model=haiku ·
T2.3 🧠 → opus (validar com architect antes) · revisão final → code-reviewer model=opus.
Cada task fecha com typecheck + testes + commit isolado, evidência em evidence.md.
Pare e pergunte antes de: deploy, migration destrutiva, qualquer [NEEDS CLARIFICATION].
```

- Spec com `[NEEDS CLARIFICATION]` aberto **não** ganha prompt de execução — ganha a lista
  das perguntas pendentes no lugar dele.
- O prompt não substitui o §2: ao executar, a I.A. ainda confere o modelo da sessão contra
  o da fase.
