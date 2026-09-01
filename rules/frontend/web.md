# 📐 Frontend Web — Núcleo (V8)

Regras normativas do frontend web. Bloqueantes em code review.
Detalhamento, exemplos e tabelas completas: `~/.claude/rules/rules/reference/web.reference.md`.
**Abra o detalhamento quando** for criar um app frontend do zero, montar os arquivos de tema,
configurar PWA/`vite-plugin-pwa`, ou quando precisar dos valores exatos das escalas de token.

## 1. Stack e arquitetura

- **React** é o padrão, com tooling Bun. **Preact não é adotado** — o React moderno resolveu
  tamanho e performance, e aliases/shims quebram o monorepo.
- Acoplamento entre módulos deve ser **zero**, para que migrar a Micro-Frontends
  (Module Federation) seja só mudança de build tooling.
- Elemento visual que precisa rodar fora do React (widget de chat, header institucional,
  barra de acessibilidade) é **Web Component** nativo (Lit ou Vanilla TS), em pacote isolado
  dentro de `packages/`.
- **Componente de interface vem do shadcn/ui** (Radix + Tailwind), copiado para dentro do repo —
  ver §14. shadcn não é alternativa ao Tailwind: o Tailwind é o motor embaixo dele.

## 2. Nomenclatura de arquivos

`*.component.tsx`, `*.page.tsx`, `*.hook.ts`, `*.query.ts` / `*.mutation.ts`,
`*.constant.ts`, `*.schema.ts`, `*.locale.json`.

## 3. Código partilhado

- Do domínio: `src/modules/<Modulo>/shared/`.
- Transversal da app (inputs, loaders, modais base): `src/modules/shared/`.
- Toda lib externa ou integração técnica (cliente HTTP, analytics, cache) é encapsulada como
  Provider, separando contrato de inicialização do uso nas páginas.

## 4. UI versus lógica

- Toda manipulação de estado, submit de formulário, paginação e condicional complexa de tela
  vai para custom hook `*.hook.ts`. O componente só consome o que o hook expõe.
- `*.component.tsx` e `*.page.tsx` são declarativos: recebem props e renderizam. Sem cálculo,
  sem chamada direta de API, sem `useEffect` complexo.

## 5. Estado de servidor

- **TanStack Query é obrigatório.** Proibido `useEffect` + `useState` para carregar dado de API.
- Cada chamada HTTP encapsulada no seu `*.query.ts` / `*.mutation.ts`.
- Tipar estritamente pelo contrato do BFF. Como o BFF dita o formato da tela (Server-Driven UI),
  o front transmite e recebe os DTOs **sem mutar a estrutura localmente**.

## 6. Internacionalização

Proibido texto hardcoded em tag ou prop. Todo texto visível ao usuário vive em `*.locale.json`
por escopo, consumido via i18n com chave estruturada (`t('order.history.title')`).

## 7. Tabelas e listagens

Toda tela com dado tabular precisa de:

- Cabeçalho clicável alternando `asc` / `desc` / neutro, com indicador da direção ativa.
- Filtros com **seleção múltipla**, não valor único.
- Checkbox por linha + "selecionar todos" no cabeçalho, habilitando barra de ação em lote
  só quando há seleção.
- Botão "limpar filtros", visível apenas quando há filtro ou ordenação aplicado.
- Ordenação, filtros e paginação refletidos em **query params** da URL.
- `sortBy`, `sortDirection`, `filters[]` e paginação definidos no contrato do BFF (ver `bff.md`),
  nunca inferidos só no cliente quando a base for grande.
- **Zebra striping** via CSS Modules ou classe utilitária — nunca estilo inline.

## 8. Design tokens

**Proibido valor arbitrário hardcoded** — hexadecimal, pixel mágico, cor literal. Tudo vem de
`src/modules/shared/theme/`: `theme.constant.ts` (COLORS, TYPOGRAPHY, RADIUS, SHADOW),
`spacing.constant.ts` (SPACING, grade base 4px) e `scale.util.ts`.

`scale(factor)` (= `factor * 4`) e `scaleRem(factor)` são a **única via** para valor dinâmico.

| Situação | ❌ | ✅ |
|---|---|---|
| Cor | `bg-[#d9fdd3]` | `COLORS.primary[50]` |
| Espaçamento | `px-3 py-2.5` | `SPACING.scale(3)` |
| Fonte | `text-[14.5px]` | `TYPOGRAPHY.size.sm` |
| Borda | `rounded-xl` | `RADIUS.xl` |
| Sombra | `shadow-sm` | `SHADOW.sm` |
| Calculado | `Math.min(x, 120)` | `scale(30)` |

