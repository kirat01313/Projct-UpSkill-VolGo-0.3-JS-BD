# Parte D — O relatório estratégico que propusemos

> Guia de estudo. O código está em `Entregaveis Finais/05-relatorio-proposto.sql`.

---

## 1. A pergunta

> **"Quanto dinheiro já foi entregue em energia e ainda não foi cobrado, de quem, e há quanto tempo?"**

Em uma frase: **quem é que já levou energia e ainda não pagou.**

---

## 2. Porque é que isto é estratégico e não apenas mais uma consulta

A VoltGo entrega primeiro e cobra depois.

```
dia 3   o cliente carrega                 -> a energia já foi entregue (custo real)
dia 31  a fatura é emitida                -> ainda não entrou dinheiro
dia 30 do mês seguinte  vencimento        -> talvez entre, talvez não
```

Nos clientes empresariais, com faturação mensal, o intervalo entre **entregar** e **receber** chega a dois meses.

Isto é um problema de **tesouraria**: a rede pode estar a crescer em carregamentos e a ficar sem dinheiro em caixa **ao mesmo tempo**. E nenhum indicador de utilização mostra isso — pelo contrário, um mês com muitos carregamentos por cobrar parece um mês excelente.

---

## 3. Porque nenhum dos sete obrigatórios responde a isto

| Relatório | O que dá | O que lhe falta |
|---|---|---|
| 3 | custo médio por tarifário | não olha a cobranças |
| 5 | conta pagamentos | não olha a prazos nem a valores em falta |
| 6 | soma o faturado | não distingue o **recebido** do que está **em aberto** |

É este vazio que justifica a proposta. Vale a pena dizê-lo assim na defesa: *"não é uma variação dos outros, é uma pergunta que nenhum deles faz."*

---

## 4. Onde está a informação — e porque não há coluna "EmDivida"

A regra 3.6 do enunciado pede para distinguir **faturado**, **pago** e **em dívida**. As duas primeiras leem-se diretamente. A terceira é **derivada**:

```
faturado    a fatura existe
pago        a soma dos pagamentos iguala o valor faturado
em dívida   a soma dos pagamentos é menor  E  o vencimento já passou
```

**Porque não criámos uma coluna `EmDivida`?**

Porque ela teria de ser reescrita **todos os dias à meia-noite**. Uma fatura que hoje está em dia, amanhã está em dívida — sem que ninguém lhe tenha tocado. A dívida nasce apenas da **passagem do tempo**.

> **A regra geral por trás disto:** 
>não se guarda o que se pode calcular, 
>sobretudo quando o valor muda sozinho.
> Guardar seria criar uma mentira com data de validade.

---

## 5. Como a consulta está construída

Está dividida em quatro blocos. Cada um responde a uma parte da pergunta.

### D1 — Dívida por entidade pagadora
*Quem deve, quanto, e há quanto tempo.*

Usa um **CTE** (o `WITH FaturaSaldo AS ...`), que é apenas uma consulta com nome, definida no início e usada a seguir. Serve para calcular uma vez o `ValorFaturado` e o `ValorRecebido` de cada fatura, e depois trabalhar com esses dois números como se fossem colunas normais.

> **Aqui o JOIN é INNER, não LEFT.** Um cliente sem dívida não tem lugar num relatório de dívidas. Pela mesma razão os filtros vão no `WHERE` — não há linhas vazias a proteger.
> Isto é o contrário do que fizemos na Parte C, e é de propósito. A escolha do JOIN depende sempre da pergunta.

### D2 — A mesma dívida, por antiguidade
*Uma dívida de 30 dias resolve-se com um email. Uma de 90 é outro problema.*

```
1 - até 30 dias
2 - 31 a 60 dias
3 - 61 a 90 dias
4 - mais de 90 dias
```

**Detalhe técnico que cai:** o `CASE` que constrói o escalão tem de ser **repetido inteiro no `GROUP BY`**. Não se pode agrupar pelo apelido da coluna, porque na altura em que o `GROUP BY` corre esse apelido ainda não existe.

### D3 — Detalhe, fatura a fatura
*Para a operadora poder agir: a quem telefonar e por quanto.*

Mostra também as **parciais** — o cliente que pagou uma parte e ficou a dever o resto. Este é exatamente o caso que a Fase 1 não conseguia representar.

### D4 — O caso de controlo (não faz parte do relatório)
Faturas por pagar mas **ainda dentro do prazo**. Não são dívida e têm de ficar de fora.

> **Porque é que isto vale pontos:** sem este caso nos dados de teste, uma consulta que se esquecesse da condição da data devolveria **exatamente o mesmo resultado** — e ninguém dava por isso.
> Ter o caso de controlo é o que transforma um teste num teste a sério.

---

## 6. Resultados reais (já executados)

```
TransNorte Lda      15,60 EUR   pagou uma parte e ficou a dever o resto
Gabriela Pinto       6,66 EUR   66 dias de atraso
Carla Mendes         6,16 EUR   45 dias de atraso

controlo: FT2026/0020  por pagar, mas ainda dentro do prazo  -> não conta
```

Os três casos são diferentes de propósito: um **parcial**, um **muito atrasado**, um **atrasado**. E o quarto está lá para provar que a data está a ser respeitada.

---

## 7. A ligação à Fase 1

Isto vem do `relatorioPorCobrar` que estava pensado para a aplicação de consola.

**O que a Fase 1 conseguia:** saber se o carregamento estava terminado ou faturado. Os ficheiros JSON não sabiam mais nada.

**O que a base de dados acrescenta:**
- data de emissão e data de vencimento → dá para calcular **atraso**
- vários pagamentos por fatura → dá para representar **pagamentos parciais**

> **A frase para a defesa:** "A Fase 1 sabia dizer *não está pago*. A Fase 2 sabe dizer *falta 15,60 € há 66 dias, do cliente X, que já pagou uma parte*."
