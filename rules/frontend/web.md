# 📐 Diretrizes de Arquitetura, Padrões de Código e Regras para I.A. (V8 - Frontend Web & Ecossistema)

Este documento estabelece as regras estritas de codificação, nomenclatura, arquitetura e qualidade para o desenvolvimento das aplicações **Frontend Web** dentro do Monorepo. Toda inteligência artificial (I.A.) ou desenvolvedor atuando nesta base de código deve respeitar rigorosamente estas diretrizes.

---

## 1. Stack Tecnológica e Decisão Arquitetural (Micro-Frontends vs Web Components)

O ecossistema Frontend deve ser planejado para alta performance, desacoplamento e prontidão para escalabilidade distribuída.

### ⚛️ Escolha de Framework e Runtimes

- **React:** Mantido como a biblioteca principal por padrão, aproveitando o ecossistema moderno do **Bun** (gerenciador de pacotes e build tooling) para máxima velocidade de compilação.
- **Preact:** **Não adotaremos Preact por padrão.** Embora o Preact seja mais leve, o React moderno resolveu grande parte dos problemas de tamanho e performance. Manter o React nativo garante 100% de compatibilidade com as bibliotecas mais modernas de mercado e ecossistemas de componentes sem a necessidade de aliases ou shims complexos que quebram o monorepo.

### 🧩 Estratégia de Micro-Frontends (MFE) e Web Components

- **Prontidão para Micro-Frontends (Module Federation):** O ecossistema deve estar estruturado de forma que, se houver necessidade de separar os projetos em Micro-Frontends, a transição seja puramente de configuração de infraestrutura (Build Tooling / Vite ou Rspack Module Federation). Para que isso seja possível, o acoplamento entre módulos deve ser **zero**.
- **Web Components (Encapsulamento Nativo):** Elementos visuais altamente transversais que precisam rodar em _qualquer_ lugar (ex: um widget de chat, uma barra de acessibilidade unificada ou um cabeçalho institucional usado tanto pelo time de React quanto por landing pages estáticas) devem ser construídos como **Web Components** nativos (usando Lit ou Vanilla TS). Eles devem morar em um pacote isolado dentro de `packages/`.

---

## 2. Convenção de Nomenclatura e Extensões de Arquivos

Para garantir consistência visual e facilidade de busca no projeto, todos os ficheiros criados no Frontend devem adotar os seus sufixos de papel/responsabilidade na extensão:

- **Componentes Visuais:** `*.component.tsx` (ex: `Button.component.tsx`)
- **Páginas / Telas Completas:** `*.page.tsx` (ex: `Dashboard.page.tsx`)
- **Lógica Isolada / Custom Hooks:** `*.hook.ts` (ex: `useAuth.hook.ts`)
- **Gerenciamento de Estado / Queries:** `*.query.ts` ou `*.mutation.ts` (ex: `useGetOrders.query.ts`)
- **Constantes Locais/Globais:** `*.constant.ts`
- **Esquemas de Validação (Formulários):** `*.schema.ts`
- **Dicionários de Tradução:** `*.locale.json`

---

## 3. Estrutura Modular e Localização do Código Partilhado (Shared)

A distribuição de arquivos segue uma hierarquia modular rígida baseada em domínios de negócio, exatamente como o Backend.

- **Shared de Módulo:** Códigos utilitários, tipos, hooks ou constantes que servem apenas ao contexto daquele domínio específico residem em `src/modules/<Modulo>/shared/`.
- **Shared Global do Projeto:** Elementos técnicos transversais pertencentes a uma aplicação específica (ex: componentes base como inputs, loaders, modais de estilo) ficam em `src/modules/shared/`.
- **Shared Providers Globais:** Toda biblioteca externa ou integração técnica (ex: cliente HTTP, analytics, rastreamento, cache) deve ser encapsulada como um Provider, separando o contrato de inicialização da sua utilização real nas páginas.

