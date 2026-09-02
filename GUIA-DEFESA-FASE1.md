# Guia de defesa — Fase 1 (Algoritmia e Programação)

Material de estudo do Fred e do Tarik. **Não faz parte da entrega** — é para
ler antes da apresentação.

As secções 1, 2, 5, 6, 7 e 8 são comuns aos dois. A **3 é a parte do Fred** e a
**4 é a parte do Tarik** — cada um estuda a sua, mas convém dar uma vista de
olhos na do outro: nas defesas as perguntas costumam saltar de um lado para o
outro.

---

## 1. A frase de abertura



> "É uma aplicação de consola para uma operadora de carregamento elétrico gerir
> a sua rede. Tem quatro entidades — postos, clientes, tarifários e
> carregamentos — com CRUD completo, integridade entre elas, um dashboard e
> dois relatórios. Está dividida em três camadas: os menus falam com o
> utilizador, os repositórios tratam dos dados, e os services fazem as contas."



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

## 3. Parte fred

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

## 4. Parte Tarik

### 4.1 Postos — `menuPostos.js` + `postoRepository.js`

**O que faz:** CRUD de postos. Cada um tem código, concelho, potência em kW,
tipo de conector e estado.

**Cinco coisas para defenderes:**

**a) O código é a chave, e é normalizado para maiúsculas na leitura.**

```js
lerTextoObrigatorio("...").trim().toUpperCase()
```

Quem escrever `p001` fica com `P001` gravado. Sem isto, havia dois postos
diferentes para o mesmo sítio e os relatórios agrupavam mal.

**b) O `"0"` está reservado para cancelar — e isso tem uma consequência.**

Repara no comentário que lá está:

> *"assim nunca chega a existir um posto com esse código, que depois seria
> impossível de gerir"*

É um bom argumento: se alguém conseguisse criar um posto com o código `0`,
nunca mais o conseguia selecionar em lado nenhum, porque escrever `0` cancela
sempre. **A reserva do código protege a aplicação de si própria.**

**c) Duas funções espelho, com condições opostas.**

```
lerCodigoNovoPosto()      repete enquanto o código JÁ existir
lercodigoPosto(acao)      repete enquanto o código NÃO existir
```

> "É a mesma pergunta feita ao contrário. Ao inserir, o que interessa é que
> ainda não exista. Ao atualizar ou remover, o que interessa é que exista."

E o `lerDadosPosto()` é partilhado pelas duas operações — no atualizar, a chave
já foi escolhida e não se volta a pedir.

**d) O `alterarPosto1` escreve campo a campo, de propósito.**

```js
postos[postoIndex].concelho = dadosNovos.concelho;
postos[postoIndex].potenciaKw = dadosNovos.potenciaKw;
postos[postoIndex].tipoConector = dadosNovos.tipoConector;
postos[postoIndex].estado = dadosNovos.estado;
```

> "Não se copia o objeto todo. Assim, mesmo que venham campos a mais, **o
> código nunca é alterado** — a chave está protegida pela própria estrutura da
> função, e não por confiança em quem a chama."

Bom ponto se te perguntarem porque não usaste o *spread* (`...`).

**e) Integridade referencial na remoção.**
O `excluirPosto1` percorre os carregamentos antes de apagar, e recusa se
encontrar algum. Repara na técnica: em vez de apagar da lista, **constrói uma
lista nova só com os que ficam**.

```js
if (restantes.length === postos.length) return false;   // não encontrou nenhum
```

> "Comparar os tamanhos no fim diz, de graça, se alguma coisa foi removida."

**Os valores permitidos vêm do `constantes.js`.** Concelho, tipo de conector e
estado são lidos com `lerOpcaoValida`, que só aceita valores da lista. Não há
como escrever "Bragga" ou um estado inventado.

---

### 4.2 Clientes — `menuClientes.js` + `clienteRepository.js`

Mesma estrutura dos postos, com uma decisão a mais que vale a pena saber
explicar.

**a) O NIF é a chave e é guardado como texto.**

> "Não se fazem contas com um NIF. Como texto, não se perdem eventuais zeros à
> esquerda."

