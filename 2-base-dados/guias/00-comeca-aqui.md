# Começa aqui — o trabalho todo, do zero

> Este guia não assume que sabes nada. Lê-o antes de todos os outros.
> No fim, vais perceber o diagrama e saber para que serve cada uma das 17 tabelas.

---

# Parte 1 — O que estamos a construir

A VoltGo é uma rede de **postos de carregamento de carros elétricos**.

Na **Fase 1**, fizeste uma aplicação de consola em JavaScript que guardava tudo em ficheiros `.json`.

Na **Fase 2**, a mesma informação passa a viver numa **base de dados**.

### Porque é que isso é diferente

Um ficheiro JSON é uma folha de papel. Escreves lá o que quiseres, e ninguém verifica nada.

Uma base de dados é uma folha de papel **com um fiscal ao lado**. Podes dizer-lhe coisas como:

> "Nunca aceites um carregamento sem cliente."
> "Nunca aceites dois clientes com o mesmo NIF."
> "Nunca aceites um pagamento de zero euros."

E ela **recusa** o que violar essas regras. Mesmo que o programa esteja com um erro.

> **A ideia central de toda a cadeira:** a base de dados não é um sítio onde se guardam dados. É um sítio onde se guardam dados **e as regras que os protegem**.

---

# Parte 2 — Porque é que são 17 tabelas e não uma só

Esta é a pergunta mais natural do mundo, e a resposta explica quase tudo o resto.

Imagina que guardavas tudo numa tabela só:

```
CARREGAMENTOS
| cliente | telefone   | posto       | concelho | energia | preco_kwh |
|---------|------------|-------------|----------|---------|-----------|
| Joao    | 912345678  | Braga Centro| Braga    | 20 kWh  | 0,28      |
| Joao    | 912345678  | Braga Centro| Braga    | 15 kWh  | 0,28      |
| Joao    | 912345678  | Barcelos    | Barcelos | 30 kWh  | 0,28      |
```

Parece que funciona. Mas tem três problemas graves.

### Problema 1 — o João mudou de telefone

Tens de o corrigir em **três linhas**. Se te esqueceres de uma, a base de dados fica a dizer duas coisas diferentes sobre a mesma pessoa.

Chama-se **anomalia de atualização**.

### Problema 2 — abriu um posto novo em Fafe, ainda sem carregamentos

Onde é que o metes? Não há linha nenhuma para ele. O posto **só pode existir se alguém carregar lá** — o que é absurdo.

Chama-se **anomalia de inserção**.

### Problema 3 — apagaste o último carregamento do Barcelos

Perdeste o carregamento **e** perdeste o posto **e** perdeste o concelho, todos de uma vez. Não havia mais nenhum sítio onde eles estivessem escritos.

Chama-se **anomalia de eliminação**.

### A solução

Separar as coisas que são **entidades diferentes no mundo real** em tabelas diferentes, e ligá-las.

```
CLIENTE                    POSTO                    CARREGAMENTO
| id | nome | telefone |   | id | nome    |         | id | cliente | posto | energia |
| 1  | Joao | 912...   |   | 1  | Braga.. |         | 1  |    1    |   1   | 20 kWh  |
                           | 2  | Barcelos|         | 2  |    1    |   1   | 15 kWh  |
                           | 3  | Fafe    |         | 3  |    1    |   2   | 30 kWh  |
```

Agora:
- o telefone do João está **num sítio só** → muda-se uma vez
- o posto de Fafe **existe sem carregamentos** → é uma linha própria
- apagar um carregamento **não apaga mais nada**

Isto chama-se **normalização**. É por isto que são 17 tabelas.

---

# Parte 3 — Como as tabelas se ligam

Aquele número `1` na coluna `cliente` do carregamento tem um nome: **chave estrangeira** (FK).

É uma seta. Diz: *"o cliente deste carregamento é o cliente número 1"*.

E a base de dados **verifica**. Se tentares gravar um carregamento do cliente 99 e o cliente 99 não existir, ela recusa.

### As três siglas que vais ver em todo o lado

| Sigla | Nome | O que significa |
|---|---|---|
| **PK** | chave primária | o número que identifica esta linha. Único, nunca se repete. |
| **FK** | chave estrangeira | aponta para a PK de outra tabela. É a seta. |
| **AK** | chave alternativa | não é a PK, mas também não pode repetir. Ex.: o NIF. |

### O pé de galinha

No diagrama, as ligações têm este aspeto:

```
CLIENTE  |———————<  CARREGAMENTO
```

O lado com **três riscos** (o "pé de galinha") é o lado do **muitos**.

Lê-se: *um cliente tem muitos carregamentos*.

> **A regra que te vai poupar tempo:**
> O pé de galinha fica **sempre** do lado onde está a FK.
> A FK fica sempre do lado do **muitos**.
>
> Um carregamento tem **um** cliente → a FK está no carregamento → o pé de galinha está no carregamento.

---

