/* ============================================================================
   VoltGo — 04 — Relatórios obrigatórios                              PARTE C
   ----------------------------------------------------------------------------
   Os sete relatórios do ponto 4.3 do enunciado.
   Explicação de cada um em ../../guias/03-parte-C-relatorios.md
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO


-- 1. Carregamentos por tipo de conector
SELECT   tc.Designacao             AS TipoConector,
         COUNT(DISTINCT pc.IDPosto)   AS PostosComEsteTipo,
         COUNT(c.IDCarregamento)      AS NumeroCarregamentos
FROM     TipoConector tc
         LEFT JOIN PostoConector pc ON pc.IDTipoConector  = tc.IDTipoConector
         LEFT JOIN Carregamento  c  ON c.IDPostoConector  = pc.IDPostoConector
GROUP BY tc.Designacao
ORDER BY NumeroCarregamentos DESC, tc.Designacao;
GO


-- 2. Postos e numero de carregamentos terminados
--    "Terminado" e "Faturado" contam os dois: a sessao acabou nos dois casos.
--    O 'Terminado' e um estado de passagem, e o objetivo do relatorio e medir
--    a atividade da rede, nao quantos carregamentos ainda nao foram faturados.
SELECT   p.Codigo,
         p.NomePosto                AS Posto,
         p.PotenciaKw,
         CASE p.Ativo WHEN 1 THEN 'Ativo' ELSE 'Desativado' END AS Situacao,
         COUNT(c.IDCarregamento)    AS CarregamentosTerminados
FROM     Posto p
         LEFT JOIN PostoConector pc ON pc.IDPosto         = p.IDPosto
         LEFT JOIN Carregamento  c  ON c.IDPostoConector  = pc.IDPostoConector
                                   AND c.Estado IN ('Terminado','Faturado')  -- filtro no ON
GROUP BY p.Codigo, p.NomePosto, p.PotenciaKw, p.Ativo
ORDER BY CarregamentosTerminados DESC, p.Codigo;
GO


-- 3. Custo medio por tarifario
SELECT   t.Nome                                    AS Tarifario,
         CASE t.Comercializado WHEN 1 THEN 'Sim' ELSE 'Nao' END AS AindaSeVende,
         t.PrecoKwhAtual                           AS PrecoEmVigor,
         COUNT(c.IDCarregamento)                   AS CarregamentosFaturados,
         CAST(AVG(c.CustoTotal) AS DECIMAL(9,2))   AS CustoMedio,
         CAST(SUM(c.CustoTotal) AS DECIMAL(9,2))   AS CustoTotal
FROM     Tarifario t
         INNER JOIN Carregamento c ON c.IDTarifario = t.IDTarifario
WHERE    c.Estado = 'Faturado'
GROUP BY t.Nome, t.Comercializado, t.PrecoKwhAtual
ORDER BY CustoMedio DESC;
GO


-- 4a) todos, com marcação de quem passa o critério
-- 4a. Clientes e numero de carregamentos (todos)
SELECT   cl.Nome                   AS Cliente,
         cl.TipoCliente,
         COUNT(c.IDCarregamento)   AS NumeroCarregamentos,
         CASE WHEN COUNT(c.IDCarregamento) > 1 THEN 'Sim' ELSE 'Nao' END AS MaisDoQueUm
FROM     Cliente cl
         LEFT JOIN Carregamento c ON c.IDClienteCondutor = cl.IDCliente
GROUP BY cl.Nome, cl.TipoCliente
ORDER BY NumeroCarregamentos DESC, cl.Nome;
GO

-- 4b) só os que têm mais do que um
--     HAVING e não WHERE: a condição é sobre um COUNT, que só existe depois
--     do GROUP BY. O WHERE corre antes de haver contagem nenhuma.
-- 4b. Clientes com mais do que um carregamento
SELECT   cl.Nome                   AS Cliente,
         cl.TipoCliente,
         COUNT(c.IDCarregamento)   AS NumeroCarregamentos
FROM     Cliente cl
         LEFT JOIN Carregamento c ON c.IDClienteCondutor = cl.IDCliente
GROUP BY cl.Nome, cl.TipoCliente
HAVING   COUNT(c.IDCarregamento) > 1
ORDER BY NumeroCarregamentos DESC, cl.Nome;
GO


-- 5. Carregamentos e respetivos pagamentos
SELECT   c.IDCarregamento,
         c.Estado,
         c.DataHoraInicio,
         c.CustoTotal,
         f.Numero                  AS Fatura,
         COUNT(pg.IDPagamento)     AS NumeroPagamentos,
         CASE
             WHEN f.IDFatura IS NULL                      THEN 'Sem fatura'
             WHEN COUNT(pg.IDPagamento) = 0               THEN 'FATURADO E POR COBRAR'
             WHEN SUM(pg.Valor) < c.CustoTotal            THEN 'Pago em parte'
             ELSE                                              'Pago'
         END                       AS Situacao
FROM     Carregamento c
         LEFT JOIN Fatura    f  ON f.IDFatura  = c.IDFatura
         LEFT JOIN Pagamento pg ON pg.IDFatura = f.IDFatura
GROUP BY c.IDCarregamento, c.Estado, c.DataHoraInicio, c.CustoTotal, f.Numero, f.IDFatura
ORDER BY NumeroPagamentos, c.IDCarregamento;
GO


-- 6a) todos os concelhos, incluindo os de valor zero
-- 6a. Concelhos e valor total faturado (todos)
SELECT   co.Nome                                  AS Concelho,
         COUNT(DISTINCT p.IDPosto)                AS Postos,
         COUNT(DISTINCT c.IDCarregamento)         AS Carregamentos,
         COUNT(DISTINCT c.IDFatura)               AS Faturas,
         ISNULL(SUM(CASE WHEN c.IDFatura IS NOT NULL
                         THEN c.CustoTotal END), 0) AS TotalFaturado
FROM     Concelho co
         LEFT JOIN Posto         p  ON p.IDConcelho       = co.IDConcelho
         LEFT JOIN PostoConector pc ON pc.IDPosto         = p.IDPosto
         LEFT JOIN Carregamento  c  ON c.IDPostoConector  = pc.IDPostoConector
GROUP BY co.Nome
ORDER BY TotalFaturado DESC;
GO

-- 6b) só os concelhos acima do limite (decisão nossa: 50 EUR)
-- 6b. Concelhos acima do limite de 20 EUR
SELECT   co.Nome                                  AS Concelho,
         COUNT(DISTINCT p.IDPosto)                AS Postos,
         ISNULL(SUM(CASE WHEN c.IDFatura IS NOT NULL
                         THEN c.CustoTotal END), 0) AS TotalFaturado
FROM     Concelho co
         LEFT JOIN Posto         p  ON p.IDConcelho       = co.IDConcelho
         LEFT JOIN PostoConector pc ON pc.IDPosto         = p.IDPosto
         LEFT JOIN Carregamento  c  ON c.IDPostoConector  = pc.IDPostoConector
GROUP BY co.Nome
HAVING   ISNULL(SUM(CASE WHEN c.IDFatura IS NOT NULL THEN c.CustoTotal END), 0) > 50
ORDER BY TotalFaturado DESC;
GO

-- 6c) o pagamento, ao nível a que ele existe: a fatura
--     Fecha a exigência de "relacionar ... e pagamentos" sem inventar uma
--     atribuição de dinheiro a concelhos que o modelo não suporta.
-- 6c. O pagamento ao nivel a que existe: a fatura
SELECT   f.Numero                          AS Fatura,
         cl.Nome                           AS EntidadePagadora,
         f.Metodo,
         COUNT(DISTINCT c.IDCarregamento)  AS Carregamentos,
         SUM(DISTINCT c.CustoTotal)        AS ValorFaturado,
         ISNULL((SELECT SUM(pg.Valor) FROM Pagamento pg
                 WHERE pg.IDFatura = f.IDFatura), 0) AS ValorRecebido
FROM     Fatura f
         INNER JOIN Cliente     cl ON cl.IDCliente = f.IDClientePagador
         LEFT  JOIN Carregamento c ON c.IDFatura   = f.IDFatura
GROUP BY f.IDFatura, f.Numero, cl.Nome, f.Metodo
ORDER BY f.Numero;
GO


-- 7a) todos os postos
-- 7a. Postos e ocorrencias de manutencao (todos)
SELECT   p.Codigo,
         p.NomePosto                        AS Posto,
         COUNT(o.IDOcorrencia)              AS NumeroOcorrencias,
         ISNULL(SUM(o.CustoIntervencao), 0) AS CustoTotalManutencao,
         CASE WHEN COUNT(o.IDOcorrencia) = 0 THEN 'Sem manutencoes' ELSE '' END AS Nota
FROM     Posto p
         LEFT JOIN Ocorrencia o ON o.IDPosto = p.IDPosto
GROUP BY p.Codigo, p.NomePosto
ORDER BY NumeroOcorrencias DESC, p.Codigo;
GO

-- 7b) os 10 com mais manutenções
--     TOP sem ORDER BY seriam 10 quaisquer: sem ordenação explícita, a ordem
--     das linhas devolvidas não é garantida por nada.
-- 7b. Os 10 postos com mais manutencoes
SELECT   TOP 10
         p.Codigo,
         p.NomePosto                        AS Posto,
         COUNT(o.IDOcorrencia)              AS NumeroOcorrencias,
         ISNULL(SUM(o.CustoIntervencao), 0) AS CustoTotalManutencao
FROM     Posto p
         LEFT JOIN Ocorrencia o ON o.IDPosto = p.IDPosto
GROUP BY p.Codigo, p.NomePosto
ORDER BY NumeroOcorrencias DESC, CustoTotalManutencao DESC;
GO
