# Treino de consultas — para escrever SQL à frente dela

> A apresentação da Fase 1 mostrou o formato: ela senta-se ao lado, lê o código
> convosco, pergunta o porquê de cada escolha, e pode pedir uma alteração ao
> vivo. Numa cadeira de bases de dados, *"escreva-me uma consulta que..."* é o
> pedido mais provável de todos.
>
> Este guia não é para decorar. É para **praticar a escrever**.

---

## 1. Antes de tudo: a base tem de estar a correr

Confirmado a 2 de setembro de 2026, com os seis scripts corridos por ordem:

```
tabelas ......... 17      (as 15 antigas + Fatura + Alerta)
procedures ...... 12      (3 CRUDs × 4 operações)
funções .........  3
triggers ........  4
alertas gerados .  3      (a Parte E a funcionar sozinha)
```

Para verificares a qualquer momento, no SSMS:

```sql
SELECT COUNT(*) FROM sys.tables;        -- tem de dar 17
SELECT * FROM Alerta;                   -- tem de ter linhas
SELECT Nome, PrecoKwhAtual FROM Tarifario;   -- o trigger de sincronização
```

Se o `PrecoKwhAtual` estiver todo a `NULL`, o script `03` não correu.

---

## 2. As duas cadeias — sabe-as de cor

Metade das consultas que ela pode pedir são uma destas duas, com um `GROUP BY`
diferente no fim.

### A cadeia do ONDE
```
Carregamento → PostoConector → Posto → Concelho
```
Sempre que a pergunta envolve **lugar** — concelho, posto, tipo de tomada — é
por aqui. São 3 saltos porque o `IDPosto` saiu do `Carregamento` (alteração 2).

### A cadeia do DINHEIRO
```
Carregamento → Fatura → Pagamento
```
Sempre que a pergunta envolve **dinheiro recebido** — pago, em dívida, por
cobrar — é por aqui. São 2 saltos porque a `Fatura` entrou no meio
(alteração 1).

> **Se te esqueceres de tudo o resto, lembra-te destas duas.** Com elas
> respondes a quase qualquer pedido, mudando só o `GROUP BY`.

---

## 3. Os teus três relatórios — o que produzem hoje

Outputs reais, com os dados de teste atuais.

### Relatório 3 — custo médio por tarifário

```
Tarifario     AindaSeVende  PrecoEmVigor  Faturados  CustoMedio  CustoTotal
Rápido        Nao           NULL                  2       18.50       37.00
Empresarial   Sim           0.2000                6       10.37       62.22
Normal        Sim           0.2800                9        8.64       77.74
Verde         Sim           0.2200                4        7.27       29.06
```

**O que apontar:** o `Rápido` tem `PrecoEmVigor` a `NULL` porque foi
descontinuado — não tem vigência aberta. Mas continua a ter **2 carregamentos
faturados** no histórico. É a prova viva de que a remoção lógica funciona: o
tarifário deixou de se vender e o passado ficou intacto.

### Relatório 5 — carregamentos e respetivos pagamentos

Três situações, e são o objetivo do relatório:

```
#22..#37   Terminado   sem fatura              -> ainda não faturado
#5,17,19   Faturado    0 pagamentos            -> FATURADO E POR COBRAR  ← é este
#4, #21    Faturado    1 pagamento, parcial    -> Pago em parte
#1, #2...  Faturado    pago na totalidade      -> Pago
```

**O que apontar:** os `#4` e `#21` estão os dois na fatura `FT2026/0019` —
25,60 € faturados, 10,00 € recebidos. É o **pagamento parcial** que a alteração
1 veio permitir, e que a versão anterior não conseguia representar de todo.

### Relatório 6 — concelhos e valor faturado

```
Concelho     Postos  Carregamentos  Faturas  TotalFaturado
Porto             4             12        7          77.97
Braga             4             12        7          72.39
Lisboa            3              8        4          43.58
Guimarães         2              5        2          12.08
Coimbra           0              0        0           0.00     ← o que prova tudo
```

**O que apontar:** Coimbra. Não tem postos nenhuns e aparece na mesma, com
zero. Se algum dos quatro `JOIN` fosse `INNER`, ela desaparecia — e o enunciado
pede explicitamente que apareça.

O `6b` filtra com `HAVING > 50` e sobram só Porto e Braga. O `6c` mostra o
**recebido por fatura**, porque uma fatura mensal pode cobrir postos de
concelhos diferentes e o dinheiro não é atribuível a um só.

### Parte D — o teu relatório proposto

```
EntidadePagadora   FaturasEmDivida  TotalEmDivida  DiasDaMaisAntiga
TransNorte Lda                   1          15.60                 3
Gabriela Pinto                   1           6.66                68
Carla Mendes                     1           6.16                47
```

