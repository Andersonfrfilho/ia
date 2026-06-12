#### Estrutura correta de um prompt

## Instrução

- A tarefa especifica que você quer que o modelo execute. Seja direto e claro sobre o que espera

## Contexto

- Informações adicionais que ajudam a IA a entender melhor a situação e o propósito da tarefa

## Dados de Entrada

- O conteúdo especifico que precisa ser processado ou analisado pela a inteligência artificial

## Formato de Saída

- Como você quer que a resposta seja estruturada e apresentada. Defina o formato esperado

lembresse de que se alguém não conseguiria executar seu prompt ele esta ruim

exemplo:

```
# Intrução
Identifique se o texto esta escritp em portugues

# Input
Texto: I really enjoyed the movie

# Output Indicator
Idioma:
```

### Zero-shot prompting

É quando você pede para a I.A fazer algo sem dar nenhum exemplo antes. sem exemplos, apenas a instrução direta. O modelo responde com base no seu conhecimento pré-treinado

exemplo:

```
Você é um assistente que transforma descrições simpes em funções JavaScript.
Escreva uma função em Javascript que some dois números.
```

### One-shot Prompting

Você da um exemplo e pede outro parecido.

```
Você é um assistente que transforma descrições simples em funções Javascript.

Exemplo:
Entrada: "Uma função que multiplica dois números."
Saída:
function multiplica(a,b){
  return a+b
}

Agora é sua vez:

Entrada: "Uma função que conta quantas vogais existem em uma string"

Saida:
```

### Few-shot Prompting

**melhor resultado que o one-shot** prompting
Você da varios exemplos e pede outros parecidos:

```
Você é um assistente que converte descrições simples em funções javascript

Exemplos:

Entrada: "Uma função que soma dois números."
Saida:
function soma(a,b){
  return a+b
}

Entrada: "Uma função que verifica se um número é par."
Saida:
function ehPar(n){
  return n%2 === 0
}

Agora é sua vez:
Entrada: "Uma função que retorna o maior número de uma lista."
Saida:
```

## Dividir Tarefas Grandes

Quebre tarefas complexas em partes menores e mais especificas, Isso facilita o atendimento e melhora os resultados

## Teste Variações

Experimente diferentes formas de escrever a mesma instrução. Pequenas mudanças podem gerar grandes melhorias

## Instruções Claras

Use linguagem direta e precisa. Evite ambiguidade que podem confundir a inteligencia artificial

## Use comandos diretos

Escreva ordens claras no prompt: "Você deve", "Você precisa","faça", "não faça". Isso estabelece autoridade e clareza na instrução

## Adicione Consequências

Inclua consequências claras: "se você não fizer X, sua tarefa será rejeita", Isso reforça a importância de seguir as instruções.

exemplo:

```
se houver tipos como any sua tarefa sera rejeitada
```

## Seja Especifico

Inclua detalhes técnicos relevantes: ferramentas necessárias, estrutura de arquivos, padrões específicos que devem ser seguidos.

exemplo:

```
utilize axios, zod, nestjs...
```

## Use Markdown + XML

Estruture seus prompts com Markdown para formação e XML para seções especificas. Estudos da Antropic comprovam a eficácia

exemplo:

```
Markdown

# Task
# Instrução
# Requirements
# Context
# Output
```

```
XML
<Instruction>
<Requirements>
<Context>
<Output>
```

## Roles (cargos)

### System

Define o comportamento geral e as instruções de alto nivel do assistente.

exemplo:

```
role: "system"
content: "Você é um assistente de programação util"
```

### User

Representa a mensagem do usuario (pergunta ou instrução)

exemplo:

```
role: "user"
content: "Escreva uma função em javascript que inverta uma string"
```

### Assistant

Representa a resposta gerada pelo o modelo de IA

### Pense antes de responder

Instrua o modelo a pense bem antes de responder. Isso o incentiva a considerar diferentes perspectivas e a elaborar uma resposta mais completa e ponderada, em vez de uma reação imediata.

### Raciocine sobre Multiplas soluções

Peça ao modelo para "raciocinar sobre multiplas soluções antes de executar sua tarefa". Esta técnica promove a expliração de alternativas e a seleção da melhor opção, o que é especialmente útil para problemas complexos.