### 📂 Mapa de Pastas Padrão do Frontend Web

```text
meu-monorepo/
├── apps/
│   ├── frontend-cliente/                    <-- Prefixo "frontend-..."
│   │   └── src/
│   │       ├── modules/
│   │       │   ├── Order/
│   │       │   │   ├── components/
│   │       │   │   │   └── OrderList.component.tsx
│   │       │   │   ├── pages/
│   │       │   │   │   └── OrderHistory.page.tsx
│   │       │   │   ├── hooks/
│   │       │   │   │   └── useProcessOrder.hook.ts
│   │       │   │   └── shared/
│   │       │   │       ├── Order.constant.ts
│   │       │   │       └── Order.locale.json    <-- Internacionalização do módulo
│   │       │   │
│   │       │   └── shared/                     <-- Elementos reutilizáveis cross-módulos
│   │       │       ├── components/             <-- Design System Local (Button, Input)
│   │       │       ├── errors/
│   │       │       └── providers/
│   │       │           └── HttpClient/         <-- Encapsulamento do Axios/Fetch
│   │       │               ├── AxiosClient.ts
│   │       │               └── HttpClient.interface.ts
│   │       └── main.tsx
│   └── frontend-admin/
└── packages/
    └── web-components-core/                    <-- Elementos agnósticos nativos (Lit/TS)
        └── src/
            └── GlobalHeader.component.ts
```

---

## 4. Separação Absoluta de Responsabilidades: UI vs Lógica (Hooks)

Componentes visuais (`*.component.tsx` ou `*.page.tsx`) devem ser **declarativos e limpos**. É expressamente proibido poluir arquivos de marcação visual com funções de cálculo, chamadas diretas de API ou lógicas complexas de estado.

- **Lógica em Custom Hooks (`*.hook.ts`):** Toda manipulação de estado, submissão de formulários, paginação e regras condicionais complexas de tela **deve** ser extraída para um Hook customizado. O componente visual apenas consome as variáveis e funções expostas por esse Hook.
- **Componentes Burros (Dumb Components):** Devem apenas receber propriedades (`props`) e renderizar elementos visuais. Não gerenciam efeitos colaterais (`useEffect` complexos).

---

## 5. Gerenciamento de Estado de Dados com TanStack Query (React Query)

Para comunicação assíncrona, cache e sincronização de estado com o servidor (BFF/APIs), o uso do **TanStack Query (React Query)** é obrigatório.

- **Proibido useEffect para Fetch:** É terminantemente proibido utilizar `useEffect` casado com estados locais (`useState`) para carregar dados de APIs de forma manual.
- **Isolamento de Queries (`*.query.ts` / `*.mutation.ts`):** Cada chamada HTTP deve ser encapsulada em seu respectivo hook do React Query.
- **Respeito Absoluto aos Contratos do BFF:** As queries do React Query devem tipar estritamente o retorno esperado baseando-se no contrato ditado pelo **BFF**. Como o BFF dita o formato exato da tela (Server-Driven UI), as mutations e queries do frontend apenas transmitem e recebem esses DTOs sem mutar a estrutura localmente.

---

## 6. Internacionalização e Proteção contra Textos Soltos (Locales)

A aplicação deve nascer preparada para multi-idiomas. É **estritamente proibido** deixar textos ("hardcoded strings") jogados diretamente dentro de tags HTML ou propriedades no código.

- **Arquivos Locale (`*.locale.json`):** Todo texto interpretável pelo usuário (labels de botões, placeholders de inputs, mensagens de sucesso, títulos) deve residir em arquivos JSON de tradução organizados por escopo (local do módulo ou global do projeto).
- **Consumo via Abstração:** O mapeamento e exibição de textos no componente deve utilizar ferramentas tradicionais de i18n (ex: `react-i18next`) através de chaves estruturadas (ex: `t('order.history.title')`).

---

## 7. 📊 Padrão Obrigatório para Tabelas e Listagens (Data Tables)

