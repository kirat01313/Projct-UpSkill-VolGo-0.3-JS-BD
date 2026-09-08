# Procedimentos, Funções e Triggers

> Guia de estudo. O código está em `Entregaveis Finais/03-procedures-funcoes-triggers.sql`.
> As chamadas de demonstração estão no `07-demonstracao.sql`.

> **Atenção:** isto **não é a Parte B** do enunciado. A Parte B escrita é a
> criação do esquema — o `01-criar-bd.sql`. Procedures, funções e triggers
> foram pedidos **oralmente** pela docente, por cima do PDF.

---

## 1. As três ferramentas

Imagina a base de dados como uma cozinha.

| Ferramenta | O que é | Analogia |
|---|---|---|
| **Procedure** | Passos guardados dentro da base. Chamas pelo nome e executa. | Uma **receita**. |
| **Função** | Recebe valores, calcula e **devolve um resultado**. | Uma **calculadora**. |
| **Trigger** | Dispara **sozinho** quando algo acontece numa tabela. | Um **alarme de fumo**. |

### A diferença que ela vai perguntar

**Procedure vs função:**
- A procedure **faz coisas**. Chama-se com `EXEC`. Não se usa dentro de um `SELECT`.
- A função **devolve um valor** e não altera dados. Usa-se dentro de um `SELECT`, como se fosse uma coluna.

**Trigger vs os outros dois:**
- Procedure e função só correm se **alguém as chamar**.
- O trigger corre **sem ninguém pedir**.

---

## 2. O que fizemos

```
12 PROCEDURES  — CRUD completo em tres tabelas de catalogo
   usp_TipoConector_*   Inserir / Listar / Atualizar / Eliminar
   usp_Concelho_*       Inserir / Listar / Atualizar / Eliminar
   usp_TipoAvaria_*     Inserir / Listar / Atualizar / Eliminar

 1 FUNCAO
   fn_EnergiaTotalPosto   escalar — devolve um numero

 2 TRIGGERS
   TR_Carregamento_Historico          escreve o historico sozinho
   TR_TarifarioPreco_SincronizaAtual  mantem a copia do preco sincronizada
```

---

## 3. As três tabelas são iguais **de propósito**

`TipoConector`, `Concelho` e `TipoAvaria` têm a mesma forma: um id e um nome.

As doze procedures são **o mesmo molde três vezes**, com os nomes trocados.

> **Se ela perguntar porquê:** um catálogo não precisa de mais do que isto. Repetir o padrão mostra que o dominamos; inventar três casos diferentes acrescentava trabalho sem acrescentar ideia nenhuma.

E há um ganho para ti: **estudas um, sabes explicar três.**

---

## 4. Porque o Inserir e o Atualizar são tão curtos

```sql
CREATE PROCEDURE dbo.usp_TipoConector_Inserir
    @Designacao NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO TipoConector (Designacao) VALUES (@Designacao);
END
```

Cinco linhas, **sem validação nenhuma** — e é deliberado.

A coluna `Designacao` já tem `UNIQUE`. É a **tabela** que recusa duplicados. Validar outra vez aqui só trocava a mensagem do SQL Server por uma nossa.

Na demonstração vê-se:

```
Erro apanhado: Violation of UNIQUE KEY constraint 'UQ_TipoConector_Desig'.
```

> **A frase:** *"a proteção está na tabela, não na procedure. Se validássemos aqui, a mesma regra passava a existir em dois sítios — e um dia divergiam."*

---

## 5. O Eliminar é o único com carne

```sql
DECLARE @Tomadas INT =
    (SELECT COUNT(*) FROM PostoConector WHERE IDTipoConector = @IDTipoConector);

IF @Tomadas > 0
BEGIN
    ...THROW com a mensagem
END

DELETE FROM TipoConector WHERE IDTipoConector = @IDTipoConector;
```

### Quem trava não é o nosso código

É a **chave estrangeira**. Se houver uma tomada a apontar para o tipo de conector, o SQL Server recusa o `DELETE`, escrevamos nós o que escrevermos.

A procedure só acrescenta uma mensagem que se percebe:

```
Nao e possivel eliminar: existem 5 tomadas associadas a este tipo de conector.
```

em vez do erro cru sobre `FK_PostoConector_TipoConector`.

### O par que faz o ponto

```
eliminar o "Tesla NACS"  ->  ninguem o usa       ->  apaga
eliminar o "Type 2"      ->  5 tomadas a usa-lo  ->  recusa, com explicacao
```

Uma passa, a outra é travada. **É o contraste que prova que a verificação existe** — mostrar só a que funciona não prova nada.

### E a regra 3.8, que proíbe apagar?

Lê a frase toda:

> *"Dados não devem ser fisicamente removidos **quando perdem validade operacional**."*

A condição está no fim. Um tipo de conector inserido por engano, que nunca foi usado por nada, **nunca teve validade operacional** — apagá-lo é corrigir um erro, não destruir histórico.

---

## 6. A função