**b) A melhor decisão desta parte: porque é que o `lerNifNovoCliente` não usa o
`lerNif`.**

Existe um `lerNif()` no `validacao.js` que exige 9 dígitos e repete até vir um
válido. Seria o óbvio a usar — mas não dá:

> "O `lerNif` nunca deixaria passar o `0` de cancelar, porque `0` não tem 9
> dígitos. Ele rejeitaria o cancelamento antes de nós o podermos sequer testar.
> Por isso lê-se como texto obrigatório e faz-se a validação **dentro** do
> ciclo, onde já dá para distinguir *'isto é um cancelamento'* de *'isto é um
> NIF mal escrito'* — e dar a mensagem certa a cada um."

E é por causa disto que o `soDigitos` está **exportado**: é a única função
auxiliar do `validacao.js` que sai para fora, precisamente para o menu poder
validar sem bloquear o `0`.

Se te pedirem "uma decisão de que te orgulhes", é esta. Mostra que percebeste
uma limitação de uma função tua e a contornaste sem a partir.

**c) As quatro validações de dados pessoais.**

| Campo | Regra |
|---|---|
| NIF | exatamente 9 dígitos |
| Telefone | exatamente 9 dígitos |
| Email | tem `@`, tem `.` depois do `@`, e não acaba em `.` |
| Matrícula | 8 caracteres, com `-` nas posições 3 e 6 (`XX-XX-XX`) |

A do email não usa expressões regulares de propósito — está feita com
`indexOf`, que é matéria das aulas e dá para explicar linha a linha.

**d) Integridade referencial.**
O `excluirCliente1` consulta os carregamentos antes de apagar. Um cliente com
histórico não sai.

> ⚠️ **Nota:** esta função tinha um erro — chamava `listarCarregamentos()` sem
> o ter importado, e rebentava sempre com `ReferenceError`. Está corrigido no
> commit `1e02d90`, com a linha de import que faltava. O `postoRepository` já
> a tinha; foi esquecida quando o código passou para os clientes.

---

### 4.3 Relatório 4.2 — clientes com carregamentos

`relatorioService.js` → `relatorioClientes()`

**A lógica: dois ciclos, um dentro do outro.**

```
para cada CLIENTE                    <- ciclo de fora
   para cada CARREGAMENTO            <- ciclo de dentro
      se for deste cliente, conta e soma a energia
   guarda a linha
```

> "É o cruzamento de duas entidades. O carregamento guarda o NIF, e é por ele
> que se ligam. Na Fase 2 isto passa a ser um `LEFT JOIN` com `GROUP BY`."

**O ponto que o enunciado exige e que é fácil falhar:**

> "Clientes **sem** carregamentos têm de aparecer, com zero. E aparecem — os
> contadores começam a `0` antes do ciclo de dentro, por isso um cliente sem
> nada dá `0 carregamentos | 0 kWh`, em vez de desaparecer da lista ou dar
> `NaN`."

Na demonstração, aponta para a **"Eva Semcarregamentos"**. Está nos dados
exatamente para provar isto.

**A idade — `calcularIdade()` no `validacao.js`.**

Não basta subtrair os anos:

```js
if (mesHoje < mesNasc || (mesHoje === mesNasc && diaHoje < diaNasc)) {
    idade = idade - 1;
}
```

> "Quem nasceu em dezembro e estamos em setembro ainda não fez anos este ano.
> A subtração de anos dá um a mais, e é preciso tirá-lo. A segunda parte da
> condição trata o caso de estarmos no próprio mês do aniversário."

Detalhe: `getMonth()` devolve 0 a 11, daí o `+1`. Se te perguntarem porquê, é
porque no objeto `Date` do JavaScript janeiro é o mês zero.

---

### 4.4 Diferenciador — análise de desvios e auditoria

`analiseService.js` — é a parte mais rica que tens, e dá para falar muito tempo.

**A pergunta que responde:** *"os carregamentos demoram o que era suposto?"*

```
previsto = energia registada (kWh) / potência do posto (kW)
real     = dataHoraFim - dataHoraInicio
desvio   = real - previsto            (positivo = demorou mais)
```

