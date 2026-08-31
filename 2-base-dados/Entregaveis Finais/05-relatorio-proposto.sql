/* ============================================================================
   VoltGo — 05 — Relatório estratégico proposto                      PARTE D
   ============================================================================
   Correr depois do 01, 02 e 03.

   A QUESTÃO
       "Quanto dinheiro já foi entregue em energia e ainda não foi cobrado,
        de quem, e há quanto tempo?"

   PORQUE É ESTRATÉGICA
   A VoltGo entrega o produto primeiro e cobra depois. Nos clientes
   empresariais, com faturação mensal, o intervalo entre entregar e receber
   chega a dois meses. É uma questão de TESOURARIA: a rede pode estar a crescer
   em carregamentos e a ficar sem dinheiro em caixa ao mesmo tempo, e nenhum
   indicador de utilização mostra isso.

   PORQUE NENHUM DOS SETE OBRIGATÓRIOS RESPONDE
       o 3  dá custos médios por tarifário, não olha a cobranças
       o 5  conta pagamentos, mas não olha a prazos nem a valores em falta
       o 6  soma o faturado, sem distinguir o recebido do que está em aberto

   ONDE ESTÁ A INFORMAÇÃO
   A regra 3.6 pede para distinguir faturado, pago e em dívida. Os dois
   primeiros leem-se diretamente; o terceiro é DERIVADO:

       faturado   = a fatura existe
       pago       = a soma dos pagamentos iguala o valor faturado
       em dívida  = a soma dos pagamentos é menor, e o vencimento já passou

   Não há coluna "EmDivida" de propósito: teria de ser reescrita todos os dias
   à meia-noite, porque a dívida nasce apenas pela passagem do tempo.

   LIGAÇÃO À FASE 1
   Vem do relatorioPorCobrar pensado para a aplicação de consola. Lá, os
   ficheiros JSON só sabiam se o carregamento estava terminado ou faturado.
   Aqui há datas de emissão, de vencimento e de pagamento — e pagamentos
   parciais, que a Fase 1 nem conseguia representar.
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO


/* ############################################################################
   D1. DÍVIDA POR ENTIDADE PAGADORA
   ############################################################################
   O valor em falta de cada fatura é o que foi faturado menos o que já entrou.
   Com pagamentos parciais, essa diferença pode não ser zero nem o total.

   INNER JOIN e não LEFT: um cliente sem dívida não tem lugar num relatório de
   dívidas. Pela mesma razão os filtros vão no WHERE — não há linhas vazias a
   proteger.
   ############################################################################ */

WITH FaturaSaldo AS (
    SELECT f.IDFatura,
           f.Numero,
           f.IDClientePagador,
           f.Metodo,
           f.DataVencimento,
           /* o valor faturado é a soma dos carregamentos que a fatura cobre */
           ISNULL((SELECT SUM(c.CustoTotal) FROM Carregamento c
                   WHERE c.IDFatura = f.IDFatura), 0)  AS ValorFaturado,
           ISNULL((SELECT SUM(pg.Valor) FROM Pagamento pg
                   WHERE pg.IDFatura = f.IDFatura), 0) AS ValorRecebido
    FROM   Fatura f
    WHERE  f.Estado <> 'Anulada'
)
SELECT   cl.Nome                                        AS EntidadePagadora,
         cl.TipoCliente,
         COUNT(*)                                       AS FaturasEmDivida,
         SUM(fs.ValorFaturado - fs.ValorRecebido)       AS TotalEmDivida,
         MAX(DATEDIFF(DAY, fs.DataVencimento, GETDATE())) AS DiasDaMaisAntiga,
         MIN(fs.DataVencimento)                         AS VencimentoMaisAntigo
FROM     FaturaSaldo fs
         INNER JOIN Cliente cl ON cl.IDCliente = fs.IDClientePagador
WHERE    fs.ValorRecebido < fs.ValorFaturado      -- ainda falta receber
  AND    fs.DataVencimento < GETDATE()            -- e o prazo já passou
GROUP BY cl.Nome, cl.TipoCliente
ORDER BY TotalEmDivida DESC;
GO


/* ############################################################################
   D2. A MESMA DÍVIDA, POR ANTIGUIDADE
   ############################################################################
   Uma dívida de 30 dias resolve-se com um email; uma de 90 é outro problema e
   trata-se de outra maneira. O CASE constrói o escalão e o GROUP BY agrupa
   por ele — e tem de ser repetido no GROUP BY, porque o alias da coluna ainda
   não existe nessa altura da execução.
   ############################################################################ */

