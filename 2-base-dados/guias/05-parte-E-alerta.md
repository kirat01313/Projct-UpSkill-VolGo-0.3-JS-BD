# Parte E — A funcionalidade nova: ALERTA

> Guia de estudo. O código está em `Entregaveis Finais/06-parte-e-alerta.sql`.
> A tabela `Alerta` é criada no script `01-criar-bd.sql`, com todas as outras.

---

## 1. O que é, em uma frase

> O sistema deteta sozinho carregamentos que registaram **mais energia do que o posto conseguiria ter entregue** no tempo que a sessão durou, e guarda cada deteção como um alerta que alguém tem de analisar.

---

## 2. Como se descobriu o problema

Não foi inventado. Saiu de um resultado da Parte B.

A função `fn_EstatisticasPosto` calcula a potência média realmente entregue por cada posto. Ao correr:

```
P001   potência do posto: 22,00 kW   |   potência média entregue: 25,00 kW
P012   potência do posto: 22,00 kW   |   potência média entregue: 27,20 kW
```

Um posto de 22 kW não consegue entregar 25 kW. É **fisicamente impossível**.

E, no entanto, a base de dados aceitou estes registos sem se queixar — porque nenhuma regra de integridade os proibia.

> **Este é um bom ponto de partida para a defesa:** a funcionalidade nasceu de uma anomalia real encontrada nos próprios dados, não de uma ideia abstrata.

---

## 3. A regra

```
energia máxima  =  potência do posto  ×  horas da sessão  ×  1,10
```

Se a energia registada for maior do que isto, é suspeita.

**Porquê a margem de 10%?** Porque o contador arredonda e os minutos arredondam. Uma sessão registada como "1 hora" pode ter durado 63 minutos. Sem margem, o sistema geraria alertas por erros de arredondamento — e um alerta que dispara sempre deixa de ser lido.

**Exemplo concreto:**

```
posto de 22 kW, sessão de 1 hora
  máximo aceite:  22 × 1 × 1,10  =  24,2 kWh

  registou 20 kWh   ->  normal, nada acontece
  registou 45 kWh   ->  impossível, gera alerta
```

---

## 4. As cinco regras de negócio

| # | Regra | Porquê |
|---|---|---|
| 1 | Suspeito se `energia > potência × horas` | é a definição do problema |
| 2 | Margem de 10% | arredondamento do contador e dos minutos |
| 3 | Só sessões **terminadas** | uma sessão a decorrer ainda não tem energia final |
| 4 | O alerta **não bloqueia** o registo | ver a secção 6 |
| 5 | Não duplicar alertas abertos no mesmo carregamento | senão cada correção de custo criava um alerta novo |

---

## 5. Porque é uma **tabela** e não uma consulta

Esta é a pergunta mais provável da professora.

Uma consulta devolve sempre o mesmo resultado e **não guarda nada**. Um alerta precisa de memória:

- quem o viu
- o que decidiu
- porquê

Sem tabela, a mesma anomalia voltaria a aparecer todos os dias, já analisada, e ninguém saberia disso.

### E há uma segunda razão: os valores ficam congelados

A tabela `Alerta` guarda a `EnergiaRegistada` e a `EnergiaMaxima` **no momento da deteção**.

Porquê? Imagina que amanhã alguém corrige a potência do P001 de 22 kW para 30 kW, porque estava mal registada. Se o alerta recalculasse, o alerta antigo passaria a parecer um erro do sistema — quando na verdade estava certo **com a informação que existia na altura**.

> **A frase:** "O alerta é uma fotografia do momento em que a suspeita nasceu, não um cálculo que se refaz."

---

## 6. Porque é que o alerta **não bloqueia**

Esta foi uma decisão deliberada, e vale a pena defendê-la assim:

> **Trigger que bloqueia** serve para o que está **sempre** errado.
> **Trigger que regista** serve para o que é apenas **estranho**.

Um carregamento acima da capacidade do posto pode ter três causas:
1. contador avariado
2. erro de registo
3. a potência do posto está desatualizada na base de dados

Nas três, a energia **foi mesmo entregue a alguém**. Recusar o registo faria com que essa sessão simplesmente **desaparecesse** — e o problema ficava invisível, que é exatamente o contrário do que queremos.

Por isso: **regista-se, sinaliza-se, e deixa-se um humano classificar.**

### O ciclo de vida do alerta

```
Aberto  ->  Justificado    (erro de medição conhecido, arquiva-se)
        ->  Confirmado     (problema real: o posto vai a inspeção)
```

---

## 7. Porque não é um CHECK

Um `CHECK` só consegue ver colunas **da própria linha** que está a ser inserida.

Aqui:
- a **energia** está no `Carregamento`
- a **potência** está no `Posto`

São tabelas diferentes. O `CHECK` não lá chega. Só um **trigger** consegue, porque o trigger pode fazer `JOIN`.

> Esta limitação já estava documentada no dicionário de dados da versão anterior. A Parte E fecha-a.

---

## 8. A ligação à Fase 1

Evolui a função de **auditoria** da aplicação de consola (`analiseService.js`), que percorria os carregamentos à procura de registos incoerentes.

| | Fase 1 | Fase 2 |
|---|---|---|
| Quando corre | quando alguém se lembra | no instante do registo |
| O que analisa | só o que está nos ficheiros nesse momento | tudo, sempre |
| Memória | nenhuma | guarda a análise humana |

> A professora pediu que a funcionalidade **evoluísse** o requisito diferenciador da Fase 1, e não que fosse uma coisa nova. É isso que esta tabela faz.

---

## 9. Impacto esperado (o que dizer sobre a utilidade)

- Um posto com alertas repetidos torna-se **candidato a inspeção antes de avariar**. Hoje, só se sabe que um posto tem problema quando alguém abre uma ocorrência — ou seja, quando já avariou.
- Impede que se fature energia que não foi entregue.
- Dá à operação uma **fila de trabalho concreta**, em vez de um relatório que alguém tem de se lembrar de correr.

---

## 10. A demonstração (já executada, com resultados)

O script faz quatro coisas, por esta ordem:

**1. Varrimento inicial** — analisa os carregamentos que já existiam.
```
apanhou os carregamentos 36 e 37
  36 -> 45 kWh em 1 hora num posto de 22 kW
  37 -> 30 kWh em 30 minutos num posto de 22 kW
```
Estes dois foram postos nos dados de teste **de propósito**: passam por todas as restrições `CHECK` existentes e mesmo assim são impossíveis.

**2. Um carregamento novo, impossível** — 90 kWh num posto de 22 kW.
```
alertas antes: 2   ->   alertas depois: 3
```
O trigger apanhou-o sozinho, no momento do INSERT.

**3. Um carregamento novo, plausível** — 20 kWh.
```
nenhum alerta gerado
```
Este é o **caso de controlo**: prova que o trigger não dispara a torto e a direito.

**4. Ciclo de vida** — um alerta é classificado como `Justificado`, outro como `Confirmado`.

---

## 11. O que mudou no modelo por causa desta funcionalidade

**Uma tabela nova:** `Alerta`.
**Nenhuma tabela existente mudou.**
**Nenhum dos sete relatórios obrigatórios muda de resultado.**

> A funcionalidade **acrescenta**, não interfere. Isto é um bom argumento: mostra que foi desenhada para encaixar no modelo, e não colada por cima.
