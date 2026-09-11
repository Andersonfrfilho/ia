---
paths:
  - "**/apps/mobile-*/**"
  - "**/*.screen.tsx"
---

# 📱 Diretrizes de Arquitetura e Padrões para I.A. (Frontend Mobile)

Este documento estabelece as regras estritas de codificação, arquitetura, performance e qualidade para o desenvolvimento das aplicações **Mobile** dentro do Monorepo. Toda inteligência artificial (I.A.) ou desenvolvedor atuando nesta base de código deve respeitar rigorosamente estas diretrizes.

---

## 1. Stack Tecnológica e Decisão Arquitetural (React Native Bare)

O ecossistema Mobile deve ser desenhado para máxima performance e acesso irrestrito aos recursos nativos dos dispositivos (iOS e Android).

### ⚛️ React Native Bare Workflow (CLI)

- **Adoção Obrigatória do Bare Workflow:** É **estritamente exigido** o uso do React Native em sua abordagem _Bare_ (via React Native CLI). Não utilizaremos o workflow gerenciado do Expo (Expo Go) como padrão limitante.
- **Por que Bare Workflow?** O projeto exige acesso total às pastas `ios/` e `android/` para integrações profundas com módulos nativos (SDKs bancários, biometria avançada, bibliotecas de hardware, push notifications customizadas) sem as restrições ou overheads de um ambiente totalmente envelopado.
- **Engine JS:** O uso da engine **Hermes** é obrigatório para otimização de tempo de inicialização (TTI), redução do tamanho do bundle e menor consumo de memória no aparelho.

---

## 2. Convenção de Nomenclatura e Extensões de Arquivos

Para manter a consistência com o restante do Monorepo, adotamos sufixos semânticos. No mobile, substituímos "page" por "screen".

- **Telas / Rotas:** `*.screen.tsx` (ex: `Login.screen.tsx`)
- **Componentes Visuais:** `*.component.tsx` (ex: `Card.component.tsx`)
- **Lógica Isolada / Custom Hooks:** `*.hook.ts` (ex: `useCamera.hook.ts`)
- **Gerenciamento de Estado / Queries:** `*.query.ts` ou `*.mutation.ts`
- **Navegação (Routers):** `*.routes.tsx` ou `*.navigator.tsx`
- **Dicionários de Tradução:** `*.locale.json`

---

## 3. Estrutura Modular e Localização do Código (Shared)

A estrutura de diretórios é um reflexo exato da arquitetura Web e Backend, garantindo que qualquer desenvolvedor se localize instantaneamente.

- **Shared de Módulo:** Código isolado daquele domínio (ex: `src/modules/Checkout/shared/`).
- **Shared Global do Projeto:** Elementos reutilizáveis (UI Kits, botões, modais) ficam em `src/modules/shared/components/`.
- **Provedores de Infraestrutura:** Armazenamento local, clientes HTTP e serviços de Push Notification devem ser abstraídos como Providers em `src/modules/shared/providers/`.

### 📂 Mapa de Pastas Padrão Mobile

```text
meu-monorepo/
├── apps/
│   ├── mobile-app/                          <-- Prefixo "mobile-..."
│   │   ├── android/                         <-- Acesso nativo Bare
│   │   ├── ios/                             <-- Acesso nativo Bare
│   │   └── src/
│   │       ├── modules/
│   │       │   ├── Auth/
│   │       │   │   ├── screens/
│   │       │   │   │   └── Login.screen.tsx
│   │       │   │   ├── hooks/
│   │       │   │   │   └── useLogin.hook.ts
│   │       │   │   └── shared/
│   │       │   │       ├── Auth.locale.json
│   │       │   │       └── Auth.constant.ts
│   │       │   │
│   │       │   └── shared/
│   │       │       ├── components/
│   │       │       │   └── PrimaryButton.component.tsx
│   │       │       └── providers/
│   │       │           ├── StorageProvider/ <-- Encapsulamento
│   │       │           └── HttpClient/      <-- Cliente do BFF
│   │       └── App.tsx
└── packages/
    └── shared-types/                        <-- Contratos DTO compartilhados
```

---

## 4. UI e Lógica Desacopladas (A Regra dos Hooks)

Assim como na Web, as telas mobile (`*.screen.tsx`) sofrem com perda de performance se misturarem processamento pesado com renderização.

- **Lógica nos Hooks:** Toda regra de negócio (validação de formulário, ativação de câmera, requisições HTTP) deve residir em um `*.hook.ts`. A tela atua apenas como uma "casca" burra (Dumb Component).
- **Navegação:** A injeção das funções de navegação (`navigation.navigate`) deve ocorrer no Hook ou ser passada via prop. A tela em si não deve conter a lógica de decisão de _para onde_ ir.

---

## 5. Consumo de Dados (BFF e React Query)

