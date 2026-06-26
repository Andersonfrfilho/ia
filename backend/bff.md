## 1. 🖥️ BFF (Backend For Frontend)

O BFF é a camada intermediária entre os clientes (Web/Mobile) e os microsserviços/APIs centrais. A sua principal responsabilidade é **formatar, agregar e ditar o contrato visual** para as interfaces.

### 📐 Regras e Responsabilidades do BFF

- **Contratos de Tela (Server-Driven UI / Screen DTOs):** O BFF **deve** montar e enviar os contratos de telas prontos. O Frontend atua apenas como um renderizador ("dumb client") que respeita fielmente as estruturas, listas e menus devolvidos pelo BFF.
- **Agregação de Dados:** Se uma tela precisa de dados de usuário, pedidos e notificações, o BFF deve fazer essas 3 chamadas internamente nas APIs e devolver um único payload consolidado ao Frontend, minimizando a latência na rede do cliente.
- **Proibição de Lógica de Negócio Profunda:** O BFF **não** deve calcular juros, não deve salvar dados complexos no banco de dados principal e não deve aplicar regras de negócio centrais. Ele apenas transforma dados.
- **Comunicação:** Construído obrigatoriamente sobre `uWebSockets.js` no Bun, priorizando latência ultrabaixa.
- **Tratamento de Sessão:** O BFF é responsável por gerenciar tokens (Refresh Tokens/Cookies) e traduzi-los de forma segura antes de encaminhar as requisições para a API.
