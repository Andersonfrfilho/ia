# ✉️ E-mail em HTML vem do modelo do módulo de notificação

Regra global para todo produto que usa `@adatechnology/notification-*` (TransportAdA e os demais).
Decidida pelo dono em 2026-10-18, durante a spec 272 do TransportAdA, depois de uma spec inteira
planejada com montador de layout em código — esforço que o pacote já resolvia.

## Regra — **OBRIGATÓRIO**

1. **O visual do e-mail mora no modelo do módulo de notificação**, escrito em HTML na tela de
   Notificações (`@adatechnology/notification-ui`). Essa tela já tem editor de código HTML no canal
   e-mail, validação (`validateEmailHtml`) e prévia com moldura (`TemplatePreview`, prop `emailHtml`).
   **Proibido** criar montador/layout de e-mail em código no produto (funções que concatenam o HTML,
   `*-mail.template.ts` novo, golden file de layout) para e-mail que o módulo pode carregar.
2. **Modelo novo de e-mail = um arquivo `.html` versionado no repositório do produto + script
   idempotente que grava a versão no módulo por chave.** O arquivo é a fonte; o banco recebe versões.
   Gravar em staging/produção é mudança de dados: pedir aprovação antes de rodar.
3. **O produto injeta o próprio renderer** (o `DefaultTemplateRenderer` do pacote escapa tudo, por
   design). O renderer do produto:
   - interpola `{{campo}}` escapando **só os valores**, nunca o texto do modelo;
   - valida o HTML do modelo com a mesma regra do pacote (sem `script`, `on*`, `javascript:`,
     `iframe`, `form`) e trata modelo inválido como "não utilizável" — nunca envia;
   - gera a parte `text/plain` a partir do HTML renderizado quando o corpo tem marcação;
   - corpo sem tag continua sendo texto (parágrafos), como antes.
4. **Variável que precisa de HTML é montada pelo sistema** (logo `<img src="cid:…">`, tabela de itens,
   rodapé com marcas) e entra no catálogo de variáveis com o nome deixando claro que já é HTML
   (`logoTransportadora`, `tabelaItens`, `marcasRodape`). Todo o resto é texto escapado.
5. **Toda variável nova aparece no catálogo que o editor mostra** (locale/lista de variáveis do painel),
   senão quem edita o modelo não sabe que ela existe.
6. **HTML de e-mail é HTML de e-mail:** tabelas e estilos inline; nada de grid, flex, `var(` ou CSS
   externo. Logo da empresa embutido por `cid:`, nunca base64 inline (o Gmail corta) nem rota pública
   por empresa (enumerável). Marcas fixas da plataforma podem ser URL pública estável.

## Por quê

Layout em código obriga deploy para mudar uma cor, duplica o que a tela do pacote já faz (editor,
validação, prévia) e cria uma segunda fonte de verdade do visual. Com o modelo no módulo, o próximo
e-mail é um arquivo `.html` e um script — não uma spec.

## Ao criar um e-mail novo

1. Conferir se as variáveis necessárias existem no renderer do produto; faltando, acrescentar
   (escapada, ou HTML do sistema pela regra 4) e registrar no catálogo do editor.
2. Escrever o `.html` a partir do desenho aprovado, versionar e gravar por script.
3. Escolher o modelo onde o produto liga o evento ao modelo (no TransportAdA: o tipo de ocorrência).
