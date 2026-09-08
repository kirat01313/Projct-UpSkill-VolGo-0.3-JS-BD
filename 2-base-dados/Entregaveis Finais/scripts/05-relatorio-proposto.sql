/* ============================================================================
   VoltGo — 05 — Relatório estratégico proposto                       PARTE D
   ----------------------------------------------------------------------------
   "Quanto dinheiro já foi entregue em energia e ainda não foi cobrado,
    de quem, e há quanto tempo?"

   D1 o detalhe, fatura a fatura.   D2 o resumo, por entidade pagadora.
   Justificação em ../../guias/04-parte-D-relatorio-proposto.md
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO


SELECT   fs.Numero                                     AS Fatura,
         cl.Nome                                       AS EntidadePagadora,
         cl.TipoCliente,
         fs.Metodo,
         fs.DataVencimento,
         fs.ValorFaturado,
         fs.ValorRecebido,
         fs.ValorFaturado - fs.ValorRecebido           AS EmFalta,
         CASE WHEN fs.DataVencimento < GETDATE()
              THEN N'Em divida ha ' + CAST(DATEDIFF(DAY, fs.DataVencimento, GETDATE()) AS NVARCHAR(10)) + N' dias'
              ELSE N'Dentro do prazo'
         END                                           AS Situacao,
         CASE WHEN fs.ValorRecebido = 0
              THEN N'Nunca pagou nada'
              ELSE N'Pagou em parte'
         END                                           AS Pagamentos
FROM     (SELECT f.IDFatura,
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
          WHERE  f.Estado <> 'Anulada') AS fs
         INNER JOIN Cliente cl ON cl.IDCliente = fs.IDClientePagador
WHERE    fs.ValorRecebido < fs.ValorFaturado      -- ainda falta receber
ORDER BY fs.DataVencimento;
GO


SELECT   cl.Nome                                          AS EntidadePagadora,
         cl.TipoCliente,
         COUNT(*)                                         AS FaturasEmDivida,
         SUM(fs.ValorFaturado - fs.ValorRecebido)         AS TotalEmDivida,
         MAX(DATEDIFF(DAY, fs.DataVencimento, GETDATE())) AS DiasDaMaisAntiga
FROM     (SELECT f.IDClientePagador,
                 f.DataVencimento,
                 ISNULL((SELECT SUM(c.CustoTotal) FROM Carregamento c
                         WHERE c.IDFatura = f.IDFatura), 0)  AS ValorFaturado,
                 ISNULL((SELECT SUM(pg.Valor) FROM Pagamento pg
                         WHERE pg.IDFatura = f.IDFatura), 0) AS ValorRecebido
          FROM   Fatura f
          WHERE  f.Estado <> 'Anulada') AS fs
         INNER JOIN Cliente cl ON cl.IDCliente = fs.IDClientePagador
WHERE    fs.ValorRecebido < fs.ValorFaturado      -- ainda falta receber
  AND    fs.DataVencimento < GETDATE()            -- e o prazo já passou
GROUP BY cl.Nome, cl.TipoCliente
ORDER BY TotalEmDivida DESC;
GO
