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
