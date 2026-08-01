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

## 9. Responsividade e PWA

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

## 10. Auditoria final

- **Performance:** re-render isolado (digitar num input não redesenha a tela), callbacks
  memoizados quando passados a componente pesado, tree shaking ativo (sem importar lib inteira).
- **Segurança:** nada renderizado sem sanitização, `dangerouslySetInnerHTML` só com DOMPurify,
  nenhum token ou dado confidencial em `localStorage` ou estado global acessível pelo console.
