# 🏗️ Diretrizes de Infraestrutura, Orquestração e Observabilidade (V1)

Este documento estabelece as regras estritas de infraestrutura como código (IaC), topologia de rede, segurança e observabilidade para o ecossistema de produção. Toda inteligência artificial (I.A.) ou engenheiro de DevOps atuando neste repositório deve respeitar rigorosamente estas diretrizes.

---

## 1. 🚦 Kong API Gateway (Porta de Entrada Única)

O **Kong** é o API Gateway oficial do ecossistema, atuando como o único ponto de entrada para o tráfego externo antes de alcançar a camada de BFFs (`apps/api-bff-...`).

### 📐 Regras de Configuração do Kong
* **Terminação TLS/SSL:** O Kong é responsável absoluto pela terminação de TLS. Nenhum BFF ou microsserviço interno gerencia certificados SSL diretamente.
* **Roteamento Inteligente (Declarativo):** As rotas devem ser configuradas via arquivos declarativos (`kong.yml` via decK) segregando por subdomínios ou caminhos (ex: `api.empresa.com/v1/orders` direciona para o BFF correspondente).
* **Plugins Obrigatórios na Borda:**
    * **Rate Limiting:** Aplicado globalmente por IP e por Token de Usuário para evitar ataques de negação de serviço (DoS) e abusos na API.
    * **CORS:** Gerenciado centralmente na borda pelo Kong, proibindo configurações permissivas nos BFFs em uWebSockets.js.
    * **Request Validator:** Utilizar o plugin do Kong para validar estruturas básicas de requisição antes mesmo de gastar poder computacional do cluster K8s.
* **Headers de Rastreabilidade:** O Kong deve interceptar ou gerar o `traceId` (caso não venha do cliente) e injetá-lo na requisição através do header `X-Trace-Id`, garantindo que a máscara de logs definida na regra 10 do `AI_CODING_RULES` funcione de ponta a ponta.

---

## 2. 🔐 Keycloak (Identity & Access Management - IAM)

O **Keycloak** é o servidor central de identidade, autenticação e autorização do ecossistema. 

### 📐 Integração e Segurança com Keycloak
* **Protocolo Padrão:** Uso estrito do **OpenID Connect (OIDC)** baseado em OAuth2.
* **Fluxos de Autenticação (Grant Types):**
    * **Web/Mobile:** Fluxo de *Authorization Code com PKCE* (Proof Key for Code Exchange). É terminantemente proibido o uso do fluxo implícito (Implicit Grant) ou Resource Owner Password Credentials.
    * **Comunicação M2M (Machine-to-Machine):** Fluxo de *Client Credentials* para microsserviços autenticarem entre si.
* **Validação de Tokens (Bearer Token):**
    * O BFF atua como um *Resource Server*. Ele valida a assinatura do JWT de forma assíncrona usando o endpoint de JWKS (`certs`) do Keycloak guardado em cache para não gerar gargalos de rede (I/O bloqueante no Bun).
* **Tratamento de Escopos e Roles:** As permissões de acesso a recursos (ex: `role:admin`, `scope:order:write`) devem ser injetadas nos *claims* do token JWT pelo Keycloak e validadas na camada de Guards/Middlewares da aplicação.

---

## 3. ☸️ Kubernetes (K8s) Cluster Architecture

Todo o ambiente produtivo e de homologação roda sobre **Kubernetes**, orquestrando os pacotes montados pelo Bun.

### 📐 Estruturação de Recursos no K8s
* **Namespaces Isolados:** Divisão rígida por ambientes (`prod`, `staging`, `dev`) e, se necessário, por contexto de negócio (ex: `core`, `payment`, `analytics`).
* **Mapeamento de Cargas de Trabalho (Workloads):**
    * **api e bff (`apps/api-...`):** Implantados como `Deployment`. Devem possuir réplicas escaláveis e expostos internamente via `Service` do tipo `ClusterIP` para o Kong mapear.
    * **worker (`apps/worker-...`):** Implantados como `Deployment` headless (sem Service associado), escalando horizontalmente de acordo com a demanda.
    * **cron (`apps/cron-...`):** **Proibido usar Deployments comuns.** Crons devem ser mapeados estritamente como objetos `CronJob` do Kubernetes, utilizando expressões cron nativas do K8s para disparar os pods temporizados.
