# Guia de defesa — Fase 1 (Algoritmia e Programação)

Material de estudo do Fred. **Não faz parte da entrega** — é para ler antes da
apresentação.

---

## 1. A frase de abertura

Se te derem 30 segundos para dizer o que é o projeto:

> "É uma aplicação de consola para uma operadora de carregamento elétrico gerir
> a sua rede. Tem quatro entidades — postos, clientes, tarifários e
> carregamentos — com CRUD completo, integridade entre elas, um dashboard e
> dois relatórios. Está dividida em três camadas: os menus falam com o
> utilizador, os repositórios tratam dos dados, e os services fazem as contas."

Isso responde a metade das perguntas antes de serem feitas.

---

## 2. O mapa: as três camadas

Esta é **a** decisão de arquitetura do trabalho. Se souberes defender isto,
tens a nota da organização garantida.

```
   1-cli/            ->  fala com o utilizador
      |                  mostra opções, lê input, imprime resultados
      |                  NÃO faz contas, NÃO lê ficheiros
      v
   3-services/       ->  faz as contas
      |                  recebe dados, calcula, devolve um objeto
      |                  NÃO imprime, NÃO pergunta nada
      v
   2-repositories/   ->  trata dos dados
                         lê e grava os .json, valida, devolve valores
                         NÃO imprime, NÃO pergunta nada
```

**A regra de dependência:** as setas só apontam para baixo. Um menu pode chamar
um service e um repositório. Um service pode chamar um repositório. **Um
repositório nunca chama um menu.**

### Se perguntarem "porquê separar assim?"

Duas respostas concretas, e a segunda é a boa:

1. Cada pessoa mexe na sua pasta, o que evita conflitos no git.
2. **Um service que não imprime pode ser reutilizado.** E há prova disso no
   trabalho: o `analiseService.js` alimenta **duas** opções de menu diferentes
   (a análise de desvios e a auditoria) a partir do mesmo cálculo. Se ele
   fizesse `console.log`, isso era impossível.

### A convenção de retorno dos repositórios

Os quatro repositórios devolvem sempre a mesma coisa. Vale a pena saber de cor:

```
listar      ->  o array (vazio se não houver nada)
inserir     ->  o objeto inserido, ou null se foi recusado
atualizar   ->  o objeto atualizado, ou null se não existe
remover     ->  true se removeu, false se não
```

**A pergunta difícil:** *"porque é que devolve `null` em vez de dar erro ou
imprimir a mensagem?"*

> "Porque o repositório não sabe quem o está a chamar. Se ele imprimisse, ficava
> preso ao terminal. Devolvendo `null`, é o menu que decide a mensagem — e o
> mesmo repositório serviria uma interface gráfica ou uma API sem mudar uma
> linha."

---

## 3. A TUA parte

### 3.1 Tarifários — `menuTarifarios.js` + `tarifarioRepository.js`

**O que faz:** CRUD de tarifários. Cada um tem nome, preço por kWh e taxa de
ativação.

**Três coisas para defenderes:**

**a) O nome é a chave, e não se altera.**
No `atualizarTarifario(nome, dados)`, o nome entra como identificador e só os
outros campos mudam. Se o nome fosse alterável, os carregamentos que apontam
para "Normal" ficavam órfãos.

**b) A taxa de ativação usa `lerNumeroNaoNegativo`, não `lerNumeroPositivo`.**
Parece um detalhe, mas é uma decisão: **a taxa pode legitimamente ser 0**
(um tarifário sem taxa), enquanto o preço por kWh não pode. Duas funções
diferentes porque são duas regras diferentes.

**c) Integridade referencial na remoção.**
Um tarifário em uso não sai. E repara no que o menu faz antes de o remover:

```js
const existe = listarTarifarios().findIndex(...) !== -1;
```