**a) Porque é que o desvio é quase sempre positivo — e porque isso não é um bug.**

> "A potência do posto é um **teto**, não uma garantia. O carro reduz o consumo
> à medida que a bateria enche, e pode ficar ligado depois de já estar cheio.
> Por isso o real demora sempre um pouco mais do que a conta prevê."

Isto chama-se *taper*, e saber o nome ajuda.

**b) A ideia central: um ciclo, duas saídas.**

Este é o argumento mais forte da tua parte:

> "Para calcular o desvio é preciso descartar os carregamentos que não servem.
> E essas verificações **são** a auditoria — muda só o que se faz quando
> falham. Os que passam entram na estatística; os que falham vão para uma lista
> de problemas, com o motivo. **O mesmo ciclo produz as duas saídas**, e é por
> isso que as opções 2 e 3 do menu chamam a mesma função."

É também a melhor prova da arquitetura em camadas: um service que não imprime
consegue alimentar dois ecrãs diferentes.

**c) A auditoria deteta cinco situações:**

```
1. aponta para um posto que não existe
2. está terminado mas sem data/hora de fim válida
3. a data de fim não é depois da de início
4. está terminado com 0 kWh registados
5. registou mais energia do que o posto conseguia entregar naquele tempo
```

E há um ponto de rigor a saber defender:

> "Um carregamento `em curso` ou `anulado` é simplesmente ignorado — não entra
> nas estatísticas nem na lista de problemas. **Não é um erro**: é que ainda
> não há nada para medir."

**d) A constante `TOLERANCIA`.**

```js
const TOLERANCIA = 1.0;   // 1.0 = sem tolerância; 1.1 = aceita 10% acima
```

> "Está isolada numa constante em vez de espalhada pelo código, porque é um
> parâmetro de negócio e não uma regra fixa. Um posto de 50 kW pode entregar um
> pouco acima disso em certas condições. Mudando um número, muda-se a política
> toda."

**e) A média e o desvio padrão — a matemática.**

Sabe explicar os dois em linguagem simples:

```
MÉDIA          onde está o centro
DESVIO PADRÃO  quão espalhados os valores estão à volta desse centro
```

O desvio padrão em 4 passos:

```
1. distância de cada valor à média
2. elevar cada distância ao quadrado
3. somar tudo e dividir pelo total        -> variância
4. tirar a raiz quadrada                  -> desvio padrão
```

As três perguntas prováveis, com resposta:

*"Porquê elevar ao quadrado?"*
> "Porque somar as distâncias com sinal dá **sempre zero**, para qualquer
> conjunto de números — é a própria definição de média: o que está acima
> cancela exatamente o que está abaixo. Ao quadrado, todas as distâncias
> contam."

*"Porquê a raiz no fim?"*
> "Porque o quadrado também elevou as unidades. A variância está em 'minutos ao
> quadrado', que não quer dizer nada. A raiz devolve minutos."

*"Porque são dois ciclos separados?"*
> "Porque o segundo precisa da média, e a média só existe depois de o primeiro
> ter percorrido tudo. A segunda passagem é obrigatória."

**f) A leitura do resultado — e é aqui que impressionas.**

Com os dados de exemplo, a média é enorme e o desvio padrão é ainda maior.
Isso não é um defeito do cálculo:

> "O desvio padrão ser **maior** do que a média é um sinal de alarme: quer
> dizer que os valores não estão agrupados à volta do centro. E não estão — há
> um registo, o #15, que ficou marcado com 252 dias de duração e sozinho
> distorce tudo. É precisamente esse contraste entre média e desvio padrão que
> sinaliza a existência de registos a corrigir. A estatística não está a
> falhar: está a fazer exatamente o seu trabalho, que é apontar o registo
> estragado."

**Utilidade para a operadora:** a média diz se a previsão dada ao cliente é
otimista; o desvio padrão diz se o erro é consistente ou errático.

---

## 5. A parte conjunta

### 5.1 Dashboard — `dashboardService.js`

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

### 5.2 `utils/validacao.js`

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

### 5.3 Notas técnicas transversais

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

