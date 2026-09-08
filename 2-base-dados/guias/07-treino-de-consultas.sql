USE VoltGo;
GO
SET NOCOUNT ON;
GO

PRINT '===== 1. Carregamentos por concelho (a cadeia do ONDE, 4 tabelas) =====';
SELECT   co.Nome AS Concelho, COUNT(c.IDCarregamento) AS Carregamentos
FROM     Concelho co
         LEFT JOIN Posto         p  ON p.IDConcelho      = co.IDConcelho
         LEFT JOIN PostoConector pc ON pc.IDPosto        = p.IDPosto
         LEFT JOIN Carregamento  c  ON c.IDPostoConector = pc.IDPostoConector
GROUP BY co.Nome
ORDER BY Carregamentos DESC;
GO

PRINT '===== 2. Cliente que mais gastou =====';
SELECT   TOP 3 cl.Nome, SUM(c.CustoTotal) AS TotalGasto
FROM     Cliente cl
         INNER JOIN Carregamento c ON c.IDClienteCondutor = cl.IDCliente
WHERE    c.Estado = 'Faturado'
GROUP BY cl.Nome
ORDER BY TotalGasto DESC;
GO

PRINT '===== 3. Postos que NUNCA tiveram carregamentos (anti-join) =====';
SELECT   p.Codigo, p.NomePosto
FROM     Posto p
WHERE    NOT EXISTS (SELECT 1
                     FROM   PostoConector pc
                            INNER JOIN Carregamento c ON c.IDPostoConector = pc.IDPostoConector
                     WHERE  pc.IDPosto = p.IDPosto)
ORDER BY p.Codigo;
GO

PRINT '===== 4. Energia total por tipo de conector (a cadeia N:M) =====';
SELECT   tc.Designacao, ISNULL(SUM(c.EnergiaKwh), 0) AS EnergiaTotalKwh
FROM     TipoConector tc
         LEFT JOIN PostoConector pc ON pc.IDTipoConector  = tc.IDTipoConector
         LEFT JOIN Carregamento  c  ON c.IDPostoConector  = pc.IDPostoConector
                                   AND c.Estado IN ('Terminado', 'Faturado')
GROUP BY tc.Designacao
ORDER BY EnergiaTotalKwh DESC;
GO

PRINT '===== 5. Faturas emitidas em julho de 2026 =====';
SELECT   f.Numero, cl.Nome AS Pagador, f.DataEmissao
FROM     Fatura f
         INNER JOIN Cliente cl ON cl.IDCliente = f.IDClientePagador
WHERE    f.DataEmissao >= '2026-07-01' AND f.DataEmissao < '2026-08-01'
ORDER BY f.DataEmissao;
GO

PRINT '===== 6. Clientes sem veiculo registado (anti-join) =====';
SELECT   cl.Nome, cl.TipoCliente
FROM     Cliente cl
WHERE    NOT EXISTS (SELECT 1 FROM Veiculo v WHERE v.IDCliente = cl.IDCliente)
ORDER BY cl.Nome;
GO

PRINT '===== 7. Quanto falta receber, no total (subconsulta) =====';
SELECT   SUM(porFatura.EmFalta) AS TotalPorReceber
FROM     (SELECT f.IDFatura,
                 (SELECT ISNULL(SUM(c.CustoTotal), 0) FROM Carregamento c WHERE c.IDFatura = f.IDFatura)
               - (SELECT ISNULL(SUM(pg.Valor), 0)     FROM Pagamento   pg WHERE pg.IDFatura = f.IDFatura)
                 AS EmFalta
          FROM   Fatura f) AS porFatura
WHERE    porFatura.EmFalta > 0;
GO

PRINT '===== 8. Media de energia por posto, so postos ATIVOS =====';
SELECT   p.Codigo,
         COUNT(c.IDCarregamento) AS Sessoes,
         CAST(ISNULL(AVG(c.EnergiaKwh), 0) AS DECIMAL(9,2)) AS MediaKwh
FROM     Posto p
         LEFT JOIN PostoConector pc ON pc.IDPosto        = p.IDPosto
         LEFT JOIN Carregamento  c  ON c.IDPostoConector = pc.IDPostoConector
                                   AND c.Estado IN ('Terminado', 'Faturado')
WHERE    p.Ativo = 1
GROUP BY p.Codigo
HAVING   COUNT(c.IDCarregamento) > 0
ORDER BY MediaKwh DESC;
GO