> **Porquê essa verificação extra?** Porque o `removerTarifario` devolve `false`
> por **dois motivos diferentes** — "não existe" e "está em uso". Sem esta
> verificação, apagar um tarifário inexistente dava a mensagem errada: *"tem
> carregamentos associados"*. O menu pergunta primeiro para a mensagem não
> mentir.

Isto é um bom exemplo para dares se te pedirem "uma decisão de que te orgulhes".

---

### 3.2 Carregamentos — `menuCarregamentos.js` + `carregamentoRepository.js`

É a tabela central e a parte mais rica do trabalho. Quatro pontos:

**a) Integridade referencial "à entrada" (3 verificações).**
Ao inserir, o repositório confirma que o **posto** existe, que o **cliente**
existe e que o **tarifário** existe. E mais uma:

```js
if (postoEncontrado.estado !== 'ativo') return null;
```

> "Um posto em manutenção existe, mas não pode receber carregamentos novos. É
> uma regra de negócio, não de integridade — e por isso é verificada em separado."

**b) Normalização da chave ao gravar.**
Esta é subtil e vale ouro na defesa:

```js
posto: postoEncontrado.codigo,      // e não novoCarregamento.posto
tarifario: tarifarioEncontrado.nome,
```

> "Grava-se o código **como está no registo original**, não como o utilizador o
> escreveu. Se ele escrever `p001`, fica gravado `P001`. Sem isto, o dashboard
> agrupava `normal` e `Normal` como se fossem dois tarifários diferentes."

**c) O custo não é perguntado — é calculado.**
No menu, opção 3:

```js
custo = energiaKwh × tarifario.precoPorKwh + tarifario.taxaAtivacao
```

> "Perguntar o custo ao utilizador era abrir a porta a que ele não batesse
> certo com o tarifário. O custo é uma consequência da energia medida e do
> preço, não um dado de entrada."

**d) O teto físico de energia.** O melhor argumento que tens.

```js
energiaMaximaPossivel = potenciaPosto (kW) × duracaoEmHoras
if (dados.energiaKwh > energiaMaximaPossivel) return null;
```

> "Um posto de 22 kW não consegue entregar 45 kWh numa hora — é fisicamente
> impossível. Em vez de aceitar o número e corromper a faturação, o repositório
> recusa. A potência do posto é um **teto**, e o registo tem de o respeitar."

Se te perguntarem *"e se o posto já não existir?"*: nesse caso não há teto para
comparar e o valor passa. É uma escolha — não se recusa um registo por falta de
uma referência que já se perdeu.

---

### 3.3 Relatório 4.1 — carregamentos e custos

`relatorioService.js` → `relatorioCarregamentosPorPosto()` e
`relatorioCarregamentosPorCliente()`

**A lógica:** percorre os carregamentos, filtra `terminado` ou `faturado`,
agrupa num objeto onde **a chave é o código do posto** (ou o NIF do cliente), e
vai somando três coisas ao mesmo tempo: as linhas do grupo, o subtotal do grupo
e o total geral.

**Perguntas prováveis:**

*"Porque é que as duas funções são quase iguais?"*
> "São dois agrupamentos diferentes da mesma lista — só muda a chave. Podiam ser
> uma função com um parâmetro, mas assim cada uma diz no nome exatamente o que
> faz, e é mais fácil de ler."

*"Porque é que filtra `terminado` OU `faturado`?"*
> "Porque um carregamento `em curso` ainda não tem energia nem custo medidos, e
> um `anulado` não deve contar para lado nenhum."

*"Onde está o somatório final?"*
> É explicitamente pedido no enunciado. São o `totalEnergia` e o `totalCusto`,
> acumulados no mesmo ciclo. **Sabe apontar para eles.**

*"Porquê `toFixed(2)` na impressão?"*
> "Porque a soma de decimais em vírgula flutuante dá coisas como
> `141.60000000000002`. O `toFixed(2)` é só apresentação — o valor guardado
> continua completo."

