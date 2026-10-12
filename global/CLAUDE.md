@RTK.md

# Standards

@standards/code-standards.md
@standards/typescript.md
@standards/react.md
@standards/nodejs.md
@standards/apis.md
# Leitura de arquivos — economia de contexto

Metade do contexto gasto com `Read` é releitura do mesmo arquivo na mesma sessão.
Isso se auto-alimenta: a compactação descarta o conteúdo, o arquivo é lido de novo,
o contexto enche, compacta outra vez. Um único hook chegou a ser lido 33 vezes numa
sessão, 118.000 tokens.

- Antes de ler, verificar se o arquivo já foi lido nesta sessão. Se foi e não houve
  edição desde então, o conteúdo já está no contexto — não reler.
- Depois de editar, nunca reler o arquivo para conferir: `Edit` e `Write` falham em
  voz alta se não aplicarem, e o harness rastreia o estado.
- Ler o trecho, não o arquivo: `offset` e `limit` quando já se sabe onde está o alvo.
  Arquivo inteiro só quando a estrutura completa importa de fato.
- Varredura ampla — "onde está X", "que arquivos usam Y", convenções espalhadas —
  vai para o agente `Explore`, que lê em contexto separado e devolve só a conclusão.
- Com o índice do socraticode disponível, `codebase_search` antes de `Read`: devolve
  o trecho relevante em vez do arquivo inteiro.
- Reler é legítimo depois de uma compactação ou quando o arquivo mudou por fora
  (git pull, script, outro agente). Nesses casos, reler só a parte que importa.

# Browser — economia de contexto

Imagem de browser é o maior consumidor de contexto que existe: um `screenshot`
custa ~30.000 tokens, um `scroll`/`zoom` do claude-in-chrome ~21.000, e um
`browser_batch` até 72.000 — mais de um terço da janela numa única chamada.
Um clique custa 61 tokens e um `read_page` inteiro custa 600.

- Verificação de UI é por texto: `read_page` (árvore de acessibilidade),
  `get_page_text`, `read_console_messages`, `read_network_requests`, e
  `javascript_tool` para CSS computado ou geometria.
- `screenshot` só como prova final ao usuário, uma vez, ao fim da tarefa —
  nunca para conferir estado intermediário nem para confirmar um clique.
- Nunca usar `zoom` para inspecionar: usar `read_page` com `ref_id`.
- Nunca usar `browser_batch`.
- Rolar com `javascript_tool` (`window.scrollTo`) em vez da ação `scroll`
  quando a ferramenta devolver screenshot.
- Usar só a stack `Claude_Browser`; `claude-in-chrome` apenas quando a tarefa
  exigir sessão logada do Chrome real.

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.


<!-- OMC:IMPORT:START -->
@CLAUDE-omc.md
<!-- OMC:IMPORT:END -->