* **Ciclo de Vida do Pod (Probes):** Todo Deployment deve conter definições explícitas de:
    * `livenessProbe`: Para o K8s saber se o processo do Bun travou e precisa de restart.
    * `readinessProbe`: Para garantir que o uWebSockets.js abriu a porta com sucesso antes do pod começar a receber tráfego.
* **Auto-Escalonamento (HPA):** Configurar o `HorizontalPodAutoscaler` para APIs baseado em consumo de CPU/Memória. Para os **Workers**, o HPA deve ser configurado para escalar com base em métricas customizadas vindas do **RabbitMQ** (comprimento da fila / mensagens pendentes).

---

## 4. 📊 Observabilidade: Prometheus, Grafana e Alertas

A saúde do sistema é guiada pelos 4 Sinais de Ouro (Latência, Tráfego, Erros e Saturação).

### 📐 Coleta de Métricas (Prometheus)
* **Endpoints `/metrics`:** Todas as APIs e Workers baseados em Bun devem expor um endpoint `/metrics` protegido (acessível apenas pelo cluster) utilizando bibliotecas compatíveis com o padrão Prometheus (OpenMetrics).
* **Métricas do RabbitMQ:** O Prometheus deve coletar continuamente o estado do broker do RabbitMQ (tamanho das filas, taxa de publicação, mensagens não confirmadas/unacked).

### 📐 Construção de Dashboards (Grafana)
Os painéis do Grafana devem ser organizados de forma unificada e limpa, divididos em três visões críticas:
1.  **Visão Executiva/Negócio:** Taxa de sucesso de compras (use cases de sucesso), faturamento minuto a minuto, novos usuários criados.
2.  **Visão de Aplicação:** Latência percentil (P95, P99) das rotas do `uWebSockets.js`, contagem de códigos HTTP (2xx, 4xx, 5xx), volumetria de mensagens na DLQ do RabbitMQ, e uso de memória/CPU por Pod Bun.
3.  **Visão de Infraestrutura:** Saúde dos nós do cluster Kubernetes, conexões simultâneas no Kong Gateway, e latência de resposta do Keycloak.

### 📐 Políticas de Alertas Estruturados (Alertmanager)
Os alertas devem ser disparados para canais integrados (ex: Slack, PagerDuty, Discord) divididos por severidade:

* **🚨 CRITICAL (Disparo Imediato / Acorda o Plantão):**
    * Erros HTTP 500 acima de 1% nas rotas nas últimas 2 janelas de minutos.
    * Mensagens acumulando na **DLQ** do RabbitMQ (falha fatal repetida em workers).
    * `livenessProbe` falhando consecutivamente em pods de produção (CrashLoopBackOff).
    * Consumo de memória RAM acima de 90% durando mais de 5 minutos em qualquer pod de banco de dados ou broker.
* **⚠️ WARNING (Aviso em Canais de Operação):**
    * Latência P95 das rotas excedendo 400ms.
    * Alerta de consumo de CPU acima de 80% disparando o teto do HPA.
    * Taxa de requisições rejeitadas por Rate Limiting no Kong acima do normal.

---

## 5. 🛡️ Segurança de Infraestrutura e Redes

* **Gerenciamento de Secrets:** **É expressamente proibido comitar arquivos `.env` ou chaves de produção.** Toda credencial, token do Keycloak e string de conexão com o banco de dados deve ser injetada de forma segura utilizando soluções de Secrets (ex: Vault, AWS Secrets Manager) acopladas nativamente como `v1/Secret` no Kubernetes através de External Secrets.
* **Network Policies (Políticas de Isolamento):** O cluster K8s deve blindar a rede de comunicação interna.
    * O banco de dados e o broker RabbitMQ só podem aceitar conexões vindas do namespace ou pods específicos das APIs e Workers.
    * Os BFFs e APIs não devem aceitar tráfego direto da internet pública, apenas requisições originadas estritamente dos IPs internos do **Kong API Gateway**.

---
**Nota para a I.A.:** Ao arquitetar scripts de Terraform, manifestos K8s, ou configurações do Kong, certifique-se de aplicar o isolamento de rede por NetworkPolicies, mapear Crons estritamente como `CronJob` e amarrar os alarmes do Alertmanager nos thresholds críticos definidos.