---

### 3.4 Diferenciador — receita por concelho

`diferenciadorService.js` → `receitaPorConcelho()`

**A pergunta que responde:** *"em que concelhos é que o negócio rende mais?"*

**O ponto técnico — o lookup.** É o único sítio do projeto que cruza duas
entidades:

```
carregamento  --tem só o código do posto-->  posto  --tem o concelho-->  concelho
```

O carregamento guarda `"P001"`. O concelho está dentro do posto. Por isso há um
**ciclo dentro de um ciclo**: para cada carregamento faturado, percorre os
postos até encontrar o dele.

> "Na Fase 2 isto passa a ser um `JOIN` com `GROUP BY`. É exatamente o mesmo
> problema — só muda quem faz o trabalho."

**As duas decisões deliberadas** (e o professor vai gostar destas):

1. **Só os `faturado` contam.** Um `terminado` já foi consumido mas ainda não
   foi cobrado — não é receita.
2. **Todos os concelhos aparecem, mesmo a zero.** Um concelho a 0 EUR não é
   ruído: é precisamente a informação que interessa a quem decide onde investir.

**E o tratamento do órfão:**

```js
if (concelhoDoPosto === null) concelhoDoPosto = '(posto desconhecido)';
```

> "Se o posto já não existir, o carregamento não é deitado fora em silêncio.
> Aparece agrupado como `(posto desconhecido)`, para o problema ficar visível
> em vez de desaparecer da conta."

---

## 4. A parte conjunta

### 4.1 Dashboard — `dashboardService.js`

**O ponto todo está aqui:** os três indicadores filtram **estados diferentes**.

```
indicador 1  ->  conta em curso / terminados / faturados
indicador 2  ->  por posto,      SÓ os 'terminado'
indicador 3  ->  por tarifário,  SÓ os 'faturado'
```

> "O indicador 2 ignora os faturados e o 3 ignora os terminados. Ler mal isso é
> o erro mais fácil de cometer nesta parte."

**A guarda de divisão por zero:** antes de calcular a média, verifica-se se a
quantidade é maior que zero. Sem isso, `0/0` dá `NaN` — e `NaN` propaga-se por
tudo o resto sem dar erro.

### 4.2 `utils/validacao.js`

Há **dois tipos de função** neste ficheiro, e a diferença é a pergunta mais
provável sobre ele:

| Tipo | Exemplos | O que faz | De quem |
|---|---|---|---|
| `ler*` | `lerTextoObrigatorio`, `lerNumeroPositivo`, `lerDataHora` | pergunta e **repete** até vir valor válido | Tarik |
| sim/não | `campoObrigatorio`, `valorPositivo`, `dataHoraValida` | só responde `true`/`false` | **Fred** |

> "As `ler*` insistem com o utilizador — vivem nos menus. As de sim/não só
> respondem, e são usadas dentro dos repositórios, onde não há utilizador para
> perguntar. É a mesma separação das camadas, aplicada às validações."

Na prática, **ambos usam as funções do outro**: os menus do Fred leem input com
as funções do Tarik, e o `analiseService.js` do Tarik valida datas com a
`dataHoraValida` do Fred.

### 4.3 Notas técnicas transversais

**Porquê síncrono e não `async`/`await`?**
> "Numa aplicação de consola que espera pelo utilizador a cada passo, o
> síncrono mantém o fluxo do código igual ao fluxo da execução. Foi uma decisão
> tomada no início, não uma omissão."

**Porque é que o NIF é guardado como texto e não como número?**
> "Porque não se fazem contas com NIF, e como texto não se perdem eventuais
> zeros à esquerda."

**E se o ficheiro JSON não existir ou estiver vazio?**
> "Os quatro repositórios verificam com `existsSync` e testam se o conteúdo
> está vazio. Nos dois casos devolvem um array vazio em vez de rebentar."

---

## 5. Roteiro para a demonstração ao vivo