## 6. Roteiro para a demonstração ao vivo

Uma ordem que mostra tudo em poucos minutos, sem improviso:

A coluna da direita diz quem fala em cada passo, para não se atropelarem.

```
                                                                    QUEM
1. npm start                                                        os dois
   -> o dashboard aparece sozinho. Aponta para os três
      indicadores e diz que cada um filtra um estado diferente.

2. Opção 5 -> 1   Relatório por posto                                Fred
   -> os grupos, os subtotais e o TOTAL no fim
      (o total é pedido no enunciado — aponta para ele)

3. Opção 5 -> 3   Clientes com carregamentos                        Tarik
   -> repara na "Eva Semcarregamentos": aparece com 0
      "clientes sem carregamentos não desaparecem da lista"

4. Opção 6 -> 1   Receita por concelho                               Fred
   -> as duas decisões: só faturados, e concelhos a zero aparecem

5. Opção 6 -> 2   Análise de desvios                                Tarik
   -> a média e o desvio padrão, e porque é que o segundo
      ser maior denuncia um registo estragado

6. Opção 6 -> 3   Auditoria                                         Tarik
   -> os 3 registos com problemas, postos nos dados de propósito
      "é o MESMO ciclo que produziu as estatísticas do passo 5"

7. Opção 4 -> 3   Atualizar o carregamento #10 -> "terminado"        Fred
   -> recusa com "o tarifário Fantasma já não existe"
      Um registo órfão tratado, em vez de a aplicação ir abaixo.

8. Opção 3 -> 4   Tentar remover o tarifário "Normal"                Fred
   -> recusa: "tem carregamentos associados"

9. Opção 2 -> 4   Tentar remover um cliente COM carregamentos       Tarik
   -> recusa pela mesma razão, noutra entidade
```

**Os passos 7, 8 e 9 são os mais fortes**: mostram regras a **impedir**
operações, o que é bastante mais convincente do que qualquer listagem. E o 8
com o 9 seguidos provam que a integridade não é um caso isolado — é uma regra
aplicada em toda a aplicação.

A ligação entre o passo 5 e o 6 é o melhor momento do Tarik: são duas opções de
menu diferentes alimentadas pela mesma função.

---

## 7. Os casos-limite que estão tratados

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

## 8. Se perguntarem o que farias diferente

É quase certo que a pergunta aparece. Ter a resposta pronta mostra maturidade e
evita a hesitação — e é melhor dizer vocês do que serem apanhados.

### A resposta comum, para fechar

Esta serve os dois, e é a mais forte. Guardem-na para o fim:

> "Nós **tratamos** as referências para registos que já não existem, mas tratar
> não é o mesmo que **impedir** — continua a ser possível os dados chegarem a
> esse estado. É exatamente isso que a Fase 2 resolve de raiz: com chaves
> estrangeiras, a base de dados não deixa sequer criar a referência."

Liga a Fase 1 à Fase 2 e mostra que perceberam **porque é que a base de dados
existe**.

### Fred

> "Duas coisas na minha parte. Os ciclos de procura não têm `break` — quando
> encontram o que procuram continuam até ao fim da lista; funciona, mas é
> trabalho a mais. E o cálculo do custo está no menu, quando devia estar num
> service: é uma regra de negócio, não apresentação."

### Tarik

> "Três coisas na minha parte. Os meus dois menus repetem-se por **recursão** —
> a função chama-se a si própria no fim — enquanto os outros quatro usam um
> ciclo `while`. Funciona, mas o `while` é mais simples e devia ter sido igual
> em todos. Depois, na atualização eu mostro 'atualizado com sucesso' sem
> verificar o que o repositório devolveu; hoje não mente porque a existência já
> foi garantida antes, mas está a confiar na ordem das chamadas em vez de
> verificar. E o `menuClientes` tem imports que não usa, copiados do
> `menuPostos`."

> **Porque é que vale a pena dizer isto:** nenhuma destas três coisas é um erro
> de funcionamento. São escolhas que se fariam melhor à segunda vez — e é
> exatamente isso que a pergunta quer ouvir.
