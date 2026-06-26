## 2. 🌐 API (Aplicações Principais)

A API é o coração do domínio. Ela guarda as regras de negócio puras, gerencia transações de banco de dados e expõe as funcionalidades principais para o BFF ou para integrações externas.

### 📐 Regras e Responsabilidades da API

- **Produtora de Mensagens:** A API atende as requisições síncronas rapidamente. Qualquer processamento pesado (envio de emails, geração de PDF, integrações em lote) **não deve bloquear o Event Loop**. A API deve salvar o estado inicial e **produzir uma mensagem** para o broker de mensageria para que um Worker finalize a tarefa.
- **Performance com Bun & uWebSockets:** Rotas estritamente tipadas, I/O assíncrono obrigatório. Nenhuma requisição deve durar mais que milissegundos sem ser delegada ao processamento em background.
- **Validação de Entrada (Zod/Tipagem):** Toda requisição recebida passa por uma blindagem de schema. Nenhum input não sanitizado toca no `*.use-case.ts`.
- **Idempotência em POST/PUT:** Rotas de criação e atualização devem ser desenhadas para suportar repetições de chamadas de rede seguras, validando UUIDs ou chaves únicas para não duplicar registros.