# Parte 4 — O modelo, contado como uma história

Vou seguir um carregamento do princípio ao fim. Cada tabela aparece quando faz falta.

### 1. O João quer carregar o carro

O João é um **cliente**.

```
CLIENTE   nome, NIF, telefone, email, tipo (particular ou empresarial)
```

Há dois tipos: **particulares** (pessoas) e **empresariais** (empresas com frota).
Uma empresa não tem data de nascimento — e a base de dados até **proíbe** que tenha.

### 2. O João tem um carro

```
VEICULO   matricula, marca, modelo   ->  pertence a um CLIENTE
```

Um cliente pode ter vários veículos. Uma empresa de frota pode ter 20.

### 3. Vai a um posto

```
POSTO     codigo (P001), nome, potencia em kW, data de instalacao
CONCELHO  nome
```

Cada posto fica num **concelho**. Porquê uma tabela só para isso? Pelo problema 1 lá atrás: se "Braga" estivesse escrito em 13 postos e alguém escrevesse "Bragga" num deles, passava a haver dois concelhos.

### 4. O posto tem tomadas

Aqui há uma subtileza importante.

Um posto tem **vários tipos de tomada**. E o mesmo tipo de tomada existe em **vários postos**.

```
POSTO 1  tem tomada Type 2 e tomada CCS
POSTO 2  tem tomada Type 2
POSTO 3  tem tomada CCS e tomada CHAdeMO
```

Isto chama-se **muitos-para-muitos**, e não se consegue representar com uma seta só. Resolve-se sempre com uma tabela no meio:

```
TIPOCONECTOR  >———  POSTOCONECTOR  ———<  POSTO
```

Cada linha da `PostoConector` é **uma tomada concreta**: "a tomada CCS do posto 3".

> Guarda esta ideia. É a que mais aparece em exames: **muitos-para-muitos resolve-se sempre com uma tabela de ligação.**

### 5. Talvez tenha reservado antes

```
RESERVA   cliente, posto, hora de inicio, hora de fim, estado
```

Uma reserva ocupa um **posto** durante uma janela de tempo.

### 6. Liga o carro — nasce o carregamento

Esta é a tabela central de todo o sistema.

```
CARREGAMENTO
   em que TOMADA foi          (e é pela tomada que se sabe o posto)
   quem CONDUZIU
   que VEICULO
   que TARIFARIO
   de que RESERVA veio        (pode não ter vindo de nenhuma)
   em que FATURA entrou       (vazio ate ser faturado)
   hora de inicio, hora de fim, energia, custo, estado
```

Repara numa coisa: o carregamento aponta para a **tomada**, não para o posto.

Porquê? Porque a tomada **já sabe** a que posto pertence. Guardar os dois seria repetir informação — e voltávamos ao problema 1. Foi uma das alterações que a professora pediu.

Para chegares ao posto, fazes o caminho:

```
Carregamento  ->  PostoConector  ->  Posto  ->  Concelho
```

### 7. O preço vem do tarifário

```
TARIFARIO        nome, se ainda se vende, preco atual, taxa atual
TARIFARIOPRECO   preco por kWh, taxa, de que dia ate que dia
```

Porque é que são duas tabelas?

Porque **os preços mudam**, e um carregamento de março tem de continuar a ser explicável com o preço de março.

```
TARIFARIO "Normal"
   TARIFARIOPRECO   0,25 EUR   de 01/01 a 30/06     <- fechado
   TARIFARIOPRECO   0,28 EUR   de 01/07 a ???       <- em vigor (sem data de fim)
```

A linha sem data de fim é a que está **em vigor agora**.

E o `PrecoKwhAtual` dentro do `Tarifario` é uma **cópia** dessa linha, mantida automaticamente por um trigger — para não ser preciso ir sempre à tabela do histórico. Também foi um pedido da professora.

### 8. O carregamento muda de estado

```
EmCurso  ->  Terminado  ->  Faturado
```

O carregamento guarda só o estado **atual**. Quem guarda o caminho é outra tabela:

```
CARREGAMENTOHISTORICO   estava assim -> passou a assado -> a esta hora
```

E ninguém a preenche à mão. É um **trigger** — código que dispara sozinho quando o estado muda.

### 9. No fim do mês, a fatura

```
FATURA   numero (FT2026/0001), quem paga, data de emissao, data de vencimento, metodo
```

A fatura **agrupa vários carregamentos** num documento só.

Isto foi a maior alteração pedida pela professora. Antes, cada carregamento era cobrado à parte — o que não é como funciona no mundo real.

> Repara: **quem paga** pode não ser **quem carregou**. O João conduz o carro da empresa; a empresa é que paga. Por isso o carregamento aponta ao *condutor* e a fatura aponta ao *pagador*.

### 10. O pagamento

```
PAGAMENTO   valor, data, meio (MBWay, cartao, transferencia)  ->  abate numa FATURA
```

Uma fatura pode receber **vários** pagamentos. É isso que permite representar um **pagamento parcial**:

