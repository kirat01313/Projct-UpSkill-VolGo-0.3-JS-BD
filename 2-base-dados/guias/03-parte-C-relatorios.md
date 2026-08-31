# Parte C — Os 7 relatórios obrigatórios

> Guia de estudo. O código está em `Entregaveis Finais/04-relatorios.sql`, comentado linha a linha.
> **Divisão do trabalho:** Fred → 3, 5, 6 · Tarik → 1, 2, 4, 7

---

## 1. A regra que decide tudo: LEFT ou INNER?

Esta é a única decisão que se repete nos sete relatórios. Vale a pena percebê-la a sério.

Imagina duas listas: **postos** e **avarias**.

```
POSTOS                    AVARIAS
  P001  Braga Centro        avaria no P001
  P002  Barcelos            avaria no P001
  P003  Fafe                avaria no P002
```

**INNER JOIN** → só aparecem os postos que têm avaria.
Resultado: P001, P002. O **P003 desaparece**.

**LEFT JOIN** → aparecem todos os postos. Os que não têm avaria vêm com a parte da direita vazia.
Resultado: P001, P002, **P003 com zero**.

### Como decidir, sem pensar muito

| O enunciado diz... | Usa |
|---|---|
| "listar **todos**" | LEFT JOIN |
| "incluir os que **não têm**" | LEFT JOIN |
| "incluir mesmo que **zero**" | LEFT JOIN |
| só interessam os que **têm** ligação | INNER JOIN |

Nos sete relatórios do enunciado, quase todos pedem "incluir os que não têm". Por isso quase tudo é LEFT.

---

## 2. As duas armadilhas que estragam um LEFT JOIN

Estas duas coisas são a diferença entre ter o relatório certo e ter um relatório que **parece** certo.

### Armadilha 1 — o filtro no sítio errado

```
LEFT JOIN Ocorrencia o ON o.IDPosto = p.IDPosto
WHERE o.Estado = 'Aberta'          <-- ERRADO
```

O que acontece: o LEFT JOIN traz o P003 com tudo a `NULL`. Depois o `WHERE` pergunta *"o estado é 'Aberta'?"*. `NULL` não é `'Aberta'`, e a linha é deitada fora.

**Resultado:** fizeste um LEFT JOIN e recebeste um INNER JOIN. O P003 desapareceu na mesma.

**A correção:** o filtro vai para o `ON`.

```
LEFT JOIN Ocorrencia o ON o.IDPosto = p.IDPosto AND o.Estado = 'Aberta'
```

> **A regra:** `ON` decide **o que se liga**. `WHERE` decide **que linhas sobrevivem**.
> Num LEFT JOIN, condições sobre a tabela da direita pertencem quase sempre ao `ON`.

### Armadilha 2 — `COUNT(*)` mente

```
COUNT(*)              -->  o P003 dá 1     (ERRADO)
COUNT(o.IDOcorrencia) -->  o P003 dá 0     (CERTO)
```

Porquê? O `COUNT(*)` conta **linhas**. O P003 tem uma linha, ainda que vazia — logo conta 1.
O `COUNT(coluna)` conta **valores que não são NULL**. Como a coluna do P003 está a NULL, conta 0.

> **Regra prática:** depois de um LEFT JOIN, nunca `COUNT(*)`. Sempre `COUNT(coluna_da_tabela_da_direita)`.

---

## 3. Os sete relatórios, um a um

### 1 — Carregamentos por tipo de conector
Todos os tipos de conector, mesmo os que ninguém usou.
**Ponto a defender:** o CHAdeMO aparece com zero. Se aparecesse com 1, o `COUNT` estava errado.

### 2 — Postos e nº de carregamentos terminados
Todos os postos, mesmo os que nunca foram usados.
**Ponto a defender:** o filtro `Estado = 'Terminado'` está no `ON`, não no `WHERE`. É a armadilha 1 aplicada.

### 3 — Custo médio por tarifário
Usa `AVG`. É aqui que aparece o `HAVING`.
**Ponto a defender:** a diferença entre `WHERE` e `HAVING`.

```
WHERE   filtra LINHAS      antes de agrupar
HAVING  filtra GRUPOS      depois de agrupar
```
Não se pode escrever `WHERE AVG(...) > 5`, porque na altura do `WHERE` a média ainda não existe.

