# 🗺️ Geração procedural de mapas — trilhas, água e terreno

Regras normativas para gerar rio, trilha, caverna, floresta e relevo. Bloqueantes
em code review.

Cada item veio de um defeito **medido** num mundo real deste ecossistema, não de
teoria. Onde há número, ele é o número que a medição deu.

---

## 1. A regra que ordena todas: MEDIR, não olhar

**Formar impressão olhando o desenho é o erro mais caro desta lista.** Um padrão
errado num gerador procedural é invisível na fórmula e visível só no resultado —
e ainda assim o olho aceita, porque tudo parece "meio orgânico".

Três medidas, todas de dez linhas, que devem existir antes de qualquer ajuste:

| o que | conta | o que denuncia |
|---|---|---|
| **Circularidade** | `(maior raio − menor raio) / comprimento do traço` | traço que é arco de círculo |
| **Sinuosidade** | `comprimento do traço / distância entre as pontas` | traço reto disfarçado |
| **Cobertura** | histograma de raio, ou de célula de grade | rede amontoada num anel |

Num caso real: eu tentei consertar "os rios parecem círculos" **três vezes**
olhando o mapa. A conta de circularidade levou dez segundos e apontou a causa de
primeira — 61 de 371 cursos quase não mudavam de raio.

---

## 2. NUNCA distribua pontos em coordenada polar

**Sortear ângulo e raio é o jeito natural de encher um anel, e é a origem do
padrão circular em qualquer coisa que cresça para esses pontos.**

A rede herda a fronteira dos pontos que a alimentam: os galhos param onde os
atratores acabam, e onde eles acabam é um círculo. O viés não aparece na
fórmula, só no desenho.

**Use grade sacudida:** uma casa de grade, um ponto no centro dela, mais um
empurrão sorteado de até meia casa. Uniforme por ÁREA, sem estrutura angular
nenhuma para a rede copiar.

- Sorteio puro faz **grumo**.
- Grade pura faz **fileira**.
- Grade sacudida não faz nem um nem outro.

Se a região for um anel, gere na grade e **descarte** o que cai fora — nunca
gere em polar e aceite.

---

## 3. NUNCA parametrize um traço pelo raio

`ponto = f(raio)` obriga todo traço a correr do centro para fora, e limita a
ramificação a *abrir em ângulo*. O desenho que sai é **espinha de peixe**, e
nenhuma quantidade de galhos conserta isso.

Guarde o traço como **polilinha** e parametrize por **progresso** (0 a 1) medido
em COMPRIMENTO andado, nunca em índice de ponto — os passos raramente têm todos
o mesmo tamanho.

E a pergunta que o resto do mundo realmente faz é **"qual ponto do traço está
mais perto daqui?"**, nunca "que ponto está no raio X". Exponha essa; ela
sobrevive a qualquer forma que o traço tome.

---

## 4. Ruído tem de ser COERENTE, e função da posição

Sorteio independente por passo dá **tremor**. Tremor não é curva.

O empurrão de cada passo vem de ruído amostrado na POSIÇÃO (Perlin, Simplex, ou
ruído de valor sobre grade com hash). Assim a mesma pedra dá sempre a mesma
curva — o que também é o que torna o mundo reproduzível.

---

## 5. Ligação explícita DESFAZ o gerador se for reta

Depois de gerar uma rede orgânica, é comum precisar costurar duas partes. **Uma
costura em linha reta recria exatamente o defeito que o gerador veio resolver**,
e ela chama atenção justamente por ser a única coisa reta na tela.

E a correção óbvia — **caminhada com mira** — NÃO CURVA. Cada passo mira o
destino, então a mira do passo seguinte DESFAZ o empurrão do anterior; os
desvios se cancelam e sobra exatamente a reta que a mira sempre apontou.
Medido: 25 emendas retas depois de "consertadas". Aumentar o número de passos
não muda nada, porque não é falta de passo — e eu tentei isso antes de medir.

**A curva é DESLOCAMENTO LATERAL, não caminhada.** Anda-se ao longo do eixo A→B
e sai-se DE LADO por ruído da posição, com a amplitude em meio seno: zero nas
duas pontas, cheia no meio. As pontas ficam presas sem precisar de mira nenhuma,
e a curva não pode se cancelar porque nada a recorrige.

    ponto = lerp(A, B, t) + perpendicular * ruído(ponto) * sin(t·π) * amplitude

