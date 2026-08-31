# Parte B — Procedimentos, Funções e Triggers

> Guia de estudo. Explica **o que é**, **porque existe** e **o que dizer à professora**.
> O código está em `Entregaveis Finais/03-procedures-funcoes-triggers.sql`, todo comentado.

---

## 1. As três ferramentas, em linguagem simples

Imagina a base de dados como uma cozinha.

| Ferramenta | O que é | Analogia |
|---|---|---|
| **Stored Procedure** | Um conjunto de passos guardado dentro da base de dados. Chamas pelo nome e ele executa. | Uma **receita**. Dizes "faz o bolo" e ele faz os 8 passos. |
| **Função** | Recebe valores, calcula e **devolve um resultado**. | Uma **calculadora**. Dás 2 números, devolve a soma. |
| **Trigger** | Código que dispara **sozinho** quando algo acontece numa tabela. | Um **alarme de fumo**. Ninguém o liga; ele reage. |

### A diferença que a professora vai perguntar

**Procedure vs Função:**
- A procedure **faz coisas** (insere, atualiza, apaga). Não se pode usar dentro de um `SELECT`.
- A função **devolve um valor** e não pode alterar dados. Usa-se dentro de um `SELECT`, como se fosse uma coluna.

**Trigger vs os outros dois:**
- Procedure e função só correm se **alguém as chamar**.
- O trigger corre **sem ninguém pedir**. É essa a graça e é esse o perigo.

---

## 2. O que fizemos — visão geral

```
3 TRIGGERS
  TR_Carregamento_Historico          escreve o histórico do carregamento
  TR_Ocorrencia_Historico            escreve o histórico da ocorrência
  TR_TarifarioPreco_SincronizaAtual  mantém o preço do Tarifário sincronizado  <-- NOVO

4 PROCEDURES  (o CRUD que a professora pediu, sobre o Tarifário)
  usp_Tarifario_Inserir              C — Create
  usp_Tarifario_Listar               R — Read
  usp_Tarifario_Atualizar            U — Update
  usp_Tarifario_Descontinuar         D — Delete (lógico, não apaga nada)

2 FUNÇÕES
  fn_PrecoEmVigor                    escalar        — devolve um número
  fn_EstatisticasPosto               tabular        — devolve uma tabela
```

---

## 3. O CRUD com procedures — porquê o Tarifário

A professora pediu **uma tarefa simples**. O Tarifário é a escolha certa por três razões:

1. **É pequeno.** Tem 5 colunas. Não distrai da matéria.
2. **Tem uma regra real por trás.** Não se pode simplesmente mudar o preço: é preciso fechar a vigência antiga e abrir uma nova. Isso obriga a usar uma **transação**.
3. **Tem apagar lógico.** O enunciado (regra 3.8) proíbe apagar. O `D` do CRUD vira "descontinuar".

### O que cada procedure faz

**`usp_Tarifario_Inserir`** — cria o tarifário **e** a primeira vigência de preço, numa só operação.
Se a segunda parte falhar, a primeira é desfeita. É isso que a `TRANSACTION` garante: ou entra tudo, ou não entra nada.

> **Porquê importa:** sem transação, podias ficar com um tarifário sem preço nenhum. Uma linha inútil que ninguém consegue explicar.

**`usp_Tarifario_Listar`** — lê. Com um parâmetro opcional para mostrar ou esconder os descontinuados.

**`usp_Tarifario_Atualizar`** — muda o nome, ou muda o preço. Mudar o preço significa:
1. fechar a vigência atual (pôr-lhe `DataFim`)
2. abrir uma nova a partir de hoje

Isto é o coração da ideia de **histórico**: o preço antigo não desaparece, fica fechado.

**`usp_Tarifario_Descontinuar`** — põe `Comercializado = 0` e fecha a vigência aberta.
Não apaga linha nenhuma. Os carregamentos antigos continuam a apontar para o tarifário e continuam a fazer sentido.

> **Se a professora perguntar "porque não apagam?":**
> Porque um carregamento de março de 2026 foi cobrado a um preço. Se apagares o tarifário, esse carregamento fica órfão e a fatura deixa de ser explicável. Apagar destrói o passado.

---

## 4. As duas funções

### `fn_PrecoEmVigor(tarifário, data)` — função **escalar**

Devolve **um número**: quanto custava o kWh desse tarifário naquele dia.

Exemplo real, testado:

```
fn_PrecoEmVigor(1, '2026-03-15')  ->  0.2500
fn_PrecoEmVigor(1, '2026-08-15')  ->  0.2800
```

