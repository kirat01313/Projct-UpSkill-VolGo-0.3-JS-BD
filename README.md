# VoltGo — Gestão de Carregamentos de Veículos Elétricos

Trabalho prático da formação UpSkill — Algoritmia e Programação (IPCA).
Formadora: Marta Martinho.

Aplicação de consola em JavaScript / Node.js para uma operadora de mobilidade
elétrica gerir os carregamentos da sua rede de postos: manutenção de dados
(CRUD), integridade das referências, dashboard e relatórios.

Este repositório cobre a **Fase 1 (Programação)**. A pasta `2-base-dados/`
está reservada para a Fase 2 e ainda não tem trabalho feito.

- **Grupo:** Tarik Guaranho e Frederico Busich
- **Aplicação:** `1-algoritmia/`

---

## Instruções de execução

Requisitos: [Node.js](https://nodejs.org) instalado (desenvolvido e testado na
versão 24). O `npm` vem incluído com o Node.

**1. Obter o projeto**

```bash
git clone https://github.com/kirat01313/VoltGo-3.0.git
```

**2. Entrar na pasta da aplicação**

Todos os comandos seguintes são dados a partir de `1-algoritmia/`, não da raiz
do repositório:

```bash
cd "VoltGo-3.0/1-algoritmia"
```

**3. Instalar a dependência**

```bash
npm install
```

O projeto tem uma única dependência externa, `readline-sync`, usada para ler o
input do utilizador no terminal. A pasta `node_modules/` não é versionada, por
isso este passo é obrigatório na primeira utilização.

**4. Correr**

```bash
npm start
```

Equivalente a `node index.js`. A aplicação arranca mostrando o dashboard,
seguido do menu principal. Navega-se escrevendo o número da opção e
pressionando Enter; `0` sai (ou volta ao menu anterior, nos submenus).

### Onde ficam os dados

Os dados são guardados em ficheiros JSON na pasta `1-algoritmia/data/`, um por
entidade:

```
data/postos.json          postos de carregamento
data/clientes.json        clientes
data/tarifarios.json      tarifários
data/carregamentos.json   carregamentos (tabela principal)
```

A gravação é feita a cada operação de escrita, pelo que os dados persistem
entre execuções. Os ficheiros já vêm preenchidos com dados de exemplo, que
incluem **casos de teste propositadamente problemáticos** (um carregamento a
apontar para um posto inexistente, outro com as datas invertidas, outro com uma
energia fisicamente impossível para a potência do posto). Servem para
demonstrar a auditoria descrita mais abaixo. Se um ficheiro não existir ou
estiver vazio, a aplicação assume a lista como vazia em vez de dar erro.

---

## Estrutura do projeto

```
VoltGo 3.0/
├── 1-algoritmia/            Fase 1 — a aplicação
│   ├── index.js             porta de entrada: só chama o menu principal
│   ├── package.json         dependências e o script "start"
│   ├── data/                os ficheiros .json com os dados
│   └── src/
│       ├── 1-cli/           menus (interação com o utilizador)
│       ├── 2-repositories/  CRUD e leitura/escrita dos JSON
│       ├── 3-services/      cálculos: dashboard, relatórios, extras
│       └── utils/           validações e constantes do negócio
└── 2-base-dados/            Fase 2 — BD
```

### As camadas

O código está separado em três camadas, com uma regra de dependência: os menus
chamam os services e os repositories, os services chamam os repositories, e os
repositories só falam com os ficheiros JSON. 

**`1-cli/` — menus.** A única camada que fala com o utilizador: mostra opções,
lê o input e imprime resultados. Não faz contas nem lê ficheiros.

- `menu.js` — menu principal e impressão do dashboard
- `cli-tarik/menuPostos.js`, `cli-tarik/menuClientes.js`
- `cli-fred/menuTarifarios.js`, `cli-fred/menuCarregamentos.js`
- `menuRelatorios.js` — relatórios 4.1 e 4.2
- `menuDiferenciador.js` — funcionalidades extra

A divisão em `cli-tarik/` e `cli-fred/` foi uma decisão de organização de
trabalho: cada um mexe na sua pasta, o que evita conflitos no git.

**`2-repositories/` — gestão de dados.** Um ficheiro por entidade, cada um com
as suas quatro operações (listar, inserir, atualizar, remover) e o caminho do
seu JSON. Não imprime nada e não pergunta nada: devolve valores, e é o menu que
decide a mensagem a mostrar. Convenção de retorno usada nos quatro:

```
listar     -> o array (vazio se não houver nada)
inserir    -> o objeto inserido, ou null se foi recusado
atualizar  -> o objeto atualizado, ou null se não existe
remover    -> true se removeu, false se não
```

**`3-services/` — cálculos.** Recebem os dados dos repositories, calculam e
devolvem o resultado num objeto. Também não imprimem, o que os torna
reutilizáveis (por exemplo, `analiseService.js` alimenta duas opções de menu
diferentes a partir do mesmo cálculo).