E os escalões de antiguidade:

```
1 - até 30 dias      1 fatura    15.60
2 - 31 a 60 dias     1 fatura     6.16
3 - 61 a 90 dias     1 fatura     6.66
```

**O que apontar:** a `FT2026/0020` da EcoFrota está por pagar **mas não
aparece** — vence a 30/09, ainda está dentro do prazo. Não é dívida, é uma
fatura normal. Está nos dados de propósito para provar que o relatório
distingue as duas coisas.

---

## 4. As oito consultas de treino

**Todas testadas contra a base a 2 de setembro de 2026.** Tapa a resposta,
escreve, e só depois compara.

---

### 1. Quantos carregamentos por concelho?

<details>
<summary>Resposta</summary>

```sql
SELECT   co.Nome AS Concelho, COUNT(c.IDCarregamento) AS Carregamentos
FROM     Concelho co
         LEFT JOIN Posto         p  ON p.IDConcelho      = co.IDConcelho
         LEFT JOIN PostoConector pc ON pc.IDPosto        = p.IDPosto
         LEFT JOIN Carregamento  c  ON c.IDPostoConector = pc.IDPostoConector
GROUP BY co.Nome
ORDER BY Carregamentos DESC;
```
`Braga 14 · Porto 12 · Lisboa 8 · Guimarães 5 · Coimbra 0`

**Os dois pontos:** todos os `JOIN` são `LEFT` (senão Coimbra desaparece), e é
`COUNT(coluna)` e não `COUNT(*)` (senão Coimbra daria 1).
</details>

---

### 2. Quem são os três clientes que mais gastaram?

<details>
<summary>Resposta</summary>

```sql
SELECT   TOP 3 cl.Nome, SUM(c.CustoTotal) AS TotalGasto
FROM     Cliente cl
         INNER JOIN Carregamento c ON c.IDClienteCondutor = cl.IDCliente
WHERE    c.Estado = 'Faturado'
GROUP BY cl.Nome
ORDER BY TotalGasto DESC;
```
`Bruno Costa 62.80 · Diogo Ferreira 37.43 · Ana Silva 32.95`

**Aqui o `INNER` está certo:** só interessam os que gastaram. E o `TOP` **exige**
`ORDER BY` — sem ele, devolve 3 linhas quaisquer.

**Atenção ao nome da coluna:** é `IDClienteCondutor`, não `IDCliente`. Quem
conduziu pode não ser quem paga — o pagador está na `Fatura`.
</details>

---

### 3. Que postos nunca tiveram um carregamento?

<details>
<summary>Resposta</summary>

```sql
SELECT   p.Codigo, p.NomePosto
FROM     Posto p
WHERE    NOT EXISTS (SELECT 1
                     FROM   PostoConector pc
                            INNER JOIN Carregamento c ON c.IDPostoConector = pc.IDPostoConector
                     WHERE  pc.IDPosto = p.IDPosto)
ORDER BY p.Codigo;
```
`P004 — Braga - Parque da Ponte`

É o **anti-join**: "existe aqui e não existe ali". Também se faz com
`LEFT JOIN ... WHERE ... IS NULL`, mas o `NOT EXISTS` lê-se como a pergunta.
</details>

---

### 4. Energia total por tipo de conector

<details>
<summary>Resposta</summary>

```sql
SELECT   tc.Designacao, ISNULL(SUM(c.EnergiaKwh), 0) AS EnergiaTotalKwh
FROM     TipoConector tc
         LEFT JOIN PostoConector pc ON pc.IDTipoConector  = tc.IDTipoConector
         LEFT JOIN Carregamento  c  ON c.IDPostoConector  = pc.IDPostoConector
                                   AND c.Estado IN ('Terminado', 'Faturado')
GROUP BY tc.Designacao
ORDER BY EnergiaTotalKwh DESC;
```
`CCS2 1066.2 · Type 2 367.7 · CHAdeMO 0 · Type 1 0`

**Dois pontos:** o filtro do estado está no **`ON`** (no `WHERE` anulava o
LEFT), e o `ISNULL(...,0)` evita que os que não têm venham a `NULL`.
</details>

---

### 5. Faturas emitidas em julho de 2026

<details>
<summary>Resposta</summary>

```sql
SELECT   f.Numero, cl.Nome AS Pagador, f.DataEmissao
FROM     Fatura f
         INNER JOIN Cliente cl ON cl.IDCliente = f.IDClientePagador
WHERE    f.DataEmissao >= '2026-07-01' AND f.DataEmissao < '2026-08-01'
ORDER BY f.DataEmissao;
```
`FT2026/0014 · FT2026/0015 · FT2026/0019`