Medido na troca: sinuosidade mediana 1,000 → 1,091.

### E reto é PARÂMETRO, não defeito

Uma rede em que NADA é reto lê tão fabricada quanto uma em que tudo é — fratura
de rocha às vezes é reta mesmo. O defeito nunca é a existência da reta, é a
PROPORÇÃO dela, e a proporção é do bioma: rocha fraturada abre passagem reta com
frequência, basalto quase nunca.

O sorteio de quem fica reto sai da **geometria das duas pontas**, nunca do índice
do laço: assim a mesma passagem é sempre a mesma se alguém reordenar o código.

E o teste cobra o **teto do parâmetro**, nunca zero. Cobrar zero congelaria uma
decisão de arte dentro de um teste, e a decisão é do bioma.

---

## 6. A grade tem de ser mais FINA que a menor coisa que ela precisa ver

Este defeito apareceu **quatro vezes** no mesmo mundo, sempre disfarçado de outra
coisa:

| o que parecia | o que era |
|---|---|
| "a trilha nunca cruza rio, não há pontes" | o rio era mais estreito que o passo do traçado |
| "a trilha sobe o barranco de frente" | a faixa do barranco tinha 1,5 casa de grade |
| "não existe corredeira nenhuma" | comparação com a escala errada |
| "a cachoeira não tem poço" | o relevo não tinha degrau na queda |

**Antes de culpar o custo, o peso ou a regra: confira a resolução.** Quem amostra
grosso não vê o que é fino, e o sintoma nunca aponta para a grade.

---

## 7. Valor fora de faixa como sinalizador VAZA

Usar "raio maior que o mundo" ou "índice negativo" para dizer *"este aqui não
tem"* só funciona enquanto ninguém lê o valor. Num caso real, três consumidores
leram: uma vila nasceu fora da ilha e trilhas miraram o mar aberto.

Exponha uma **função de pertinência** (`ChegaAoMar()`, `TemLago()`) e uma
**lista filtrada** (`PlanTrunks()`) em vez de esperar que todo consumidor lembre
de checar.

---

## 8. Cada árvore tem UM pai — redes não se fundem sozinhas

Em algoritmos de crescimento (colonização espacial, DLA, difusão), cada nó tem um
pai só. Duas redes crescendo uma para a outra **encostam no desenho e continuam
topologicamente separadas**.

Se o requisito é "dá para ir de A até B", ele é uma pergunta de **grafo conexo** e
tem de ser afirmado em teste. Olhar o mapa e achar que sim é o modo de falhar.

---

## 9. Que algoritmo para quê

| objetivo | algoritmo | por quê |
|---|---|---|
| Raiz, galho, bacia hidrográfica, nervura | **Colonização espacial** (Runions) | a ramificação é EMERGENTE: dois grupos de atratores puxando o mesmo nó para lados opostos partem o galho sem ninguém programar isso |
| Relevo, elevação, umidade | **Perlin / Simplex** | transição suave; separa terra, água e monte |
| Caverna, galeria, caminho torto | **Caminhada aleatória** com ruído coerente | cava em vez de riscar |
| Região, bioma, território | **Voronoi** | fronteira natural entre células |
| Desfragmentar mancha de floresta | **Autômato celular** | junta o que o sorteio deixou picado |
| Planta estilizada, ornamento | **L-System** | gramática, não simulação — bom para estilizado, ruim para raiz |
| Fractal puro (autossimilaridade exata) | ⚠️ evitar em mundo | repetição perfeita lê como artificial |

---

## 10. Mapa fixo se calcula UMA vez — e depois se assa

Se o mundo não depende de partida, de jogador nem de relógio, todo plano é
memoizável. Num caso real, o plano da região e o dos rios eram remontados **uma
vez por aresta** de um Dijkstra — milhões de montagens de mundo.

E a pergunta feita milhões de vezes ("este ponto está molhado?") vira **grade
rasterizada**: percorre-se a água uma vez carimbando as casas, em vez de
percorrer a água a cada pergunta.

**Cálculo único ainda não basta** quando "uma vez" leva minutos: aí o certo é
**assar** — calcular fora e embarcar o resultado.

---

## 11. Faixas de aceite, quando o alvo é imitar o real

