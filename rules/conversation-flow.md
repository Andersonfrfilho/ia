# 💬 Fluxos de Conversa — Núcleo (V1)

Regras normativas para o texto que o bot fala e para a forma como ele oferece escolha.
Bloqueantes em code review, e válidas para todo produto do ecossistema com atendimento
automatizado (WhatsApp, widget de site, ou qualquer canal futuro).

O canal impõe limites que o editor de fluxo não mostra. Passar deles não degrada a mensagem:
a Graph API **recusa a mensagem inteira** e o cliente vê silêncio — falha que só aparece em
produção, com o lead do outro lado.

## 1. Onde o texto vive

- O grafo em código (`defaultFlow.constant.ts` ou equivalente) é **ponto de partida**, não a
  fonte da verdade. Ele serve para a base nascer com conversa publicada.
- Depois da primeira publicação, **a versão do banco manda**. Editar o arquivo em código não
  muda o que o cliente lê hoje.
- Todo produto com fluxo editável precisa de **dois caminhos**: edição pelo fluxograma do
  painel (o normal) e um comando de **republicação versionada** a partir do código (para
  ambiente novo, rollback e revisão em PR).
- Republicação nunca sobrescreve em silêncio: sobe versão nova, e a anterior continua no
  histórico.

## 2. Escolha — botão ou lista

| Opções | Formato | Teto do título |
|---|---|---|
| 1 a 3 | **Botão de resposta rápida** (`interactive.type: button`) | 20 caracteres |
| 4 a 10 | **Lista** (`interactive.type: list`) | 24 caracteres por linha |
| acima de 10 | ❌ não existe — quebrar em dois nós | — |

- **≤3 opções sempre vira botão.** A lista custa um toque a mais para abrir e esconde a
  escolha atrás de um rótulo genérico ("Ver opções"); com duas alternativas isso é atrito puro.
- Os limites vivem em constante compartilhada (`WHATSAPP_CHOICE_LIMIT`), nunca como número
  solto no meio do código.
- **O tamanho do título é validado na publicação do fluxo**, não no envio. Descobrir o estouro
  quando a Meta recusa é descobrir tarde.
- O emoji **conta como caractere** no orçamento do título — em botão, ele custa ~3 dos 20.
- Canal que não sabe enviar botão cai na lista automaticamente. A capacidade é opcional por
  ausência; nunca uma flag `hasButtons`.

## 3. Emoji

- **Todo botão de resposta rápida leva emoji explícito**, antes do rótulo. Numa lista de
  escolhas curtas o olho acha o símbolo antes de ler a palavra, e é aí que o emoji paga.
- Linha de lista segue a mesma regra quando o texto couber nos 24 caracteres.
- No corpo da mensagem o emoji é bem-vindo com parcimônia: **no máximo um por parágrafo**, e
  nunca substituindo palavra ("Falamos por 📞" é adivinhação, não comunicação).
- O mesmo emoji significa a mesma coisa em todo o produto (✅ confirmar, 🔙 voltar,
  🙋 falar com pessoa, 📊 dados, 💬 atendimento).
- **Isto não contradiz `web.md` §9**, que proíbe emoji na UI de produto. Lá o emoji seria
  ícone de interface, renderizado pelo nosso CSS; aqui ele é **conteúdo da conversa**,
  renderizado pelo cliente de mensagem — o WhatsApp não aceita SVG no título do botão.

## 4. Formatação

- Marcação única para todos os canais, na convenção do WhatsApp: `*negrito*`, `_itálico_`.
  Quem escreve o fluxo escreve **uma vez**.
- Canal que não entende a marcação nativamente **traduz na renderização** — nunca se escreve
  o texto duas vezes, e nunca se aceita que o asterisco vaze como literal para o usuário.
- **A tradução jamais passa por `innerHTML`.** O texto vem do editor de fluxo, que é entrada
  de usuário: a renderização monta nó de texto e elemento por `createElement`, e ponto.
- Negrito serve para **o nome do produto e o número que decide** — não para frase inteira.
  Itálico para ressalva curta. Mais de dois destaques na mesma mensagem não destacam nada.
- Proibido: título em CAIXA ALTA, `~tachado~` para preço, e marcação dentro de rótulo de
  botão (o WhatsApp não interpreta lá — sai o asterisco).

## 5. Ritmo da conversa

- **Uma ideia por mensagem.** Descrição de produto e pergunta seguinte são mensagens
  separadas — o bloco único faz a pergunta desaparecer no fim do parágrafo.
- Corpo de mensagem com no máximo ~3 linhas no celular. Texto longo vira duas mensagens ou
  vira conversa com uma pessoa.
- Toda pergunta termina em **uma pergunta só**. Duas perguntas na mesma mensagem produzem
  resposta para uma delas.
- Todo nó de escolha declara `fallbackMessage`. Sem ela o cliente que digita fora do menu
  recebe o nó repetido sem explicação.
- Depois de N tentativas fora do fluxo (padrão: 2), **chama uma pessoa**. O bot não improvisa
  resposta.
- Todo caminho do grafo termina em fim explícito ou em handoff. Nó sem saída é conversa que
  morre calada.

## 6. LGPD no texto

- O bot pede **o mínimo para o retorno**: nome e um contato. Nada de CPF, data de nascimento,
  renda ou endereço num fluxo automatizado.
- Nenhum texto de fluxo pede dado sensível "para agilizar" — se a etapa precisa disso, ela é
  atendimento humano em canal apropriado.
- O que o cliente digita é conteúdo de mensagem: **nunca vai para log**, em nenhum nível
  (ver `security.md` §1).

## 7. Identificadores

- `id` de opção e de nó são **estáveis e sem acento** (`falar`, `voltar`, `produto_dados`):
  eles vão para o histórico, para métrica e para o `byAnswer` do grafo. Renomear rótulo é
  barato; renomear id quebra conversa em andamento.
- O rótulo é o que o cliente lê; o id é o que o sistema casa. Nunca use o rótulo como chave.

## 8. Checklist de aceite de um fluxo

- [ ] Nenhum título de opção acima do teto do formato que ele vai usar
- [ ] Todo nó com ≤3 opções sai como botão; com 4+ sai como lista
- [ ] Todo botão de resposta rápida tem emoji
- [ ] Marcação `*`/`_` renderiza certo **nos dois canais**, verificada em ambos
- [ ] Todo nó de escolha tem `fallbackMessage`
- [ ] Todo caminho termina em fim ou handoff
- [ ] Nenhum texto pede dado sensível
- [ ] Ids de nó e opção sem acento e estáveis
- [ ] Mudança de texto em produto já publicado tem caminho de republicação versionada

## 9. 🤖 Modelo recomendado

| Etapa | Modelo |
|---|---|
| Desenhar o grafo (nós, ramificação, pontos de handoff) | `opus` 🧠 |
| Escrever e revisar o texto das mensagens | `sonnet` |
| Passe mecânico de emoji, corte de título, ajuste de limite | `haiku` |