Toda tela que renderize dados tabulares (listagens, grids administrativos, relatórios) deve seguir um padrão mínimo de usabilidade, independente do domínio de negócio.

- **Ordenação por Cabeçalho:** Todas as colunas ordenáveis devem expor um cabeçalho clicável, alternando entre `asc` / `desc` / estado neutro, com indicador visual da direção ativa.
- **Filtros com Seleção Múltipla:** Filtros de coluna ou de barra superior devem suportar seleção múltipla (multi-select) de valores, não apenas um valor único por vez.
- **Seleção e Ação em Massa:** A primeira coluna deve conter checkbox por linha e um checkbox "selecionar todos" no cabeçalho, habilitando uma barra de ações em lote (ex: editar, excluir, exportar) somente quando houver itens selecionados.
- **Botão "Limpar Filtros":** Deve existir um botão visível para resetar todos os filtros e ordenações ativas de uma vez, aparecendo apenas quando há algum filtro/ordenação aplicado.
- **Estado na URL:** Ordenação, filtros e paginação devem ser refletidos como query params, permitindo compartilhar/recarregar a URL sem perder o estado da listagem.
- **Contrato com o BFF:** Os parâmetros de ordenação (`sortBy`, `sortDirection`), filtros multi-valor (`filters[]`) e paginação devem ser definidos e documentados no contrato do BFF (ver `bff.md`), nunca inferidos ou tratados apenas no cliente quando a base de dados for grande.
- **Linhas Zebradas:** Todas as tabelas devem aplicar zebra striping (cores alternadas entre linhas pares e ímpares) para facilitar a leitura horizontal, via CSS Modules ou classes utilitárias — nunca com estilo inline.

---

## 8. 🛡️ Auditoria Final Frontend (Performance & Segurança)

Ao final de qualquer implementação ou refatoração no Frontend Web, a I.A. ou o desenvolvedor deve realizar uma auditoria rigorosa antes do commit.

### Auditoria de Performance Frontend

- **Renderizações Desnecessárias (Re-renders):** Validar se o isolamento de estados em hooks ou componentes menores impede que a digitação em um input mude a tela inteira.
- **Desperdício de Eventos:** Verificar se funções passadas para componentes pesados estão devidamente memoizadas (`useCallback` / `useMemo`) quando necessário.
- **Bundle Size:** Garantir que grandes bibliotecas externas de utilitários não estão sendo importadas por inteiro quando apenas uma função é utilizada (Tree Shaking ativo).

### Auditoria de Segurança Frontend

- **Prevenção de XSS:** Garantir que nenhuma string provinda do usuário ou do banco de dados seja renderizada sem sanitização ou injetada via propriedades perigosas como `dangerouslySetInnerHTML` sem um sanitizer robusto (ex: DOMPurify).
- **Vazamento de Informação Local:** Certificar-se de que dados confidenciais de negócio ou tokens não fiquem expostos de forma desprotegida no `localStorage` ou em estados globais acessíveis via console de desenvolvimento.

---

## 9. 🎨 Design System, Temas e Escalas (Design Tokens Obrigatórias)

Toda aplicação frontend deve obrigatoriamente consumir valores visuais de um sistema de **Design Tokens** centralizado. É **estritamente proibido** utilizar valores arbitrários (hardcoded) para cores, espaçamentos, tamanhos de fonte, bordas ou sombras diretamente em componentes ou estilos.

### 📐 Arquivo de Temas

Todo projeto frontend deve possuir constantes de tema em `src/shared/theme/` ou `src/modules/shared/theme/`:

```text
src/modules/shared/theme/
├── theme.constant.ts    ← Cores, tipografia, bordas, sombras
├── spacing.constant.ts  ← Escala de espaçamento (grid base 4px)
└── scale.util.ts        ← Função scale() para valores dinâmicos
```

### 🎯 Cores — Tokens Semânticos (NUNCA hardcode)

