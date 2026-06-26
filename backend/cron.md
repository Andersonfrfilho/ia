## 4. ⏰ Cron (Tarefas Agendadas)

O Cron gerencia execuções baseadas em tempo (batch processing, expiração de tokens, limpezas, cobranças mensais).

### 📐 Regras e Responsabilidades do Cron

- **Stateless e Lock de Execução:** É **obrigatório** o uso de mecanismos de Lock Distribuído (ex: Redlock no Redis) para garantir que apenas uma instância execute a rotina por ciclo em ambientes distribuídos (Docker/Kubernetes).
- **Processamento em Lote (Batches):** Nunca traga milhões de registros para a memória do Bun de uma vez. As consultas (`SELECT`) devem ser paginadas ou feitas por _cursors_ (ex: processar de 1000 em 1000).
- **Delegação via Mensageria:** Um Cron não deve processar uma cobrança complexa internamente. A melhor prática do mercado e da nossa arquitetura dita que o Cron deve apenas identificar os registros elegíveis e **publicar mensagens na Exchange do RabbitMQ**, permitindo que o ecossistema de Workers processe em massa e de forma paralelizada.
- **Observabilidade Crítica:** Geração estrita de logs no formato `[traceId][timestamp][appName]...` iniciando com um Trace único gerado para cada ciclo da rotina.