### 4 — Clientes e nº de carregamentos
**Ponto interessante:** o enunciado pede duas coisas que não cabem na mesma consulta — *"incluir clientes sem carregamentos"* e *"os que têm mais"*. Num ranking ordenado por quantidade, os zeros são sempre os primeiros a ser cortados.
Por isso está dividido em **4a** (todos) e **4b** (o ranking).

> Isto não é um defeito. É reconhecer que são duas perguntas diferentes.

### 5 — Carregamentos e respetivos pagamentos
Mostra carregamentos que ainda não foram pagos.
**Ponto a defender:** desde que existe a `Fatura`, o pagamento já não está colado ao carregamento. O caminho agora é:

```
Carregamento  ->  Fatura  ->  Pagamento
```

### 6 — Concelhos e valor total faturado
O mais difícil dos sete: uma cadeia de **cinco tabelas**, todas em LEFT.

```
Concelho -> Posto -> PostoConector -> Carregamento -> (Fatura)
```

**Três pontos a defender:**

1. **Todos os JOIN têm de ser LEFT.** Basta um INNER a meio da cadeia para Coimbra (que não tem postos nenhuns) desaparecer. E o enunciado pede explicitamente que ela apareça, com zero.

2. **`COUNT(DISTINCT ...)`.** A cadeia multiplica as linhas: um posto com 3 tomadas aparece 3 vezes. Sem `DISTINCT`, esse posto era contado 3 vezes.

3. **`ISNULL(..., 0)`.** Sem isto, Coimbra vem a `NULL`. E `NULL > 50` não dá nem verdadeiro nem falso — dá desconhecido. A linha era eliminada pelo `HAVING` exatamente no sítio onde tinha de aparecer.

**A pergunta difícil que a professora pode fazer aqui:**
> *"Onde está o pagamento? O enunciado pede pagamentos."*

Resposta: com a entidade `Fatura`, o pagamento passou a estar **um nível acima do concelho**. Uma fatura mensal pode cobrir postos de Braga e de Barcelos ao mesmo tempo. Nesse caso, o dinheiro recebido **não é atribuível a um concelho só** sem inventar uma regra de repartição.

Por isso:
- o **faturado** é por concelho (6a e 6b), porque cada carregamento sabe onde aconteceu;
- o **recebido** é por fatura (6c), que é o nível onde ele existe de verdade.

> Isto é uma decisão de modelação, não uma fuga à pergunta. Vale a pena dizer assim.

### 7 — Postos e existência de manutenções
Mesma tensão do relatório 4: 7a lista todos, 7b isola o TOP 10.
**Ponto a defender:** `TOP 10` sem `ORDER BY` devolve 10 linhas quaisquer. A ordem das linhas não é garantida por nada em SQL a menos que a peças.

---

## 4. Os dados de teste foram feitos para partir consultas erradas

Isto é importante e é um bom argumento na defesa.

Os dados em `02-dados-teste.sql` têm **órfãos de propósito**:

| Órfão | Serve para testar |
|---|---|
| Coimbra — concelho sem postos | relatório 6 |
| CHAdeMO — tipo de conector nunca usado | relatório 1 |
| P013 — posto sem carregamentos | relatório 2 |
| clientes sem carregamentos | relatório 4 |
| postos sem ocorrências | relatório 7 |
| fatura por pagar mas **ainda dentro do prazo** | relatório D4 |

Se as consultas estivessem erradas, **nada disto apareceria** — e o resultado continuaria a parecer bonito.

> **A frase:** "Os dados de teste não são só para encher a base. São para que uma consulta errada dê um resultado visivelmente diferente da certa."

---

## 5. Checklist do que o enunciado exige tecnicamente

| Exigência | Onde aparece |
|---|---|
| `INNER JOIN` | 3, 5, 6c |
| `LEFT JOIN` | 1, 2, 4, 6, 7 |
| `COUNT` | todos |
| `SUM` | 3, 6, 7 |
| `AVG` | 3 |
| `GROUP BY` | todos |
| `HAVING` | 3, 6b |
| Subconsulta | 5, 6c |
| `TOP` | 4b, 7b |
