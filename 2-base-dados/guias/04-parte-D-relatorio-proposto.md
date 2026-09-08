# Parte D — O relatório estratégico que propusemos

> Guia de estudo. O código está em `Entregaveis Finais/05-relatorio-proposto.sql`.

---

## 1. A pergunta

> **"Quanto dinheiro já foi entregue em energia e ainda não foi cobrado, de quem, e há quanto tempo?"**

Em uma frase: **quem é que já levou energia e ainda não pagou.**

---

## 2. Porque é estratégica

A VoltGo entrega primeiro e cobra depois.

```
dia 3   o cliente carrega                -> a energia ja foi entregue (custo real)
dia 31  a fatura e emitida               -> ainda nao entrou dinheiro
dia 30 do mes seguinte  vencimento       -> talvez entre, talvez nao
```

Nos clientes empresariais, com faturação mensal, o intervalo entre **entregar** e **receber** chega a dois meses.

É um problema de **tesouraria**: a rede pode estar a crescer em carregamentos e a ficar sem dinheiro em caixa **ao mesmo tempo**. Nenhum indicador de utilização mostra isso — pelo contrário, um mês com muitos carregamentos por cobrar parece um mês excelente.

---

## 3. Porque nenhum dos sete obrigatórios responde

| Relatório | O que dá | O que lhe falta |
|---|---|---|
| 3 | custo médio por tarifário | não olha a cobranças |
| 5 | conta pagamentos | não olha a prazos nem a valores em falta |
| 6 | soma o faturado | não distingue o **recebido** do que está **em aberto** |

É este vazio que justifica a proposta. Na defesa: *"não é uma variação dos outros, é uma pergunta que nenhum deles faz."*

---

## 4. Porque não há coluna "EmDivida"

A regra 3.6 pede para distinguir **faturado**, **pago** e **em dívida**. As duas primeiras leem-se diretamente. A terceira é **derivada**:

```
faturado    a fatura existe
pago        a soma dos pagamentos iguala o valor faturado
em divida   a soma dos pagamentos e menor  E  o vencimento ja passou
```

Uma coluna `EmDivida` teria de ser reescrita **todos os dias à meia-noite**. Uma fatura que hoje está em dia, amanhã está em dívida — sem que ninguém lhe tenha tocado. A dívida nasce apenas da **passagem do tempo**.

> **A regra geral:** não se guarda o que se pode calcular, sobretudo quando o valor muda sozinho. Guardar seria criar uma mentira com data de validade.

---

## 5. As duas consultas

O enunciado pede **uma**. Estão aqui duas, porque respondem à mesma pergunta em dois níveis.

### D1 — o detalhe

Lista todas as faturas com valor em falta, **vencidas ou não**, e classifica cada uma numa coluna.

```
Fatura        Entidade         EmFalta  Situacao               Pagamentos
FT2026/0005   Carla Mendes       6,16   Em divida ha 74 dias   Nunca pagou nada
FT2026/0006   Maria Costa        7,16   Em divida ha 53 dias   Nunca pagou nada
FT2026/0007   TransNorte Lda     5,60   Em divida ha 9 dias    Pagou em parte
FT2026/0008   EcoFrota SA        6,70   Dentro do prazo        Nunca pagou nada
```

**A última linha é o caso de controlo.** Tem valor em falta, mas ainda não venceu — não é dívida.

> **Porque é que isto vale pontos:** se a consulta se esquecesse da condição da data, a FT2026/0008 aparecia como dívida e ninguém dava por isso. Pondo as duas situações na mesma tabela, o contraste fica à vista e o resultado torna-se **verificável**.

O `CASE` é o que constrói a coluna `Situacao`. É a mesma ideia do `if` de outras linguagens.

### D2 — o resumo

Agora só as vencidas, agrupadas por quem paga. É o número que interessa a quem gere a tesouraria: a quem telefonar, e por quanto.

```
EntidadePagadora   FaturasEmDivida   TotalEmDivida   DiasDaMaisAntiga
Maria Costa               1               7,16             53
Carla Mendes              1               6,16             74
TransNorte Lda            1               5,60              9
```

> **Aqui o JOIN é INNER, não LEFT.** Um cliente sem dívida não tem lugar num relatório de dívidas. Pela mesma razão os filtros vão no `WHERE` — não há linhas vazias a proteger.
>
> É o **contrário** do que fizemos na Parte C, e é de propósito: a escolha da junção depende sempre da pergunta.

---

## 6. A subconsulta no FROM

As duas consultas começam por um bloco entre parênteses a que chamámos `fs`:

```sql
FROM (SELECT ... ) AS fs
```

Isso é uma **tabela derivada**: calculas o valor faturado e o valor recebido de cada fatura uma vez, dás-lhe um nome, e a partir daí usas esses dois números como se fossem colunas normais.

Sem isto, o mesmo cálculo tinha de ser repetido no `SELECT`, no `WHERE` e no `ORDER BY` da mesma consulta — e bastava enganar-se numa cópia para o resultado ficar errado.

> No curso do Bóson é a **aula 44**, "Subconsultas com Tabelas Derivadas". Foi dado no material da professora.

---

## 7. A ligação à Fase 1

Vem do `relatorioPorCobrar` pensado para a aplicação de consola.

**O que a Fase 1 conseguia:** saber se o carregamento estava terminado ou faturado. Os ficheiros JSON não sabiam mais nada.

**O que a base de dados acrescenta:**
- data de emissão e de vencimento → dá para calcular **atraso**
- vários pagamentos por fatura → dá para representar **pagamentos parciais**

> **A frase:** *"a Fase 1 sabia dizer 'não está pago'. A Fase 2 sabe dizer 'faltam 5,60 € há 9 dias, do cliente X, que já pagou uma parte'."*