| medida | referência | fonte |
|---|---|---|
| Onda de meandro | 10 a 14 larguras de calha | Leopold |
| Sinuosidade de rio meândrico | 1,5 a 2,0 (abaixo de 1,5 é reto) | Leopold |
| Raio de curva | 2 a 3 larguras | Leopold |
| Declive sustentável de trilha | ≤ 10% | construção de trilha |
| Regra da metade | trilha ≤ metade do declive da encosta | construção de trilha |
| Cabeceira de rio | reta; meandro nasce no curso baixo | geomorfologia |
| Poço de cachoeira | mais LARGO que fundo | ⚠️ ver abaixo |

⚠️ **Ler a fonte errado produz teste que nasce verde.** O "dez vezes" da
literatura de poço de queda é razão de VELOCIDADE de erosão (vertical sobre
lateral), não a forma do buraco. Escrevi um teste afirmando "mais fundo que
largo"; ele reprovou o código, e quem estava errado era o teste.

---

## 12. Teste que RECONSTRÓI a decisão mede o desempate

Um traçado procedural escolhe muita coisa por proximidade — o rio mais perto, a
vila mais perto. Quando duas candidatas empatam quase, o gerador elege uma e o
teste que refaz a conta elege a outra. **O teste reprova desenho certo, e a
mensagem não dá nenhuma pista de que o problema é o desempate.**

Aconteceu duas vezes seguidas na mesma regra ("o cemitério fica do lado seco da
vila"): a primeira versão refazia a escolha do rio, a segunda elegia a vila dona
pela proximidade — e o cemitério de um posto de fronteira cai mais perto da vila
vizinha, então todas as contas passaram a ser sobre a vila errada.

| forma | o que ela mede |
|---|---|
| "o rio mais perto é X, logo o rumo é Y" | ❌ o desempate |
| "está mais longe da água do que a vila está" | ⚠️ melhor, mas ainda elege a vila |
| "EXISTE vila para a qual isto vale" | ✅ a propriedade |

**Afirme a propriedade, na forma existencial.** Sem dono eleito não há desempate
para errar.

---

## 13. 🤖 Modelo recomendado

| etapa | modelo |
|---|---|
| Escolher o algoritmo e desenhar a topologia da rede | `opus` 🧠 |
| Implementar o gerador e as medições | `sonnet` |
| Ajustar constantes já medidas, renomear, extrair | `haiku` |

---

## 14. Planos que se consultam: o ciclo trava o PROCESSO

Um mundo procedural é feito de planos que se calculam uma vez e ficam
guardados: a região, a água, as trilhas, o uso do solo. Eles se consultam entre
si — e basta um consultar alguém que, mais abaixo, consulta ele de volta.

Em C++ isso reentra um inicializador estático, que é `abort()`. E o custo não é
o erro: é a **forma** dele. O processo morre depois de minutos escrevendo dump
de pilha, sem dizer nada útil, e a rodada inteira se perde.

**Três medidas, e a primeira é a que salva a rodada:**

1. **Guarda de reentrada em todo plano guardado.** Uma lista dos planos em
   construção; reentrou, `checkf` nomeando o CAMINHO do ciclo. "A água chamou a
   região, que chamou a água" é acionável; um rastro de pilha de dez minutos
   não é.
2. **Camadas declaradas, e a de baixo nunca pergunta à de cima.** Exemplo real:

       rocha  ->  água  ->  região  ->  relevo com lotes  ->  trilhas  ->  solo

3. **Uma altura por camada.** O leito do rio é anterior à vila, então ele
   pergunta à ROCHA — mar, ondulação e vulcão — nunca ao relevo acabado.

### O erro de diagnóstico que vem junto

Consertei um trecho do ciclo (o achatamento dos lotes) e **dei o problema por
resolvido**. O segundo trecho passava pela mesa da cidade, que também é definida
pela posição da cidade — e portanto não é terreno natural, é consequência de uma
escolha de povoamento.

**Ciclo tem mais de uma aresta.** Consertar uma e testar não basta: o rastro de
pilha mostra o caminho inteiro, e é ele que se lê.

### E `timeout` não existe no macOS

Usei `timeout` para limitar duas medições. Ele retorna **127, comando não
encontrado**, sem executar nada — e eu li o arquivo de despejo ANTIGO duas vezes
seguidas, concluindo em cima dele. Medição que não roda parece medição que deu
zero. `gtimeout` (coreutils) ou nada.