Valor hardcoded é **rejeitado em code review**.

## 9. Ícones em ações

Todo botão e item de menu deve ser **avaliado** para receber um ícone ao lado do rótulo. Ícone
acelera o reconhecimento (o olho acha "🗑 Excluir" antes de ler a palavra numa lista de seis
botões) e dá hierarquia visual sem depender só de cor ou peso de fonte.

**Avaliar não é obrigar.** O ícone entra quando comunica a ação de imediato; fica de fora quando
seria decorativo. Um ícone genérico ao lado de cada rótulo vira ruído e anula o ganho — se for
preciso pensar muito para escolher, a ação provavelmente não tem ícone óbvio, e texto sozinho é
melhor.

| Situação | Decisão |
|---|---|
| Ação com convenção estabelecida (salvar, excluir, editar, buscar, filtrar, adicionar, exportar) | ✅ ícone + rótulo |
| Ação destrutiva ou irreversível | ✅ ícone — reforça o peso antes do clique |
| Ação primária de um formulário ou modal | ✅ ícone, se houver um óbvio |
| Botão só de texto num par (`Cancelar` ao lado de `Salvar`) | ➖ ícone só no primário; o secundário fica limpo |
| Ação abstrata sem convenção ("Conciliar", "Apurar") | ❌ texto sozinho é mais claro que um ícone inventado |
| Grupo com muitos botões lado a lado | ✅ ícones — é onde o ganho de varredura é maior |

**Regras de execução:**

- **Biblioteca de ícones, não emoji, em produto.** Emoji renderiza diferente em cada
  sistema operacional, não herda `currentColor` e não escala com o token de tipografia. Use a
  biblioteca de ícones do projeto (`lucide-react` ou equivalente já adotado). Emoji é aceitável
  em protótipo, changelog, documentação e mensagem de terminal — não na UI entregue.
- **Ícone nunca substitui o rótulo** em ação de texto. Botão só-ícone (barra de ferramentas,
  fechar modal) exige `aria-label` descritivo.
- Tamanho e cor vêm dos tokens (§8) — nunca `width="18"` solto nem cor literal; o ícone herda
  `currentColor` para acompanhar estado (hover, disabled, variante destrutiva).
- Espaçamento entre ícone e rótulo pela escala (`SPACING.scale(2)`), não por margem mágica.
- O mesmo ícone significa a mesma ação em todo o produto. Dois ícones diferentes para "excluir"
  em telas diferentes é inconsistência, e é rejeitado em code review.
- Ícone é decorativo quando acompanha rótulo: `aria-hidden="true"`, para o leitor de tela não
  anunciar duas vezes.

## 10. Responsividade e PWA

Mobile-first, `min-width` para adicionar — nunca `max-` para remover.
Breakpoints: base 0px, `tablet:` 640px, `desktop:` 1024px, `wide:` 1280px.

- Área de toque mínima `scale(11)` (44px) em mobile.
- Nenhuma tela com scroll horizontal — tabela usa `overflow-x-auto` + `whitespace-nowrap`.
- Imagem com `max-w-full h-auto` ou `w-full object-cover`; nunca largura fixa em px.
- Corpo de texto em unidade relativa ou token; nunca px fixo.
- Layout quebra naturalmente (`flex-wrap`, `grid-cols-1 tablet:grid-cols-2 desktop:grid-cols-3`).
- Modal fullscreen em mobile; cantos arredondados e margem em desktop.
- Sidebar vira drawer/hamburger abaixo de `desktop:`.
- Verificar em 375px, 768px e 1280px+ antes do merge.

PWA obrigatório: `manifest.json` (name, short_name, ícones 192 e 512 PNG, start_url,
`display: standalone`, theme_color, background_color), service worker com cache-first para
asset estático e network-first para API (mínimo Stale-While-Revalidate), HTTPS em produção,
`offline.html` com identidade da marca, meta tags de theme-color e apple-touch-icon,
gerados via `vite-plugin-pwa`.

Tela quebrada em mobile/tablet ou app sem manifest e service worker é **rejeitada em code review**.

## 11. Formulários e campos de seleção

- **Select nativo do navegador é proibido em campo grande.** Toda lista longa (a partir de
  ~8 opções, ou qualquer lista que possa crescer) usa componente de combobox/select customizado
  com busca embutida — o `<select>` nativo do SO não aceita busca e quebra o visual entre
  navegadores. O componente segue os tokens (§8) e o mesmo design da página, nunca o estilo
  default do browser.
- Select nativo só é aceitável para lista curta e estática (até ~8 opções, ex: sim/não, unidade
  de medida).
