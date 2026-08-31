# As quatro alterações pedidas pela professora

> Ler este guia primeiro. Explica o que mudou desde a versão que foi mostrada na aula e porquê.

---

## Resumo

| # | Alteração | Estado |
|---|---|---|
| 1 | Nova entidade **Fatura**, com pagamentos totais ou parciais | feito |
| 2 | Retirar o **IDPosto** do Carregamento (redundante) | feito |
| 3 | Preço e taxa de ativação **também** no Tarifário, com trigger a sincronizar | feito |
| 4 | Nova funcionalidade **Alerta** | feito |

---

## 1. A entidade Fatura

### Como era antes

O `Pagamento` apontava diretamente ao `Carregamento`.

```
Carregamento  <---  Pagamento
```

Isto funcionava, mas tinha um limite: **não havia forma de agrupar vários carregamentos num documento só**. Um cliente empresarial com 10 carregamentos no mês recebia... 10 cobranças separadas. Não é assim que funciona no mundo real.

### Como é agora

```
Carregamento  --->  Fatura  <---  Pagamento
```

Lê-se assim:
- **muitos carregamentos** entram numa fatura
- **uma fatura** pode receber **vários pagamentos**

### O que isto passa a permitir

```
FT2026/0007   TransNorte Lda   ->  agrupa 4 carregamentos   =  46,80 EUR
                                    pagamento 1 (15/07)     =  31,20 EUR
                                    pagamento 2 (não houve)
                                    ------------------------------------
                                    em falta                =  15,60 EUR
```

Um pagamento **parcial**. A versão anterior não conseguia representar isto de todo.

### O detalhe técnico

O `Carregamento` ganhou a coluna `IDFatura`, que fica a `NULL` enquanto o carregamento não estiver faturado.

E há uma restrição a proteger a coerência:

> Se o estado do carregamento diz **'Faturado'**, então tem obrigatoriamente de haver fatura. E se não diz, não pode haver.

Sem isto, era possível ter um carregamento a dizer que está faturado sem fatura nenhuma — a base de dados a contradizer-se a si própria.

---

## 2. Retirar o IDPosto do Carregamento

### O que a professora viu

O `Carregamento` guardava **duas** coisas ao mesmo tempo:

```
IDPosto          -> em que posto foi
IDPostoConector  -> em que tomada foi
```

Mas a tomada **já sabe** a que posto pertence. Portanto o `IDPosto` era informação repetida.

### Porque é que repetir é mau

Porque a base de dados podia começar a dizer duas coisas diferentes sobre o mesmo carregamento:

```
IDPosto = 5          "foi no posto 5"
IDPostoConector = 12  ->  e a tomada 12 pertence ao posto 7
```

Qual delas está certa? Não há maneira de saber. Isto chama-se **anomalia de atualização** e é precisamente o que a normalização existe para evitar.

### O que mudou na prática

A coluna `IDPosto` desapareceu do `Carregamento`. Agora, para chegar ao posto, passa-se pela tomada:

```
Carregamento  ->  PostoConector  ->  Posto
```

Todas as consultas da Parte C foram reescritas para fazer este caminho.

### A limitação que assumimos (é preciso dizê-lo)

Havia uma coisa que o `IDPosto` garantia de graça: que o carregamento acontecia **no posto que tinha sido reservado**. Isso fazia-se com uma chave estrangeira composta.

Sem a coluna, essa garantia perde-se. Continua a ser possível verificar por consulta ou por trigger, mas já não é a estrutura da tabela que a impõe.

> **Como dizer isto:** "É o preço de não repetir informação. Escolhemos evitar a redundância, e assumimos a verificação como regra de aplicação em vez de regra estrutural."
> Está documentado no diagrama, na caixa "Limitações assumidas".

---

## 3. O preço atual dentro do Tarifário

### O pedido

Ter `PrecoKwhAtual` e `TaxaAtivacaoAtual` na tabela `Tarifario`, para não ser preciso ir sempre à `TarifarioPreco`.

### A tensão que isto cria

É o **contrário** da alteração número 2. Aqui estamos a **criar** redundância de propósito, depois de a termos acabado de eliminar noutro sítio.

Isto não é uma incoerência — mas convém saber explicar a diferença:

| | Alteração 2 (IDPosto) | Alteração 3 (preço) |
|---|---|---|
| Ganho | nenhum, era só repetição | consultas muito mais simples |
| Risco | alguém mexe num e esquece o outro | o mesmo |
| Protegido por | nada — por isso saiu | **um trigger** — por isso pode ficar |

### O trigger

```
Alguém insere ou altera uma linha na TarifarioPreco
                    |
                    v
     TR_TarifarioPreco_SincronizaAtual dispara sozinho
                    |
                    v
     Procura a vigência aberta (a que tem DataFim a NULL)
                    |
                    v
     Copia o preço e a taxa para a tabela Tarifario
```

Se não houver vigência aberta, a cópia fica a `NULL` — o que é correto: não há preço em vigor.

### A frase para a professora

> "A `TarifarioPreco` continua a ser a **fonte da verdade** e mantém-se como histórico. As duas colunas novas no `Tarifario` são uma **cópia mantida automaticamente**. Aceitámos a redundância porque o trigger torna impossível alterar uma e esquecer a outra."

### Prova de que funciona

Depois de correr o script, sem ninguém escrever nada à mão:

```
Normal        0,2800
Verde         0,2200
Empresarial   0,2000
Rápido        NULL     <-- tarifário descontinuado, sem vigência aberta
```

---

## 4. A funcionalidade Alerta

Tem guia próprio: **`05-parte-E-alerta.md`**.

Em duas linhas: regista automaticamente carregamentos que declararam mais energia do que o posto conseguiria entregar. Não bloqueia — regista e deixa um humano classificar.

---

## Onde ver tudo isto

| O quê | Onde |
|---|---|
| Diagrama atualizado | `Entregaveis Finais/VoltGo-ModeloRelacional.drawio` (e `.png`) |
| Dicionário atualizado | `Entregaveis Finais/VoltGo-DicionarioDados.xlsx`, folha **Alterações** |
| Tabela Fatura e Alerta | `Entregaveis Finais/01-criar-bd.sql` |
| Trigger de sincronização | `Entregaveis Finais/03-procedures-funcoes-triggers.sql` |
| Trigger de alerta | `Entregaveis Finais/06-parte-e-alerta.sql` |