- **Comunicação Direcionada:** O Mobile **nunca** acessa APIs de terceiros diretamente. Ele se comunica **exclusivamente com o BFF**, recebendo os contratos de Server-Driven UI (telas prontas).
- **TanStack Query Obrigatório:** O uso de `useEffect` para carregar dados via fetch/axios é banido. Use sempre `*.query.ts`. Isso resolve problemas complexos no mobile como _caching_ offline, _refetch_ ao focar a tela (`refetchOnWindowFocus`) e gerenciamento de estado de carregamento/erro de forma elegante.

---

## 6. Internacionalização e Textos (Locales)

- **Proibido Textos Hardcoded:** Todo aplicativo nasce preparado para múltiplos idiomas e culturas. Qualquer _string_ apresentada ao usuário deve estar no `*.locale.json`.
- Textos no código mobile geram refatorações custosas e exigem novos builds nas lojas. Centralizar textos permite atualizações dinâmicas via OTA (Over-The-Air) futuramente.

---

## 7. Performance Extrema Crítica (React Native)

No mobile, gargalos de performance causam travamentos na interface, queda de FPS e aquecimento do aparelho do usuário. O código deve ser obcecado por otimização.

- **Listas Otimizadas:** É proibido usar `ScrollView` ou `.map()` para renderizar listas dinâmicas. O uso de `FlatList` ou `FlashList` é estritamente obrigatório.
- **Componentes de Lista Otimizados:** Elementos renderizados em listas devem utilizar `React.memo` para evitar re-renderizações cíclicas sempre que um novo item for carregado.
- **Funções Anônimas na Renderização:** Evite ao máximo funções _inline_ diretamente nos atributos JSX (ex: `onPress={() => doSomething()}`). Isso recria a função a cada ciclo. Use `useCallback`.
- **Tráfego na Bridge:** Evite passar volumes absurdos de dados entre a thread de JavaScript e o ambiente Nativo. Transfira apenas o DTO formatado estritamente necessário.

---

## 8. 📊 Padrão Obrigatório para Listagens Tabulares (Data Tables Mobile)

Quando uma tela mobile precisar exibir dados em formato tabular/grid (ex: extratos, relatórios administrativos dentro do app), a `FlatList`/`FlashList` deve seguir o mesmo padrão mínimo de usabilidade definido para a Web (ver `web.md`, seção 7), adaptado às interações nativas:

- **Ordenação:** Cabeçalho fixo (sticky header) com toque para alternar `asc` / `desc` / neutro por coluna, com indicador visual da direção ativa.
- **Filtros com Seleção Múltipla:** Filtros exibidos em um bottom sheet ou modal dedicado, suportando seleção múltipla de valores por campo.
- **Seleção e Ação em Massa:** Modo de seleção ativado por long-press no item, com checkbox por linha, opção "selecionar todos" e barra de ações em lote fixada na parte inferior da tela.
- **Botão "Limpar Filtros":** Visível no cabeçalho do modal/bottom sheet de filtros, resetando todos os filtros e ordenações de uma vez, somente quando há algo aplicado.
- **Linhas Zebradas:** Itens da lista devem alternar cor de fundo par/ímpar via `getItemLayout`/estilo do item, nunca com estilo inline recalculado a cada render.
- **Contrato com o BFF:** Os mesmos parâmetros de ordenação, filtros multi-valor e paginação usados na Web (`sortBy`, `sortDirection`, `filters[]`) devem ser reaproveitados nas `*.query.ts` do mobile — nunca reinventados por plataforma.

---

## 9. 🛡️ Segurança e Armazenamento (Auditoria Crítica)

- **Armazenamento de Dados Sensíveis:** O `AsyncStorage` escreve dados em texto plano (desprotegido). É **terminantemente proibido** salvar JWT Tokens, credenciais ou PII em `AsyncStorage`.
- **Keychain / Keystore:** Para qualquer dado sensível, o Provider de Storage local deve utilizar bibliotecas integradas com a segurança nativa do aparelho (ex: `react-native-keychain` ou `react-native-encrypted-storage`).
- **Logs e Depuração:** Garantir que o log de eventos e transições (formato de rastreio) não vaze informações pessoais em ambientes de release/produção.

---

## 10. 🎨 Design System, Temas e Escalas (Design Tokens Obrigatórias)

Toda aplicação mobile deve obrigatoriamente consumir valores visuais de um sistema de **Design Tokens** centralizado. É **estritamente proibido** utilizar valores arbitrários (hardcoded) para cores, espaçamentos, tamanhos de fonte, bordas ou sombras diretamente em componentes ou estilos.

### 📐 Arquivo de Temas

```text
src/modules/shared/theme/
├── theme.constant.ts    ← Cores, tipografia, bordas, sombras
├── spacing.constant.ts  ← Escala de espaçamento (grid base 4px)
└── scale.util.ts        ← Função scale() para valores dinâmicos
```

### 🎯 Cores — Tokens Semânticos (NUNCA hardcode)

```ts
export const COLORS = {
  primary:   { 50: '#eff6ff', 500: '#3b82f6', 900: '#1e3a5f' },
  neutral:   { 0: '#ffffff', 100: '#f3f4f6', 900: '#111827' },
  semantic:  { success: '#16a34a', error: '#dc2626', warning: '#f59e0b' },
} as const
```

