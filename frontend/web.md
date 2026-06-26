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

## 7. 🛡️ Auditoria Final Frontend (Performance & Segurança)

Ao final de qualquer implementação ou refatoração no Frontend Web, a I.A. ou o desenvolvedor deve realizar uma auditoria rigorosa antes do commit.

### Auditoria de Performance Frontend

- **Renderizações Desnecessárias (Re-renders):** Validar se o isolamento de estados em hooks ou componentes menores impede que a digitação em um input mude a tela inteira.
- **Desperdício de Eventos:** Verificar se funções passadas para componentes pesados estão devidamente memoizadas (`useCallback` / `useMemo`) quando necessário.
- **Bundle Size:** Garantir que grandes bibliotecas externas de utilitários não estão sendo importadas por inteiro quando apenas uma função é utilizada (Tree Shaking ativo).

### Auditoria de Segurança Frontend

- **Prevenção de XSS:** Garantir que nenhuma string provinda do usuário ou do banco de dados seja renderizada sem sanitização ou injetada via propriedades perigosas como `dangerouslySetInnerHTML` sem um sanitizer robusto (ex: DOMPurify).
- **Vazamento de Informação Local:** Certificar-se de que dados confidenciais de negócio ou tokens não fiquem expostos de forma desprotegida no `localStorage` ou em estados globais acessíveis via console de desenvolvimento.