Mesmo tarifário, datas diferentes, preços diferentes. É a prova de que o histórico funciona.

> **Onde isto se usa:** para refazer uma fatura antiga. Se um cliente reclamar de um carregamento de março, precisas do preço de março, não do de hoje.

### `fn_EstatisticasPosto(posto)` — função **tabular**

Devolve **uma tabela** com os indicadores de um posto: número de carregamentos, energia total, receita, média por carregamento e potência média real entregue.

> **A diferença entre as duas:**
> A escalar devolve uma célula. A tabular devolve uma grelha, e usa-se no `FROM` como se fosse uma tabela normal.

**Descoberta interessante nos testes:** os postos P001 e P012 aparecem com potência média de **25,00 kW** e **27,20 kW**, quando o cartão de identidade deles diz **22 kW**. Isto é fisicamente impossível — e foi o que deu origem à Parte E.

---

## 5. Os triggers

### 5.1 Os dois triggers de histórico

Sempre que um carregamento (ou uma ocorrência) muda de estado, escreve-se uma linha no histórico a dizer: *estava assim, passou a estar assado, a esta hora*.

Ninguém tem de se lembrar de o fazer. É o trigger que faz.

```
Carregamento 12:  EmCurso  ->  Terminado  ->  Faturado

CarregamentoHistorico:
  linha 1 |  (nada)   -> EmCurso    | 12/08 14:02
  linha 2 |  EmCurso  -> Terminado  | 12/08 15:20
  linha 3 |  Terminado-> Faturado   | 31/08 09:00
```

O carregamento em si só guarda o estado **atual**. O histórico guarda o **caminho**.

### 5.2 O trigger novo — sincronizar o preço

Este resolve um pedido concreto da professora.

**O pedido:** ter o preço atual dentro da tabela `Tarifario`, para não ter de ir sempre à `TarifarioPreco`.

**O problema imediato:** passa a haver a mesma informação em dois sítios. Se alguém muda um e esquece o outro, a base de dados fica a dizer duas coisas diferentes. Isto chama-se **redundância**, e normalmente evita-se.

**A solução:** deixar de ser possível esquecer.

```
Alguém mexe na TarifarioPreco
        |
        v
TR_TarifarioPreco_SincronizaAtual dispara sozinho
        |
        v
Vai ver qual é a vigência aberta (DataFim IS NULL)
        |
        v
Copia esse preço e essa taxa para o Tarifario
```

> **A frase para dizer à professora:**
> "A `TarifarioPreco` continua a ser a fonte da verdade. As colunas no `Tarifario` são uma **cópia mantida automaticamente**. Aceitámos a redundância porque o trigger torna a divergência impossível."

Se um tarifário deixar de ter vigência aberta, a cópia fica a `NULL` — e isso é correto: não há preço em vigor.

---

## 6. O erro clássico dos triggers (e a matéria que cai)

Dentro de um trigger existem duas tabelas especiais:

| Tabela | O que tem |
|---|---|
| `inserted` | as linhas **como ficaram** |
| `deleted` | as linhas **como estavam antes** |

| Operação | `inserted` | `deleted` |
|---|---|---|
| INSERT | tem as linhas novas | vazia |
| UPDATE | tem os valores novos | tem os valores antigos |
| DELETE | vazia | tem as linhas apagadas |

**O erro que toda a gente comete:** tratar `inserted` como se fosse **uma linha**.

Não é. É uma **tabela**. Se alguém fizer um `UPDATE` que afeta 50 carregamentos, o trigger dispara **uma vez** com 50 linhas lá dentro — e não 50 vezes.

Por isso os nossos triggers usam `INSERT ... SELECT`, que trata o conjunto todo de uma vez, em vez de variáveis que só aguentam um valor.

---

## 7. Perguntas prováveis da defesa

**"Porque é que o trigger não bloqueia nada?"**
Estes três triggers registam e sincronizam. Não recusam nada. O único que poderia recusar é o da Parte E, e decidimos deliberadamente que também não bloqueia — ver o guia da Parte E.

**"Porque é que o D do CRUD não apaga?"**
Regra 3.8 do enunciado: remoção lógica. Além disso, apagar partiria as chaves estrangeiras dos carregamentos antigos.

**"Podiam ter feito isto sem procedure?"**
Podíamos, escrevendo o SQL à mão de cada vez. A procedure garante que os passos são sempre os mesmos e que a transação existe sempre. É a diferença entre uma receita escrita e cozinhar de memória.