- Todo formulário aplica **formatação e máscara de entrada** conforme o tipo do dado (CPF,
  telefone, CEP, moeda, data) durante a digitação, não só na validação do submit.
- Toda validação necessária (obrigatoriedade, formato, limites) vive em `*.schema.ts` (Zod)
  compartilhado entre o hook do formulário e o schema de request da API — nunca duplicada solta
  no componente.
- **Formulário rápido de preencher:** ao completar um campo (todos os caracteres esperados
  digitados — CPF completo, data completa, código de N dígitos), o foco avança automaticamente
  para o próximo campo, sem exigir Tab manual. O avanço automático não pula a validação do
  campo atual.
- **Campo único é checado no banco, sempre.** Todo campo com unicidade no banco (CPF, CNPJ, e-mail,
  placa, CNH, código) tem checagem contra o servidor — nunca só validação de formato no cliente.
  A checagem tem duas metades, e as duas são obrigatórias:
  1. **Antes do envio**, ao sair do campo (`blur`) e com o valor já completo: consulta ao endpoint
     que responde se o valor está em uso, com `AbortSignal` por digitação. O operador descobre a
     colisão no campo, não depois de preencher o formulário inteiro.
  2. **No envio**, o servidor responde **409 com código estável** por campo colidido
     (`*_TAX_ID_TAKEN`, `*_EMAIL_TAKEN`, …), e o cliente ancora a mensagem **no campo**, não só num
     aviso genérico no rodapé. A checagem prévia é conveniência; entre ela e o `INSERT` cabe outra
     escrita, e só a constraint do banco decide.
- Erro de campo é renderizado pelo próprio componente de campo (`aria-invalid` + `aria-describedby`
  apontando para a mensagem), nunca como texto solto ao lado. Editar o campo limpa o erro dele.

### A recusa do servidor nomeia o campo, e o nome é um atalho

**Aviso de falha que não diz qual campo é aviso que não ajuda.** O servidor valida na fronteira e
devolve `error.details[]` com `{field, message}` por regra violada (`apis.md` § Validação: *todos*
os erros de uma vez, não só o primeiro). O cliente que lê só `error.code` e ignora `details` joga
fora a informação **uma linha antes** de ela virar interface — e o operador fica com "não foi
possível salvar" numa ficha de quarenta campos.

Quatro exigências, todas bloqueantes em code review:

1. **O erro do transporte carrega os detalhes.** A classe de erro do cliente HTTP guarda
   `details: readonly {field, message}[]` ao lado do código. Se ela só tem `message`, os campos
   morrem no `throw`.
2. **Todos os campos recusados aparecem, não o primeiro.** A lista é deduplicada por campo (um
   campo que viola duas regras é um item, não dois) e sai por extenso: *"Confira: RNTRC, CPF,
   CEP."* Mostrar um por vez transforma a correção em tentativa e erro, com uma ida ao servidor
   por erro escondido.
3. **Cada nome é um atalho para o campo.** Clicar rola até ele e põe o foco nele. Dizer o nome
   põe a pessoa na direção certa; levá-la até lá é o que a poupa de varrer o formulário
   procurando o rótulo que acabou de ler. Em mobile o gesto é o mesmo: `scrollTo` da referência
   do campo + `focus()`.
4. **O rótulo impresso é o que aparece, nunca o caminho do corpo.** `address.postalCode` é o nome
   interno; "CEP" é o que a pessoa leu na tela. O mapa `caminho da API → chave de rótulo` mora num
   arquivo só, e **campo sem rótulo conhecido não some do aviso** — sai com o nome que a API usou.
   Esconder o desconhecido devolve exatamente o aviso genérico que esta regra conserta.

Casar o atalho pelo **rótulo** dentro do formulário é aceitável e costuma ser o certo: o rótulo já
é único ali, e obrigar cada campo a carregar o nome interno até a tela custa encanamento em dezenas
de lugares pelo mesmo resultado.

Isto **não substitui** o erro ancorado no campo (`aria-invalid`, borda) do item anterior — os dois
convivem. O aviso com atalho é a rede que pega o campo que não tem tratamento próprio, e é o único
caminho que escala para uma ficha longa sem plumbing campo a campo.

**Contrato de teste obrigatório:** a lista com dois ou mais campos, o silêncio quando a falha não
aponta campo algum, e o campo desconhecido chegando ao usuário com o nome cru.

## 12. Aviso de ambiente sem produção

Toda app web declara o ambiente em variável de build (`VITE_APP_ENV` ou equivalente) com três
valores — `local`, `staging`, `production` —, e **ausente ou desconhecido cai em `production`**:
variável esquecida no painel de hospedagem não pode fazer a instalação do cliente pedir desculpas.