- `dashboardService.js` — os três indicadores do arranque
- `relatorioService.js` — relatórios 4.1 e 4.2
- `diferenciadorService.js` — receita por concelho
- `analiseService.js` — análise de desvios e auditoria

**`utils/` — auxiliares.** `validacao.js` reúne as funções que leem input e
repetem a pergunta até vir um valor aceitável (texto não vazio, número
positivo, NIF de 9 dígitos, data válida no formato `AAAA-MM-DD`, data/hora no
formato `AAAA-MM-DD HH:mm`), mais os cálculos de idade e de duração.
`constantes.js` fixa os valores permitidos do negócio: concelhos, tipos de
conector e estados de posto.

---

## Funcionalidades

### Manutenção de dados (CRUD)

As quatro entidades — postos, clientes, tarifários e carregamentos — têm
inserção, listagem, atualização e remoção, acessíveis pelas opções 1 a 4 do
menu principal.

Os dados introduzidos são validados no momento da leitura: campos obrigatórios
não aceitam vazio, campos numéricos não aceitam letras nem valores negativos,
as datas têm de existir mesmo (30 de fevereiro é recusado, e os anos bissextos
são tratados), e as chaves não podem repetir-se — código de posto, NIF de
cliente e nome de tarifário são únicos. As chaves não são alteráveis: ao
atualizar um registo, pedem-se apenas os restantes campos.

### Integridade das referências

- Um **posto** não pode ser removido se existirem carregamentos nele.
- Um **tarifário** não pode ser removido se estiver a ser usado.
- Ao inserir um carregamento, o posto, o cliente e o tarifário indicados têm de
  existir; além disso, o posto tem de estar `ativo` (um posto em manutenção não
  recebe carregamentos novos).
- Ao fechar um carregamento, a energia registada é comparada com o teto físico
  do posto (potência × duração). Um valor impossível é recusado.

### Dashboard

Apresentado uma vez, ao arrancar a aplicação, com três indicadores. Cada um
filtra estados diferentes:

```
=== Dashboard ===
Carregamentos em curso: 2
Carregamentos terminados: 7
Carregamentos faturados: 5

Por posto (só carregamentos terminados):
  P001 -> 4 carregamento(s), média de 26.25 kWh
  P002 -> 2 carregamento(s), média de 10.00 kWh
  P999 -> 1 carregamento(s), média de 15.00 kWh

Por tarifário (só carregamentos faturados):
  Normal -> 2 carregamento(s), média de 48.00 EUR
  Verde -> 3 carregamento(s), média de 2.20 EUR
```

### Relatórios

**4.1 — Carregamentos e custos** (opções 1 e 2 do menu Relatórios). Lista os
carregamentos `terminado` ou `faturado`, agrupados por posto ou por cliente,
com a energia e o custo de cada um, subtotal por grupo e somatório final.

```
Posto P002:
  #6 | 10 kWh | 3.00 EUR
  #7 | 40 kWh | 1.10 EUR
  #14 | 10 kWh | 3.00 EUR
  Subtotal: 60.00 kWh | 7.10 EUR
```

**4.2 — Clientes com carregamentos** (opção 3). Para cada cliente: nome, idade
calculada a partir da data de nascimento, contacto, matrícula, número de
carregamentos e energia total consumida.

```
Frederico | 23 anos | 912795272 | AB-55-CD | 3 carregamentos | 360 kWh
Eva Semcarregamentos | 30 anos | 944444444 | EE-55-EE | 0 carregamentos | 0 kWh
```

Clientes sem carregamentos aparecem com zero, em vez de desaparecerem da lista.

---

## Requisitos diferenciadores

Ambos estão no menu **6. Funcionalidades extra**.

### 1. Receita por concelho (Fred)

`src/3-services/diferenciadorService.js`

Responde à pergunta "em que concelhos é que o negócio rende mais?". Um
carregamento guarda apenas o código do posto; o concelho está guardado no
posto. A função percorre os carregamentos `faturado` e, para cada um, procura o
posto correspondente para descobrir o concelho — o único cruzamento entre duas
entidades desta parte do trabalho. Depois soma a receita por concelho e no
total.

Duas decisões deliberadas: contam-se apenas os carregamentos **faturados**,
porque um carregamento terminado ainda não foi cobrado e não é receita; e todos
os concelhos onde a operadora trabalha aparecem, mesmo os que ainda não deram
dinheiro, porque um concelho a zero é precisamente a informação que interessa a
quem decide onde investir. Se um carregamento apontar para um posto que já não
existe, aparece agrupado como `(posto desconhecido)` em vez de ser descartado
em silêncio.

Utilidade para a operadora: mostra onde a rede está a gerar retorno e onde não
está, e é a base natural para uma decisão de expansão.

Output real com os dados de exemplo incluídos:

