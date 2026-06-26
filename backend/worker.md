## 3. ⚙️ Worker (Processamento em Background / Mensageria)

O Worker é uma aplicação "headless" (sem interface ou portas HTTP expostas para clientes, exceto `/healthcheck`). Ele consome ativamente filas ou tópicos para desonerar a API principal.

### 📐 Escolha de Tecnologia: RabbitMQ (Preferencial)

- **Broker Padrão:** Adotamos o **RabbitMQ** como o broker de mensageria oficial e preferencial para o ecossistema de Workers. Toda a arquitetura de distribuição de mensagens e filas deve ser construída baseada nos conceitos nativos do RabbitMQ.
- **Arquitetura Amqp Avançada:** Utilize o modelo completo de **Exchanges** (Direct, Topic ou Fanout) para roteamento inteligente de mensagens em vez de publicar diretamente em filas isoladas. A API publica na Exchange, e esta direciona a mensagem para as filas vinculadas (_bindings_).

### 📐 Regras e Responsabilidades do Worker com RabbitMQ

- **Consumo e Idempotência:** Mensagens no RabbitMQ podem ser entregues mais de uma vez em cenários de instabilidade de rede ou re-queueing. Todo `*.use-case.ts` do Worker deve verificar se a tarefa já foi executada (ex: checando o status do pedido no banco de dados) antes de reprocessá-la.
- **Confirmações Manuais (Manual Acknowledgements):** Nunca utilize auto-ack. O Worker deve enviar o `ack` (confirmação de sucesso) ao RabbitMQ **apenas** após o Caso de Uso finalizar com sucesso e a transação de banco de dados ser commitada.
- **Tratamento de Erros, Retries e DLQ (Dead Letter Queue):** * Se o processamento falhar por uma falha temporária ou de infraestrutura, envie um `nack` com rejeição de volta à fila para tentativa de reprocessamento, preferencialmente configurando um mecanismo de *Retry com Backoff Exponencial\* (usando x-delayed-message ou filas de TTL).
  - Erros fatais ou repetidos estourando o limite de tentativas devem enviar a mensagem para uma **DLQ (Dead Letter Exchange/Queue)** dedicada para auditoria e alertas de observabilidade.
- **Controle de Fluxo (Prefetch Count):** Configure o `channel.prefetch(quantidade)` para limitar quantas mensagens não confirmadas o Worker pode puxar por vez do RabbitMQ. Isso impede que o processo do Bun consuma memória excessiva e trave o Event Loop.
- **Desligamento Gracioso (Graceful Shutdown):** Ao receber um sinal de kill (`SIGTERM`), o Worker deve imediatamente fechar os canais de consumo (`channel.close()`) para o RabbitMQ parar de enviar mensagens, finalizar o lote corrente em memória e fechar a conexão (`connection.close()`) antes de derrubar o container Docker.