Fora de produção, duas marcações e só duas:

- **O ícone da aba** troca por uma variante com 🚧. A marca continua **do tamanho normal**, no mesmo
  enquadramento do ícone de produção, e o 🚧 entra como **plaquinha sobreposta no canto inferior
  esquerdo**, à frente do desenho. Encolher a marca para abrir espaço ao aviso torna o ícone
  irreconhecível justamente onde ele é menor — e o ícone é o que se lê na aba antes do título.
- **Uma faixa de ambiente** no topo da tela.

O título da aba fica só com o nome do produto: com o ícone já avisando, um segundo aviso ao lado é
ruído. Emoji aqui é legítimo — é conteúdo do próprio desenho do ícone, não ícone de interface (§9).

Contrato obrigatório: o arquivo do ícone existe, o `<link rel="icon">` aponta para ele fora de
produção e para o normal em produção, e o build carrega a variável (o `ARG` do `Dockerfile` também
é do contrato — sem ele o valor não entra no bundle).

## 13. Auditoria final

- **Performance:** re-render isolado (digitar num input não redesenha a tela), callbacks
  memoizados quando passados a componente pesado, tree shaking ativo (sem importar lib inteira).
- **Segurança:** nada renderizado sem sanitização, `dangerouslySetInnerHTML` só com DOMPurify,
  nenhum token ou dado confidencial em `localStorage` ou estado global acessível pelo console.

## 14. Componentes de UI — shadcn é o padrão

**Todo componente de interface novo nasce do shadcn/ui**, não escrito à mão. Botão, modal, select,
dropdown, tabs, tooltip, toast, popover, comando: já existem ali, com acessibilidade de teclado e
leitor de tela vinda do Radix. Reimplementar é assinar embaixo de bugs de foco, `aria` e navegação
que já estão resolvidos — e são justamente os que não aparecem em teste manual de quem enxerga e usa
mouse.

O projeto declara `components.json` e os componentes são **copiados para dentro do repo**
(`src/components/ui/`), não instalados como dependência: eles são código do produto, se editam à
vontade e entram em code review como qualquer arquivo.

### O Tailwind continua embaixo, e isso não é escolha

shadcn **não substitui** o Tailwind: são componentes Radix estilizados com classes Tailwind. Sem
Tailwind configurado, nenhum deles renderiza. Não existe "trocar Tailwind por shadcn" — quem tenta
remover o Tailwind quebra o shadcn junto.

O que muda com esta regra é de onde vem o **componente**, não de onde vem o **estilo**: os tokens do
§8 continuam sendo a fonte da verdade, e o shadcn os respeita via `cssVariables: true`, mapeando as
variáveis CSS dele para a paleta do produto. Valor arbitrário hardcoded segue rejeitado, inclusive
dentro de componente copiado do shadcn.

### A tela existente manda sobre a preferência

**Componente novo segue o comportamento e a aparência das telas que já existem no produto.** Se a
listagem atual abre o detalhe em painel lateral, a próxima também abre — não em modal, porque o
shadcn tem um `Dialog` bonito. A regra existe para dar consistência, e adotá-la de um jeito que
produza duas linguagens visuais na mesma aplicação anula o motivo dela.

Disso decorre:

- **Não migrar tela que funciona** só para adotar shadcn. Migração é trabalho com risco e sem ganho
  visível ao usuário; ela se justifica quando a tela já vai ser mexida por outro motivo.
- **Divergência é o defeito**, não a implementação antiga. Dois modais com comportamentos diferentes
  é pior que dois modais igualmente artesanais.
- **Telas compartilhadas mandam mais ainda.** O que vem de `@adatechnology/conversations-ui` é o
  padrão dos três produtos: ali se consome a tela composta inteira e se customiza por `labels` e
  slots (ver a regra de pacotes), nunca remontando o grid com shadcn por cima.

### Quando não é shadcn

- **O que ele não cobre.** Canvas, editor de fluxo, gráfico, player — componente de domínio se
  escreve, seguindo os tokens do §8 e a regra de ícones do §9.
- **Web Component fora do React** (widget de chat, header institucional, §1): shadcn é React, não
  serve ali.
- **Campo de seleção com busca** (§11) pode sair do `Command`/`Combobox` do shadcn — é o caso comum,
  e evita o `<select>` nativo que aquela regra proíbe em lista longa.

Componente de interface novo escrito do zero, tendo equivalente no shadcn e sem justificativa acima,
é **rejeitado em code review**.