### 📏 Escala de Espaçamento — Grade Base 4px

```ts
export const SPACING = {
  0: 0, 1: 4, 2: 8, 3: 12, 4: 16, 5: 20, 6: 24, 8: 32, 10: 40, 12: 48, 16: 64,
  scale: (factor: number) => factor * 4,
} as const
```

### 📐 Função `scale()`

```ts
export function scale(factor: number): number { return factor * 4 }
export function scaleRem(factor: number): string { return `${(factor * 4) / 16}rem` }
```

### 🔤 Escala Tipográfica

```ts
export const TYPOGRAPHY = {
  size: { xs: 12, sm: 14, base: 16, lg: 18, xl: 20, '2xl': 24, '3xl': 30 },
  weight: { normal: '400', medium: '500', semibold: '600', bold: '700' },
} as const
```

### 📐 Bordas e Sombras

```ts
export const RADIUS = { sm: 4, md: 8, lg: 12, xl: 16, full: 9999 } as const
export const SHADOW = {
  sm: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
  md: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
  lg: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
} as const
```

### ✅ Regras de Uso (Inquebráveis)

| Situação | ❌ Proibido | ✅ Correto |
|----------|------------|-----------|
| Cor | `color: '#d9fdd3'` | `color: COLORS.primary[50]` |
| Padding | `padding: 12` | `padding: SPACING.scale(3)` |
| Fonte | `fontSize: 14.5` | `fontSize: TYPOGRAPHY.size.sm` |
| Margem | `margin: 6` | `margin: SPACING.scale(1.5)` |
| Borda | `borderRadius: 16` | `borderRadius: RADIUS.xl` |
| Calculado | `minHeight: 120` | `scale(30)` |
| Sombra | `elevation: 4` | `boxShadow: SHADOW.md` |
| Gap | `gap: 1.5` | `gap: SPACING.scale(1.5)` |

### 🚨 Penalidade

Código que contenha **valores arbitrários hardcoded** será **rejeitado em code review**. Toda constante visual deve vir dos arquivos de tema.

## 11. Ícones em ações

Vale a mesma regra da web (`web.md` §9): **todo botão e item de menu é avaliado para receber um
ícone** ao lado do rótulo — ícone entra quando comunica a ação de imediato, fica de fora quando
seria decorativo. A tabela de decisão (ação com convenção → sim; ação abstrata sem convenção →
texto sozinho) é a mesma, e não se repete aqui.

Três diferenças que só existem no mobile:

- **Biblioteca nativa, nunca emoji em `<Text>` como ícone.** Emoji no Android e no iOS são
  desenhos diferentes, não herdam `color` do estilo e desalinham na linha de base. Use a
  biblioteca de ícones vetoriais do projeto (`@expo/vector-icons`, `react-native-vector-icons`
  ou equivalente já adotado).
- **Área de toque de 44px vale para o botão inteiro** (§ Responsividade da web e alvo mínimo
  desta doc) — não para o ícone. Ícone de 20px dentro de um alvo de 44px, com `hitSlop` quando
  o layout apertar.
- Tamanho e cor vêm dos tokens (§10) — `size={SPACING.scale(5)}` e `color={COLORS...}`, nunca
  `size={20}` solto.

Botão só-ícone precisa de `accessibilityLabel`; ícone que acompanha rótulo é decorativo e leva
`accessibilityElementsHidden` (iOS) / `importantForAccessibility="no"` (Android), para o leitor
de tela não anunciar a ação duas vezes.

## 12. Formulários — a recusa aponta o campo

Vale integralmente a regra da web (`web.md` §11, *"A recusa do servidor nomeia o campo, e o nome é
um atalho"*): o erro do cliente HTTP carrega `details[]`, **todos** os campos recusados são
listados de uma vez, cada um vira atalho para o campo, e o que aparece é o rótulo impresso, não o
caminho do corpo. A tabela de exigências não se repete aqui.

Três diferenças que só existem no mobile:

- **O atalho é `scrollTo` + `focus()`, não `scrollIntoView`.** Guarde a `ref` do input por campo
  e role o `ScrollView`/`KeyboardAwareScrollView` até `measureLayout`. Focar sem rolar deixa o
  cursor num campo fora da tela, e o teclado sobe escondendo o que se ia corrigir.
- **O teclado é parte do problema.** Depois de rolar, o campo tem de ficar acima do teclado —
  role com folga (`SPACING.scale(4)` além do topo do campo), não para a borda exata.
- **A lista de campos é `Text` com `onPress` por item**, com área de toque de 44px como qualquer
  outra ação (§11), e `accessibilityRole="button"` em cada nome. Um bloco de texto único com os
  nomes dentro não é tocável e vira o mesmo aviso morto que a regra proíbe.

A validação local continua acontecendo antes do envio; esta regra é sobre o que fazer quando o
servidor recusa mesmo assim — e ele recusa, porque só o banco decide colisão e só ele conhece a
constraint.