Nunca use valores hexadecimais (`#ff0000`), RGB ou nomes de cores CSS diretamente. Use tokens semânticos:

```ts
// theme.constant.ts
export const COLORS = {
  primary:   { 50: '#eff6ff', 500: '#3b82f6', 900: '#1e3a5f' },
  neutral:   { 0: '#ffffff', 100: '#f3f4f6', 900: '#111827' },
  semantic:  { success: '#16a34a', error: '#dc2626', warning: '#f59e0b' },
} as const
```

### 📏 Escala de Espaçamento — Grade Base 4px (`spacing.constant.ts`)

```ts
export const SPACING = {
  0:   0,
  1:   4,
  2:   8,
  3:   12,
  4:   16,
  5:   20,
  6:   24,
  8:   32,
  10:  40,
  12:  48,
  16:  64,
  scale: (factor: number) => factor * 4,
} as const
```

### 📐 Função `scale()`

A função `scale()` é a **única via permitida** para calcular valores dinâmicos:

```ts
// scale.util.ts
export function scale(factor: number): number {
  return factor * 4
}
export function scaleRem(factor: number): string {
  return `${(factor * 4) / 16}rem`
}
```

### 🔤 Escala Tipográfica

```ts
export const TYPOGRAPHY = {
  size: {
    xs:   12,
    sm:   14,
    base: 16,
    lg:   18,
    xl:   20,
    '2xl': 24,
    '3xl': 30,
  },
  weight: { normal: '400', medium: '500', semibold: '600', bold: '700' },
} as const
```

### 📐 Bordas e Sombras

```ts
export const RADIUS = {
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  full: 9999,
} as const

export const SHADOW = {
  sm: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
  md: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
  lg: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
} as const
```

### ✅ Regras de Uso (Inquebráveis)

| Situação | ❌ Proibido | ✅ Correto |
|----------|------------|-----------|
| Cor | `bg-[#d9fdd3]` | `style={{ backgroundColor: COLORS.primary[50] }}` |
| Padding | `px-3 py-2.5` | `style={{ padding: SPACING.scale(3) }}` |
| Fonte | `text-[14.5px]` | `style={{ fontSize: TYPOGRAPHY.size.sm }}` |
| Gap | `gap-1.5` | `style={{ gap: SPACING.scale(1.5) }}` |
| Borda | `rounded-xl` | `style={{ borderRadius: RADIUS.xl }}` |
| Calculado | `Math.min(x, 120)` | `scale(30)` — 120px |
| Dimensão | `w-9 h-9` | `style={{ width: scale(9), height: scale(9) }}` |
| Sombra | `shadow-sm` | `style={{ boxShadow: SHADOW.sm }}` |

### 🚨 Penalidade

Código que contenha **valores arbitrários hardcoded** (hexadecimais, pixels mágicos, cores literais) será **rejeitado em code review**. Toda constante visual deve ser referenciada dos arquivos de tema.

---

## 10. 📱 Responsividade Obrigatória (Mobile-First & Tablet) + PWA Ready

Toda aplicação frontend web deve ser **responsiva por padrão**, cobrindo obrigatoriamente 3 breakpoints: mobile, tablet e desktop. Além disso, deve estar preparada para funcionar como **PWA (Progressive Web App)**.

### 📐 Breakpoints Obrigatórios (Mobile-First)

O desenvolvimento deve seguir a abordagem **mobile-first**: estilos base são para mobile, e breakpoints de `min-width` adicionam complexidade para telas maiores.

| Breakpoint | Largura mínima | Dispositivo alvo |
|------------|---------------|------------------|
| Base (sem prefixo) | 0px | Mobile (smartphone) |
| `tablet:` | 640px | Tablet retrato / smartphone paisagem |
| `desktop:` | 1024px | Tablet paisagem / desktop pequeno |
| `wide:` | 1280px | Desktop padrão |