```
Receita por concelho (só carregamentos faturados):
  braga -> 1 carregamento(s), 90.00 EUR
  porto -> 1 carregamento(s), 1.10 EUR
  lisboa -> 1 carregamento(s), 3.30 EUR
  guimarães -> 2 carregamento(s), 8.20 EUR
Receita total: 102.60 EUR
```

### 2. Análise de desvios e auditoria de registos (Tarik)

`src/3-services/analiseService.js`

Compara, em cada carregamento já concluído, quanto tempo ele **deveria** ter
demorado com quanto tempo **realmente** demorou:

```
previsto = energia registada (kWh) / potência do posto (kW)
real     = dataHoraFim - dataHoraInicio
desvio   = real - previsto          (positivo = demorou mais)
```

O desvio é quase sempre positivo, e isso é esperado: a potência do posto é um
teto, não uma garantia — o carro reduz o consumo à medida que a bateria enche,
e pode ficar ligado depois de já estar cheio. O que interessa à operadora não é
o desvio de um carregamento isolado, mas o padrão: a **média** diz se a
previsão dada ao cliente é otimista, e o **desvio padrão** diz se o erro é
consistente ou errático. Um desvio padrão maior do que a média é sinal de que
há registos anómalos a distorcer o retrato.

Para calcular o desvio é preciso descartar os carregamentos que não servem, e
são exatamente essas verificações que constituem a **auditoria** — o mesmo
ciclo produz duas saídas: os registos válidos entram na estatística, os
rejeitados vão para uma lista de problemas com o motivo. Um carregamento `em
curso` ou `anulado` é simplesmente ignorado, porque ainda não há nada para
medir; não é um problema.

A auditoria deteta cinco situações: carregamento a apontar para um posto que
não existe; carregamento dado como terminado sem data/hora de fim válida; data
de fim anterior à de início; carregamento terminado com 0 kWh registados; e
energia registada acima do que o posto consegue fisicamente entregar naquele
tempo. Utilidade para a operadora: são erros de registo ou de medição que
passariam despercebidos na listagem normal e que corrompem a faturação e os
relatórios.

Output real com os dados de exemplo incluídos (opção 2 — cada `#` representa 5
minutos de desvio). Excerto: dos nove carregamentos analisados, omitem-se aqui
as linhas dos registos #2 e #15, cujas barras são demasiado longas para caber
na página:

```
  id | posto | previsto |  real |  desvio
   1 | P001  |     33m |   60m |    +27m  #####
   7 | P002  |     48m |   90m |    +42m  ########
   8 | P004  |     55m |   60m |     +5m  #
   9 | P005  |    136m |  180m |    +44m  #########
  11 | P001  |    164m |  180m |    +16m  ###
  13 | P004  |     36m |   60m |    +24m  #####
  14 | P002  |     12m |   60m |    +48m  ##########
```

O registo #15 é um bom exemplo do que a estatística revela: ficou registado
como tendo demorado 252 dias, o que arrasta a média dos desvios para valores
absurdos e faz o desvio padrão disparar muito acima dela. É esse contraste
entre média e desvio padrão que sinaliza a existência de registos a corrigir.

E a auditoria (opção 3), que apanha os três registos problemáticos incluídos de
propósito nos dados de exemplo:

```
  3 registo(s) com problemas:
  Carregamento #5 -> 23 kWh é impossível: o posto P001 (22 kW) só entrega 22.0 kWh em 1.0h.
  Carregamento #6 -> A data de fim não é depois da data de início.
  Carregamento #10 -> Aponta para o posto P999, que não existe.
```

---

## Divisão de tarefas

| Tarik Guaranho ---------------|----------------- Frederico Busich |
|-------------------------------|-----------------------------------|
| Postos (menu + repositório)   |   Tarifários (menu + repositório) |
| Clientes (menu + repositório) |   Carregamentos (menu + repositório) |
| Relatório 4.2 — clientes com carregamentos    |    Relatório 4.1 — carregamentos e custos |
| Diferenciador: análise de desvios e auditoria |    Diferenciador: receita por concelho |

O **dashboard** (`3-services/dashboardService.js`) foi feito em conjunto.

O ficheiro **`utils/validacao.js`** é partilhado: a maior parte das funções são
do Tarik — as que leem input e insistem até vir um valor válido
 e as três validações que respondem apenas
sim/não (`campoObrigatorio`, `valorPositivo`, `dataHoraValida`) são do Fred, mais os
cálculos de idade e duração,
usadas dentro dos repositórios dele. Na prática, ambos usam as funções do
outro: os menus do Fred leem input com as funções do Tarik, e o
`analiseService.js` do Tarik valida datas com a função do Fred.

---

## Notas técnicas

- **Módulos ES** (`import` / `export`), com `"type": "module"` no `package.json`.
- **Leitura e escrita síncronas** (`readFileSync` / `writeFileSync` e
  `readline-sync`), sem `async`/`await`. Foi uma decisão tomada no início: numa
  aplicação de consola que espera pelo utilizador a cada passo, o síncrono
  mantém o fluxo do código igual ao fluxo da execução.

