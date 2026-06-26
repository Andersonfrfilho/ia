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

## 8. 🛡️ Segurança e Armazenamento (Auditoria Crítica)

- **Armazenamento de Dados Sensíveis:** O `AsyncStorage` escreve dados em texto plano (desprotegido). É **terminantemente proibido** salvar JWT Tokens, credenciais ou PII em `AsyncStorage`.
- **Keychain / Keystore:** Para qualquer dado sensível, o Provider de Storage local deve utilizar bibliotecas integradas com a segurança nativa do aparelho (ex: `react-native-keychain` ou `react-native-encrypted-storage`).
- **Logs e Depuração:** Garantir que o log de eventos e transições (formato de rastreio) não vaze informações pessoais em ambientes de release/produção.