```sql
CREATE FUNCTION dbo.fn_EnergiaTotalPosto (@IDPosto INT)
RETURNS DECIMAL(10,3)
AS
BEGIN
    DECLARE @Total DECIMAL(10,3);

    SELECT @Total = SUM(c.EnergiaKwh)
    FROM   Carregamento c
           INNER JOIN PostoConector pc ON pc.IDPostoConector = c.IDPostoConector
    WHERE  pc.IDPosto = @IDPosto;

    RETURN ISNULL(@Total, 0);
END
```

Devolve **um número**: a energia total que aquele posto já entregou.

### A parte que se vê num relance

```sql
SELECT   Codigo,
         NomePosto,
         dbo.fn_EnergiaTotalPosto(IDPosto) AS EnergiaTotalKwh
FROM     Posto;
```

A função aparece **como se fosse uma coluna** da tabela `Posto`. É isto que distingue uma função de uma procedure — e explica-se em cinco segundos.

### O `ISNULL` no fim

Vale nota. Um posto sem carregamentos faz o `SUM` devolver **`NULL`**, não zero.

Sem o `ISNULL`, o P004 — que não tem carregamentos nenhuns — aparecia com a coluna vazia em vez de `0.000`.

> É o mesmo raciocínio do `COUNT(coluna)` nos relatórios: agregar zero linhas dá `NULL`, não `0`.

---

## 7. Os triggers

### 7.1 O de histórico

```sql
CREATE TRIGGER TR_Carregamento_Historico
ON Carregamento
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO CarregamentoHistorico (IDCarregamento, EstadoNovo)
    SELECT i.IDCarregamento, i.Estado
    FROM   inserted i;
END
```

**Três linhas de código.** Sempre que um carregamento nasce ou muda, fica registada uma linha a dizer em que estado ficou.

**Porque vive na base e não na aplicação:** há muitas portas de entrada para a mesma tabela — o serviço que fala com os postos, o processo mensal de faturação, alguém a corrigir um erro à mão. Se fosse a aplicação a escrever, bastava uma esquecer-se para ficarem buracos.

> **A frase:** *"o histórico deixa de depender de quem escreve o código."*

**A limitação assumida:** regista **qualquer** alteração, incluindo as que não mudam o estado. Corrigir o custo também escreve uma linha. Distinguir os dois casos obrigava a comparar `inserted` com `deleted`, com dois `JOIN`. Escolhemos a simplicidade, e a limitação está escrita no código.

### 7.2 O de sincronização

A docente pediu que o preço em vigor aparecesse **também** na tabela `Tarifario`, para as consultas não terem de ir sempre à `TarifarioPreco`.

Isso cria a mesma informação em dois sítios — o que a normalização evita.

```
Alguem mexe na TarifarioPreco
        |
        v
o trigger dispara sozinho
        |
        v
copia o preco da vigencia aberta para o Tarifario
```

> **A frase:** *"a `TarifarioPreco` continua a ser a fonte da verdade. As colunas no `Tarifario` são uma cópia mantida automaticamente. Aceitámos a redundância porque o trigger torna impossível alterar uma e esquecer a outra."*

Se um tarifário ficar sem vigência aberta, a cópia vai a `NULL`. É o caso do Rápido, que está descontinuado — e está correto.

---

## 8. `inserted` e `deleted` — a matéria que cai

Duas tabelas que o SQL Server cria sozinho dentro do trigger:

| Operação | `inserted` | `deleted` |
|---|---|---|
| INSERT | as linhas novas | vazia |
| UPDATE | os valores novos | os valores antigos |
| DELETE | vazia | as linhas apagadas |

**O erro que toda a gente comete:** tratar `inserted` como se fosse **uma linha**.

Não é. É uma **tabela**. Um `UPDATE` que afete 50 carregamentos dispara o trigger **uma vez**, com 50 linhas lá dentro — e não 50 vezes.

Por isso os triggers usam `INSERT ... SELECT`, que trata o conjunto todo de uma vez.

---

## 9. Perguntas prováveis

**"Porque é que as procedures de inserir não validam nada?"**
Porque a tabela já valida. A regra está no `UNIQUE`, num sítio só.

**"Porque é que aqui apagam e no tarifário não?"**
A regra 3.8 proíbe remover dados que *perderam* validade operacional. Um tipo de conector que nada usa nunca a teve.

**"O que é o `inserted`?"**
Uma tabela, não uma linha. Tem as linhas como ficaram depois da operação.

**"E se o trigger falhar?"**
O `UPDATE` inteiro é desfeito. O trigger corre dentro da mesma transação — não existe estado a meio.

**"Não há nenhuma transação no trabalho?"**
Não. Nenhuma operação escreve em duas tabelas ao mesmo tempo — nos catálogos, cada operação toca numa linha só. A transação serve para quando há mais do que uma escrita a ter de acontecer junta.

**"Porque é que a demonstração está noutro ficheiro?"**
Porque um script de criação não devia alterar dados. O `03` cria os objetos; o `07` mostra-os a funcionar.