```ts
// tailwind.config.js — breakpoints obrigatórios
export default {
  theme: {
    screens: {
      tablet:  '640px',
      desktop: '1024px',
      wide:    '1280px',
    },
  },
}
```

### 📱 Regras de Responsividade (Inquebráveis)

| Regra | Descrição |
|-------|-----------|
| **Mobile-first sempre** | Classes sem prefixo = mobile. Use `tablet:` e `desktop:` para adicionar, nunca `max-` para remover. |
| **Touch-friendly** | Áreas de toque (botões, links, checkboxes) devem ter no mínimo `scale(11)` (44px) em mobile. |
| **Sem overflow horizontal** | Nenhuma tela pode ter scroll horizontal — use `overflow-x-auto` com `whitespace-nowrap` para tabelas. |
| **Imagens responsivas** | Use `max-w-full h-auto` ou `w-full object-cover`. Nunca largura fixa em `px`. |
| **Fontes escalam** | Use unidades relativas (`rem`, `%`) ou tokens da `TYPOGRAPHY`. Nunca `px` fixo para corpo de texto. |
| **Grid/Flex wrap** | Layouts devem quebrar naturalmente (`flex-wrap`, `grid-cols-1 tablet:grid-cols-2 desktop:grid-cols-3`). |
| **Modal/Diálogo fullscreen em mobile** | Modais devem ocupar 100% da tela em mobile e ter cantos arredondados + margem em desktop. |
| **Sidebar colapsável** | Sidebars de navegação devem virar drawer/hamburger menu abaixo de `desktop:`. |
| **Testar nos 3 breakpoints** | Toda tela deve ser visualmente verificada em 375px (iPhone SE), 768px (iPad) e 1280px+ antes do merge. |

### 📲 PWA — Requisitos Mínimos

Toda aplicação web deve estar **pronta para ser instalada como PWA** (ícone na home screen do dispositivo):

| Requisito | Descrição |
|-----------|-----------|
| **Manifest** | `manifest.json` na raiz pública com `name`, `short_name`, `icons` (192px + 512px PNG), `start_url`, `display: standalone`, `theme_color`, `background_color` |
| **Service Worker** | Registrar um service worker que implementa cache-first para assets estáticos (CSS, JS, fontes, imagens) e network-first para chamadas de API. Mínimo: estratégia `Stale-While-Revalidate`. |
| **HTTPS** | PWA exige HTTPS em produção (desenvolvimento local via `localhost` é exceção). |
| **Ícones** | Fornecer ícone 192x192 (home screen) e 512x512 (splash screen) em PNG com fundo sólido (sem transparência no corpo principal). |
| **Offline fallback** | Service worker deve servir uma página `offline.html` mínima quando não há rede, com identidade visual da marca e mensagem de "sem conexão". |
| **Meta tags** | `<meta name="theme-color">`, `<meta name="apple-mobile-web-app-capable">`, `<meta name="apple-mobile-web-app-status-bar-style">`, `<link rel="apple-touch-icon">`. |
| **Vite PWA plugin** | Usar `vite-plugin-pwa` para gerar o manifest e service worker automaticamente no build. |

```ts
// vite.config.ts — configuração mínima PWA
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    VitePWA({
      registerType: 'autoUpdate',
      manifest: {
        name: 'Nome do App',
        short_name: 'App',
        theme_color: '#ffffff',
        icons: [
          { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png' },
        ],
      },
      workbox: {
        runtimeCaching: [
          {
            urlPattern: /^https?:\/\/.*\/api\/.*/i,
            handler: 'NetworkFirst',
            options: { cacheName: 'api-cache', expiration: { maxEntries: 50, maxAgeSeconds: 300 } },
          },
        ],
      },
    }),
  ],
})
```

### 🚨 Penalidade

Telas que **não funcionarem** em mobile/tablet (layout quebrado, scroll horizontal, toques impossíveis) ou aplicações sem `manifest.json` e service worker serão **rejeitadas em code review**.