```
FT2026/0007   valor da fatura       46,80 EUR
              pagamento em 15/07    31,20 EUR
              ------------------------------
              ainda em falta        15,60 EUR
```

Não há coluna "em dívida". Calcula-se. (Está explicado no guia da Parte D.)

### 11. Um dia o posto avaria

```
TIPOAVARIA           categorias de avaria
OCORRENCIA           que posto, que tipo, quando, custo da reparacao, estado
OCORRENCIAHISTORICO  o caminho dos estados, preenchido por trigger
```

Mesma lógica do carregamento: a ocorrência guarda o estado atual, o histórico guarda o percurso.

### 12. E um registo impossível

```
ALERTA   que carregamento, quanta energia registou, quanta era possivel, estado
```

Se um carregamento disser que entregou 45 kWh num posto de 22 kW durante 1 hora, isso é **fisicamente impossível**. Um trigger deteta e regista um alerta.

Esta é a funcionalidade nova do trabalho. Tem guia próprio.

---

# Parte 5 — As 17 tabelas, agrupadas

É assim que estão organizadas no diagrama, por cores:

```
REDE          Concelho · TipoConector · Posto · PostoConector
              onde ficam os postos e que tomadas tem

CLIENTES      Cliente · Veiculo
              quem carrega e com que carro

COMERCIAL     Tarifario · TarifarioPreco
              quanto custa, e quanto custava antes

OPERACAO      Reserva · Carregamento · CarregamentoHistorico
              o que acontece no dia a dia

FATURACAO     Fatura · Pagamento
              o dinheiro

MANUTENCAO    TipoAvaria · Ocorrencia · OcorrenciaHistorico · Alerta
              o que corre mal
```

---

# Parte 6 — O que o trabalho pede, em português

O enunciado tem cinco partes. Estas são as quatro que têm guia:

| | O que pede | Em linguagem simples |
|---|---|---|
| **B** | procedures, funções e triggers | código guardado **dentro** da base de dados |
| **C** | 7 relatórios obrigatórios | 7 perguntas que a base tem de saber responder |
| **D** | 1 relatório proposto por nós | uma pergunta que **nós** achámos importante |
| **E** | 1 funcionalidade nova | uma coisa que a Fase 1 não fazia |

### O que fizemos em cada uma

**B** — 4 procedures (um CRUD sobre o Tarifário), 2 funções, 4 triggers.

**C** — os 7 relatórios. Divididos: Fred faz o 3, 5 e 6; tu fazes o 1, 2, 4 e 7.

**D** — *"quanto dinheiro já foi entregue em energia e ainda não foi cobrado, de quem, e há quanto tempo?"*

**E** — o **Alerta**: detetar carregamentos fisicamente impossíveis.

---

# Parte 7 — Os ficheiros, e por que ordem se corre

```
01-criar-bd.sql       cria a base e as 17 tabelas       <-- APAGA a base anterior
02-dados-teste.sql    enche com dados
03-...triggers.sql    PARTE B
04-relatorios.sql     PARTE C
05-relatorio-...sql   PARTE D
06-parte-e-...sql     PARTE E
```

Sempre por esta ordem. Cada um assume que os anteriores já correram.

> **Atenção:** o `01` começa por apagar a base `VoltGo` e criá-la de novo. Se tiveres coisas tuas lá dentro, perdes.

---

# Parte 8 — Agora sim, o que ler a seguir

1. Abre o **`VoltGo-ModeloRelacional.png`** ao lado deste guia e procura as tabelas da história. Segue as setas.
2. **`01-as-quatro-alteracoes.md`** — o que mudou depois da conversa com a professora, e porquê.
3. O guia da parte que quiseres estudar (B, C, D ou E).
4. **`06-perguntas-da-defesa.md`** — na véspera da apresentação.

---

# Vocabulário, para consultar

| Palavra | Significado |
|---|---|
| **Entidade** | uma coisa do mundo real que merece tabela própria (um cliente, um posto) |
| **Atributo** | uma coluna (o nome, o NIF) |
| **Tuplo / registo** | uma linha |
| **PK** | chave primária — identifica a linha |
| **FK** | chave estrangeira — aponta para outra tabela |
| **AK / UNIQUE** | não pode repetir (o NIF, a matrícula) |
| **CHECK** | uma regra que a base verifica (ex.: o valor tem de ser positivo) |
| **DEFAULT** | valor que entra sozinho se não disseres nada |
| **NULL** | "ainda não se sabe" ou "não se aplica". **Não é zero nem texto vazio.** |
| **JOIN** | juntar duas tabelas pela seta que as liga |
| **Trigger** | código que dispara sozinho quando algo muda |
| **Procedure** | receita guardada na base; chamas pelo nome |
| **Função** | recebe valores e devolve um resultado |
| **Normalização** | separar em tabelas para não repetir informação |
| **Remoção lógica** | em vez de apagar, marcar como inativo |