WITH FaturaSaldo AS (
    SELECT f.IDFatura, f.DataVencimento,
           ISNULL((SELECT SUM(c.CustoTotal) FROM Carregamento c WHERE c.IDFatura = f.IDFatura), 0)  AS ValorFaturado,
           ISNULL((SELECT SUM(pg.Valor)     FROM Pagamento   pg WHERE pg.IDFatura = f.IDFatura), 0) AS ValorRecebido
    FROM   Fatura f
    WHERE  f.Estado <> 'Anulada'
)
SELECT   CASE
             WHEN DATEDIFF(DAY, DataVencimento, GETDATE()) <= 30 THEN N'1 - ate 30 dias'
             WHEN DATEDIFF(DAY, DataVencimento, GETDATE()) <= 60 THEN N'2 - 31 a 60 dias'
             WHEN DATEDIFF(DAY, DataVencimento, GETDATE()) <= 90 THEN N'3 - 61 a 90 dias'
             ELSE                                                     N'4 - mais de 90 dias'
         END                                     AS Escalao,
         COUNT(*)                                AS Faturas,
         SUM(ValorFaturado - ValorRecebido)      AS TotalEmDivida
FROM     FaturaSaldo
WHERE    ValorRecebido < ValorFaturado
  AND    DataVencimento < GETDATE()
GROUP BY CASE
             WHEN DATEDIFF(DAY, DataVencimento, GETDATE()) <= 30 THEN N'1 - ate 30 dias'
             WHEN DATEDIFF(DAY, DataVencimento, GETDATE()) <= 60 THEN N'2 - 31 a 60 dias'
             WHEN DATEDIFF(DAY, DataVencimento, GETDATE()) <= 90 THEN N'3 - 61 a 90 dias'
             ELSE                                                     N'4 - mais de 90 dias'
         END
ORDER BY Escalao;
GO


/* ############################################################################
   D3. DETALHE — fatura a fatura
   ############################################################################
   Para a operadora poder agir: a quem telefonar, e por quanto.
   Mostra também as PARCIAIS, que são o caso que a Fase 1 não sabia representar.
   ############################################################################ */

SELECT   f.Numero                                      AS Fatura,
         cl.Nome                                       AS EntidadePagadora,
         f.Metodo,
         f.DataEmissao,
         f.DataVencimento,
         DATEDIFF(DAY, f.DataVencimento, GETDATE())    AS DiasDeAtraso,
         COUNT(DISTINCT c.IDCarregamento)              AS Carregamentos,
         ISNULL(SUM(DISTINCT c.CustoTotal), 0)         AS ValorFaturado,
         ISNULL((SELECT SUM(pg.Valor) FROM Pagamento pg
                 WHERE pg.IDFatura = f.IDFatura), 0)   AS ValorRecebido,
         ISNULL(SUM(DISTINCT c.CustoTotal), 0)
           - ISNULL((SELECT SUM(pg.Valor) FROM Pagamento pg
                     WHERE pg.IDFatura = f.IDFatura), 0) AS EmFalta,
         CASE WHEN (SELECT COUNT(*) FROM Pagamento pg WHERE pg.IDFatura = f.IDFatura) = 0
              THEN N'Nunca pagou nada'
              ELSE N'Pagou em parte'
         END                                           AS Situacao
FROM     Fatura f
         INNER JOIN Cliente     cl ON cl.IDCliente = f.IDClientePagador
         LEFT  JOIN Carregamento c ON c.IDFatura   = f.IDFatura
WHERE    f.Estado <> 'Anulada'
  AND    f.DataVencimento < GETDATE()
GROUP BY f.IDFatura, f.Numero, cl.Nome, f.Metodo, f.DataEmissao, f.DataVencimento
HAVING   ISNULL(SUM(DISTINCT c.CustoTotal), 0)
           > ISNULL((SELECT SUM(pg.Valor) FROM Pagamento pg WHERE pg.IDFatura = f.IDFatura), 0)
ORDER BY DiasDeAtraso DESC;
GO


/* ############################################################################
   D4. CONTROLO — não faz parte do relatório
   ############################################################################
   Faturas por pagar mas ainda DENTRO do prazo. Não são dívida e têm de ficar
   de fora das consultas acima.

   Sem este caso nos dados de teste, uma consulta que se esquecesse da condição
   da data devolvia exatamente o mesmo resultado — e ninguém dava por isso.
   Ter o caso de controlo é o que torna o teste um teste.
   ############################################################################ */

SELECT   f.Numero                                   AS Fatura,
         cl.Nome                                    AS EntidadePagadora,
         f.DataVencimento,
         DATEDIFF(DAY, GETDATE(), f.DataVencimento) AS DiasAteVencer
FROM     Fatura f
         INNER JOIN Cliente cl ON cl.IDCliente = f.IDClientePagador
WHERE    f.Estado <> 'Anulada'
  AND    f.DataVencimento >= GETDATE()
  AND    ISNULL((SELECT SUM(pg.Valor) FROM Pagamento pg WHERE pg.IDFatura = f.IDFatura), 0)
       < ISNULL((SELECT SUM(c.CustoTotal) FROM Carregamento c WHERE c.IDFatura = f.IDFatura), 0)
ORDER BY f.DataVencimento;
GO
