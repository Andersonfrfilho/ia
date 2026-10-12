# 🧹 Sessões OMC: fechar o que não é mais necessário

Regra global. Um modo OMC (autopilot, ralph, ultragoal, ralplan, team) deixado ativo sem trabalho por
trás faz o hook de parada **bloquear sessões que não têm nada a ver com ele** e reforçar uma tarefa que
já acabou. O estado fica em `<projeto>/.omc/state/sessions/<id>/` e **não some sozinho**.

## 1. Fechar o modo desta sessão quando o trabalho acaba

- Terminou a tarefa (ou o usuário só pediu algo que não é executar o modo): `/oh-my-claudecode:cancel`
  na mesma resposta. Nunca encerrar um turno deixando autopilot/ralph/ultragoal ativo sem motivo.
- **A palavra "autopilot" na mensagem não é ordem de executar.** "Crie um prompt para o autopilot",
  "revise o prompt do autopilot" ou colar um prompt para guardar são pedidos de TEXTO. O hook liga o modo
  mesmo assim: se o usuário não pediu para executar, cancele o modo logo, antes de seguir.
- Cancelar autopilot é **pausa**, não apagar: `state_write(mode="autopilot", session_id, active=false)`.
  Nunca `rm` no arquivo de estado de autopilot (perde o resumo).

## 2. Higiene das sessões antigas (fazer sempre que `state_list_active` mostrar algo que não é desta sessão)

1. Liste com `state_list_active` e leia cada uma com `state_read`.
2. Classifique antes de tocar em qualquer uma, **pelo transcript da conversa**:
   `stat -f "%Sm" -t "%Y-%m-%d %H:%M" ~/.claude/projects/*/<session-id>.jsonl`
   - **Viva (não tocar):** transcript modificado nas últimas ~2 h, ou processo `claude` ativo da janela.
     É de outra janela do usuário; fechar mataria o trabalho dele.
   - **Obsoleta (fechar):** transcript parado há mais de ~12 h e/ou estado de dias atrás, sem processo,
     ou o objetivo do prompt já foi concluído.
   - **Dúvida:** mostrar a tabela e perguntar. Nunca adivinhar.
3. **Mostrar a tabela ao usuário** (id, início, última atividade, veredito) antes ou junto de fechar.
4. Fechar as obsoletas pelo caminho que preserva o que importa:
   - autopilot: `state_write(active=false)` (retomável);
   - ultragoal: `state_clear(mode="ultragoal", session_id)` (só a trava; plano e ledger em `.omc/ultragoal/`
     ficam);
   - ralph/ralplan/team: `state_clear` com o `session_id` da sessão, nunca sem `session_id`.
5. **Nunca** usar `state_clear` sem `session_id` nem `--force/--all` para "limpar tudo": isso atinge as
   sessões das outras janelas.

## 2b. Quando pesquisar

No começo de uma tarefa longa, quando o stop hook bloquear algo que não é desta sessão, e ao ver o
cabeçalho `[AUTOPILOT - Phase: unspecified]` sem que se esteja executando autopilot. O hook pode estar lendo
o estado de OUTRA sessão: identifique a dona antes de agir.

## 3. Registro

Ao fechar sessões, relatar no fim da resposta quais foram fechadas, quais foram deixadas e por quê. Se a
decisão for repetida (mesma sessão obsoleta de novo), a causa é um modo que não foi cancelado ao terminar:
corrigir isso na origem (item 1), não só limpar.
