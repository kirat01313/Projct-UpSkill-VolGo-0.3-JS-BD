# Parte E — A funcionalidade nova: ALERTA

> Guia de estudo. O código está em `Entregaveis Finais/06-parte-e-alerta.sql`.
> A tabela `Alerta` é criada no `01-criar-bd.sql`, com todas as outras.

---

## 1. O que é, em uma frase

> O sistema deteta carregamentos que registaram **mais energia do que o posto conseguiria ter entregue** no tempo que a sessão durou, e guarda cada deteção como um alerta que alguém tem de analisar.

---

## 2. O que o enunciado pede aqui

Repara bem no ponto 4.5. Ele pede **quatro coisas**:

```
descricao funcional
regras de negocio associadas
impacto esperado no sistema
alteracoes necessarias ao modelo relacional
```

**Não diz "implementar".** O que vale os 10% é a proposta escrita. O código é o extra — e por isso o mantivemos simples.

As quatro estão escritas no cabeçalho do `06-parte-e-alerta.sql`, para irem também no PDF.

---

## 3. A regra

```
energia maxima  =  potencia do posto  x  horas da sessao
```

Se a energia registada for maior do que isto, é impossível.

**Exemplo concreto:**

```
posto de 22 kW, sessao de 1 hora
  maximo:  22 x 1  =  22 kWh

  registou 20 kWh   ->  normal, nada acontece
  registou 45 kWh   ->  impossivel, gera alerta
```

### O detalhe técnico que vale nota

```sql
DATEDIFF(MINUTE, DataHoraInicio, DataHoraFim) / 60.0
                                                 ^^^^
```

Tem de ser **`60.0`** e não `60`. Com um inteiro, o SQL Server faz divisão inteira e 45 minutos davam **zero horas** — a energia máxima dava zero e *tudo* era sinalizado.

É o tipo de pormenor que mostra que testaste.

---

## 4. As regras de negócio

| # | Regra | Porquê |
|---|---|---|
| 1 | Suspeito se `energia > potência × horas` | é a definição do problema |
| 2 | Só sessões **terminadas** | uma sessão a decorrer ainda não tem energia final |
| 3 | O alerta **não impede** o registo | ver a secção 6 |
| 4 | Ciclo de vida: Aberto → Justificado ou Confirmado | alguém tem de decidir |

---

## 5. Porque é uma **tabela** e não só uma consulta

Esta é a pergunta mais provável.

Uma consulta devolve sempre o mesmo resultado e **não guarda nada**. Um alerta precisa de memória: quem o viu e o que decidiu.

Sem tabela, a mesma anomalia voltaria a aparecer todos os dias, já analisada, e ninguém saberia disso.

### E os valores ficam congelados

A tabela guarda a `EnergiaRegistada` e a `EnergiaMaxima` **no momento da deteção**.

Se amanhã alguém corrigir a potência do P001 de 22 para 30 kW, o alerta antigo continua a poder ser explicado. Se recalculasse, passaria a parecer um erro do sistema — quando estava certo **com a informação que existia na altura**.

> **A frase:** *"o alerta é uma fotografia do momento em que a suspeita nasceu, não um cálculo que se refaz."*

---

## 6. Porque não bloqueia

Decisão deliberada:

> Um carregamento acima da capacidade do posto pode ter três causas: contador avariado, erro de registo, ou a potência do posto está desatualizada na base de dados.
>
> Nas três, **a energia foi mesmo entregue a alguém**. Recusar o registo fazia essa sessão desaparecer — e o problema ficava invisível, que é o contrário do que queremos.

Por isso: **regista-se, sinaliza-se, e deixa-se um humano classificar.**

```
Aberto  ->  Justificado    erro de medicao conhecido, arquiva-se
        ->  Confirmado     problema real: o posto vai a inspecao
```

---

## 7. Porque não é um CHECK

Um `CHECK` só consegue ver colunas **da própria linha** que está a ser inserida.

Aqui:
- a **energia** está no `Carregamento`
- a **potência** está no `Posto`

São tabelas diferentes. O `CHECK` não lá chega — é preciso um `JOIN`, e um `CHECK` não faz `JOIN`.

---

## 8. A implementação

Não tem trigger, não tem função, não tem procedure. Só:

```
1  um SELECT           ver os carregamentos impossiveis
2  um INSERT...SELECT  registar na tabela Alerta
3  um SELECT com JOIN  a fila de trabalho
4  dois UPDATE         o ciclo de vida
5  um SELECT com GROUP BY  postos com mais alertas
```

> **Se ela perguntar porque não é automático:** a Fase 1 também corria a pedido. O `analiseService.js` percorria os carregamentos quando alguém o chamava. Isto é o mesmo, escrito em SQL.

O `NOT IN (SELECT IDCarregamento FROM Alerta)` no passo 2 evita registar duas vezes o mesmo carregamento se correres o script outra vez.

---

## 9. A ligação à Fase 1

Evolui a rotina de **auditoria** da aplicação de consola (`analiseService.js`), que percorria os carregamentos à procura de registos incoerentes.

| | Fase 1 | Fase 2 |
|---|---|---|
| Onde corre | em JavaScript, sobre ficheiros JSON | em SQL, sobre a base de dados |
| Memória | nenhuma | o resultado da análise fica guardado |
| Alcance | só o que estivesse nos ficheiros | tudo, e cruza duas tabelas |

> O enunciado pede que a funcionalidade **evolua** o requisito diferenciador da Fase 1, e não que seja uma coisa nova. É isso que esta faz.

---

## 10. O resultado

```
IDAlerta  Carregamento  Posto  Potencia  Registada  Maxima  Excesso
   1          17        P001    22 kW     45,000    22,000   23,000
   2          18        P012    22 kW     30,000    11,000   19,000
```

Os carregamentos 17 e 18 foram postos nos dados de teste **de propósito**: passam por todas as restrições `CHECK` do modelo e mesmo assim descrevem algo impossível.

> **Se ela perguntar porque há dados errados na base:** são a demonstração da funcionalidade. O ponto é precisamente que nenhuma restrição os conseguia travar.

---

## 11. O que mudou no modelo

**Uma tabela nova:** `Alerta`, com 6 colunas.
**Nenhuma tabela existente mudou.**
**Nenhum dos sete relatórios obrigatórios muda de resultado.**

> A funcionalidade **acrescenta, não interfere**. É um bom argumento: mostra que foi desenhada para encaixar no modelo, e não colada por cima.