Uma ordem que mostra tudo em poucos minutos, sem improviso:

```
1. npm start
   -> o dashboard aparece sozinho. Aponta para os três indicadores
      e diz que cada um filtra um estado diferente.

2. Opção 5 -> 1     Relatório por posto
   -> mostra os grupos, os subtotais e o TOTAL no fim
      (o total é pedido no enunciado — aponta para ele)

3. Opção 5 -> 3     Clientes com carregamentos
   -> repara na "Eva Semcarregamentos": aparece com 0
      "clientes sem carregamentos não desaparecem da lista"

4. Opção 6 -> 1     Receita por concelho
   -> as duas decisões: só faturados, e concelhos a zero aparecem

5. Opção 6 -> 3     Auditoria
   -> os 3 registos com problemas, incluídos de propósito nos dados

6. Opção 4 -> 3     Atualizar o carregamento #10 -> "terminado"
   -> recusa com "o tarifário Fantasma deste carregamento já não existe"
      Um registo órfão tratado, em vez de a aplicação ir abaixo.

7. Opção 3 -> 4     Tentar remover o tarifário "Normal"
   -> recusa: "tem carregamentos associados"
      É a integridade referencial a funcionar à frente deles.
```

Os passos **6 e 7 são os mais fortes**: mostram regras a **impedir** operações,
o que é bastante mais convincente do que qualquer listagem.

---

## 6. Os casos-limite que estão tratados

Se te perguntarem *"e se os dados estiverem estragados?"*, tens três respostas
concretas — e são as três demonstráveis ao vivo.

### a) Carregamento cujo tarifário já não existe

O **#10** aponta para o tarifário `"Fantasma"`, que não existe (está nos dados
de propósito, para a auditoria o apanhar). Ao fechá-lo, o custo teria de sair
do preço desse tarifário — e não há preço nenhum.

O menu procura o tarifário **antes** de pedir a data e a energia, e se não o
encontrar dá a mensagem sem pedir mais nada:

```
Não foi possível fechar — o tarifário "Fantasma" deste carregamento já não existe.
```

> **A frase:** "Avisar cedo e com a causa certa. Não faz sentido o utilizador
> escrever três campos para depois descobrir que a operação nunca poderia ter
> resultado."

É o mesmo raciocínio do posto em manutenção, no mesmo menu.

### b) Cliente com carregamentos associados

O `excluirCliente1` consulta os carregamentos antes de apagar e recusa se
houver algum. É a mesma integridade referencial dos postos e dos tarifários —
a quarta entidade não é exceção.

### c) Desvios absurdos não estragam o ecrã

O carregamento **#15** ficou registado com 252 dias de duração. No gráfico da
opção 2 do menu 6, a barra é cortada aos 40 caracteres e marcada com `>`.

> **A frase:** "A barra é uma escala visual, não é o dado. O valor exato está
> na coluna do desvio, ao lado. Um registo estragado não pode tornar o
> relatório ilegível — é precisamente quando ele é mais preciso de ler."

---

## 7. Se perguntarem o que farias diferente

Tem uma resposta preparada — mostra maturidade e evita a hesitação:

> "Três coisas. Primeiro, os ciclos de procura não têm `break` — quando
> encontram o que procuram continuam até ao fim da lista. Funciona, mas é
> trabalho a mais. Segundo, o cálculo do custo está no menu e devia estar num
> service, porque é uma regra de negócio e não apresentação. E terceiro, nós
> **tratamos** as referências para registos que já não existem, mas tratar não
> é o mesmo que **impedir** — continua a ser possível os dados chegarem a esse
> estado. É exatamente isso que a Fase 2 resolve de raiz: com chaves
> estrangeiras, a base de dados não deixa sequer criar a referência."

A última parte é a melhor: liga a Fase 1 à Fase 2 e mostra que percebeste
**porque é que a base de dados existe**.