**Repara no `>= e <`**, e não `BETWEEN`. Com datas que possam ter hora, o
`BETWEEN '2026-07-01' AND '2026-07-31'` perde tudo o que aconteceu no dia 31
depois da meia-noite. O `>= início AND < início do mês seguinte` nunca falha.
</details>

---

### 6. Clientes sem veículo registado

<details>
<summary>Resposta</summary>

```sql
SELECT   cl.Nome, cl.TipoCliente
FROM     Cliente cl
WHERE    NOT EXISTS (SELECT 1 FROM Veiculo v WHERE v.IDCliente = cl.IDCliente);
```
**Devolve zero linhas** — todos os clientes têm pelo menos um veículo.

Isso não é um erro. Um anti-join sem resultados quer dizer *"não há nenhum"*.
Se ela perguntar se a consulta está bem, apaga um veículo e mostra que aparece.

**O nome da coluna é `TipoCliente`**, não `Tipo`.
</details>

---

### 7. Quanto falta receber, no total?

<details>
<summary>Resposta</summary>

```sql
SELECT   SUM(porFatura.EmFalta) AS TotalPorReceber
FROM     (SELECT f.IDFatura,
                 (SELECT ISNULL(SUM(c.CustoTotal),0) FROM Carregamento c WHERE c.IDFatura = f.IDFatura)
               - (SELECT ISNULL(SUM(pg.Valor),0)     FROM Pagamento   pg WHERE pg.IDFatura = f.IDFatura)
                 AS EmFalta
          FROM   Fatura f) AS porFatura
WHERE    porFatura.EmFalta > 0;
```
`35.12 EUR`

**O ponto a defender:** não existe coluna "em dívida" em lado nenhum, e é de
propósito. Guardá-la era guardar duas vezes o mesmo facto — um valor que teria
de ser atualizado a cada pagamento e que acabaria por divergir. **Calcula-se:
faturado menos recebido.**
</details>

---

### 8. Média de energia por posto, só nos postos ativos

<details>
<summary>Resposta</summary>

```sql
SELECT   p.Codigo,
         COUNT(c.IDCarregamento) AS Sessoes,
         CAST(ISNULL(AVG(c.EnergiaKwh),0) AS DECIMAL(9,2)) AS MediaKwh
FROM     Posto p
         LEFT JOIN PostoConector pc ON pc.IDPosto        = p.IDPosto
         LEFT JOIN Carregamento  c  ON c.IDPostoConector = pc.IDPostoConector
                                   AND c.Estado IN ('Terminado','Faturado')
WHERE    p.Ativo = 1
GROUP BY p.Codigo
HAVING   COUNT(c.IDCarregamento) > 0
ORDER BY MediaKwh DESC;
```
`P007 67.67 · P010 54.87 · P003 54.00 · ...`

**Aqui está o `WHERE` e o `HAVING` na mesma consulta**, e é o melhor exemplo da
diferença:
- `WHERE p.Ativo = 1` filtra **linhas**, antes de agrupar — e está certo no
  `WHERE` porque é sobre a tabela da **esquerda**
- `HAVING COUNT(...) > 0` filtra **grupos**, depois de agrupar — não podia
  estar no `WHERE`, porque nessa altura o `COUNT` ainda não existe
</details>

---

## 5. As cinco armadilhas, resumidas

Se ela te vir a escrever e fizeres alguma destas, ela vai reparar:

| # | Armadilha | A regra |
|---|---|---|
| 1 | filtrar a tabela da direita no `WHERE` | num LEFT JOIN, essa condição vai no **`ON`** |
| 2 | `COUNT(*)` depois de um LEFT JOIN | é sempre `COUNT(coluna_da_direita)` |
| 3 | `TOP` sem `ORDER BY` | devolve N linhas **quaisquer** |
| 4 | comparar com `NULL` usando `=` | só o `IS NULL` funciona |
| 5 | `BETWEEN` em datas com hora | usa `>= início AND < mês seguinte` |

---

## 6. Como praticar

1. Abre o SSMS na base `VoltGo`
2. Tapa as respostas e escreve as oito
3. Depois **inventa cinco tuas** a partir das duas cadeias — por exemplo:
   - "que concelho tem mais avarias?"
   - "quanto rendeu cada tipo de conector?"
   - "que clientes nunca pagaram nada?"
4. Corre-as. Se der erro, lê a mensagem — é assim que se aprende a escrever
   depressa à frente de alguém

> A diferença entre saber explicar e saber escrever é a única coisa que a
> apresentação vai medir que o ficheiro entregue não mede.
