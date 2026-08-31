/* ============================================================
   VoltGo — 03 — Relatórios obrigatórios (Parte C)
   ============================================================
   Correr depois do 01 e do 02.

   Regra de escolha da junção:
     LEFT   quando o enunciado diz "listar TODOS" / "incluir os que não têm"
     INNER  quando só interessam os registos que têm ligação

   Duas armadilhas:
     1. filtrar a tabela da direita no WHERE anula o LEFT JOIN;
        o filtro pertence ao ON
     2. COUNT(*) conta a linha vazia do LEFT JOIN (dá 1);
        COUNT(coluna) ignora os NULL (dá 0) — é este que se usa

   Divisão:  Fred -> 3, 5, 6   |   Tarik -> 1, 2, 4, 7
   ============================================================ */

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
USE VoltGo;
GO


/* ---- 1. Carregamentos por tipo de conector -------------------
   LEFT: "incluir também os tipos sem carregamentos". */

SELECT   tc.Designacao            AS TipoConector,
         COUNT(c.IDCarregamento)  AS NumeroCarregamentos
FROM     TipoConector tc
         LEFT JOIN Carregamento c ON c.IDTipoConector = tc.IDTipoConector
GROUP BY tc.Designacao
ORDER BY NumeroCarregamentos DESC, tc.Designacao;
GO


/* ---- 2. Postos e nº de carregamentos terminados --------------
   O filtro do estado vai no ON. No WHERE, os postos sem
   carregamentos desapareciam. */

SELECT   p.Designacao             AS Posto,
         p.PotenciaKw,
         CASE p.Ativo WHEN 1 THEN 'Ativo' ELSE 'Desativado' END AS Estado,
         COUNT(c.IDCarregamento)  AS CarregamentosTerminados
FROM     Posto p
         LEFT JOIN Carregamento c
              ON  c.IDPosto = p.IDPosto
              AND c.Estado  = 'Terminado'
GROUP BY p.Designacao, p.PotenciaKw, p.Ativo
ORDER BY CarregamentosTerminados DESC, p.Designacao;
GO


/* ---- 3. Custo médio por tarifário ----------------------------
   INNER: é o único que não pede para incluir os que não têm.
   A média de um tarifário sem faturados não existe.
   Aqui o WHERE está certo porque não há linhas vazias a proteger. */

SELECT   t.Nome                                   AS Tarifario,
         CASE t.Comercializado WHEN 1 THEN 'Sim' ELSE 'Nao' END AS AindaSeVende,
         COUNT(c.IDCarregamento)                  AS CarregamentosFaturados,
         CAST(AVG(c.CustoTotal) AS DECIMAL(9,2))  AS CustoMedio,
         CAST(SUM(c.CustoTotal) AS DECIMAL(9,2))  AS CustoTotal
FROM     Tarifario t
         INNER JOIN Carregamento c ON c.IDTarifario = t.IDTarifario
WHERE    c.Estado = 'Faturado'
GROUP BY t.Nome, t.Comercializado
ORDER BY CustoMedio DESC;
GO


/* ---- 4. Clientes e nº de carregamentos -----------------------
   O enunciado pede "incluir clientes sem carregamentos" E
   "identificar os que têm mais do que um" — não cabem na mesma
   consulta. 4a responde à primeira, 4b à segunda. */

-- 4a) todos, com marcação de quem passa o critério
SELECT   cl.Nome                  AS Cliente,
         cl.TipoCliente,
         COUNT(c.IDCarregamento)  AS NumeroCarregamentos,
         CASE WHEN COUNT(c.IDCarregamento) > 1 THEN 'Sim' ELSE 'Nao' END AS MaisDoQueUm
FROM     Cliente cl
         LEFT JOIN Carregamento c ON c.IDCliente = cl.IDCliente
GROUP BY cl.Nome, cl.TipoCliente
ORDER BY NumeroCarregamentos DESC, cl.Nome;
GO

-- 4b) só os que têm mais do que um
--     HAVING e não WHERE: a condição é sobre um COUNT, que só
--     existe depois do GROUP BY
SELECT   cl.Nome                  AS Cliente,
         cl.TipoCliente,
         COUNT(c.IDCarregamento)  AS NumeroCarregamentos
FROM     Cliente cl
         LEFT JOIN Carregamento c ON c.IDCliente = cl.IDCliente
GROUP BY cl.Nome, cl.TipoCliente
HAVING   COUNT(c.IDCarregamento) > 1
ORDER BY NumeroCarregamentos DESC, cl.Nome;
GO


/* ---- 5. Carregamentos e respetivos pagamentos ----------------
   O objetivo é encontrar carregamentos SEM pagamento, por isso
   o LEFT é o ponto do relatório e não uma opção. */

SELECT   c.IDCarregamento,
         c.Estado,
         c.DataHoraInicio,
         c.CustoTotal,
         COUNT(p.IDPagamento)     AS NumeroPagamentos,
         CASE WHEN COUNT(p.IDPagamento) = 0 AND c.Estado = 'Faturado'
              THEN 'FATURADO SEM PAGAMENTO' ELSE '' END AS Alerta
FROM     Carregamento c
         LEFT JOIN Pagamento p ON p.IDCarregamento = c.IDCarregamento
GROUP BY c.IDCarregamento, c.Estado, c.DataHoraInicio, c.CustoTotal
ORDER BY NumeroPagamentos, c.IDCarregamento;
GO


/* ---- 6. Concelhos e valor total faturado ---------------------
   Cadeia de quatro tabelas. Todos os JOIN são LEFT: basta um
   INNER a meio para se perder a linha inteira (Coimbra não tem
   postos e tem de chegar ao fim com 0).

   "Valor faturado" = SUM(Pagamento.Valor). O enunciado manda
   incluir a tabela Pagamento na consulta e prevê concelhos sem
   valor — o que só faz sentido se a origem for o pagamento.

   COUNT(DISTINCT): a cadeia repete o posto uma vez por cada
   carregamento e pagamento.
   ISNULL: sem ele, Coimbra vinha NULL, e NULL não compara com
   o limite do HAVING. */

-- 6a) todos os concelhos, incluindo os de valor zero
SELECT   co.Nome                           AS Concelho,
         COUNT(DISTINCT p.IDPosto)         AS Postos,
         COUNT(DISTINCT c.IDCarregamento)  AS Carregamentos,
         ISNULL(SUM(pg.Valor), 0)          AS TotalFaturado
FROM     Concelho co
         LEFT JOIN Posto        p  ON p.IDConcelho      = co.IDConcelho
         LEFT JOIN Carregamento c  ON c.IDPosto         = p.IDPosto
         LEFT JOIN Pagamento    pg ON pg.IDCarregamento = c.IDCarregamento
GROUP BY co.Nome
ORDER BY TotalFaturado DESC;
GO

-- 6b) só acima do limite (decisão nossa: 20 EUR)
SELECT   co.Nome                     AS Concelho,
         COUNT(DISTINCT p.IDPosto)   AS Postos,
         ISNULL(SUM(pg.Valor), 0)    AS TotalFaturado
FROM     Concelho co
         LEFT JOIN Posto        p  ON p.IDConcelho      = co.IDConcelho
         LEFT JOIN Carregamento c  ON c.IDPosto         = p.IDPosto
         LEFT JOIN Pagamento    pg ON pg.IDCarregamento = c.IDCarregamento
GROUP BY co.Nome
HAVING   ISNULL(SUM(pg.Valor), 0) > 20
ORDER BY TotalFaturado DESC;
GO


/* ---- 7. Postos e existência de manutenções -------------------
   Mesma tensão do 4: "incluir postos sem ocorrência" e "os 10 com
   maior número" não cabem juntos — num TOP 10 os zeros são
   cortados. 7a lista todos, 7b isola o TOP 10. */

-- 7a) todos os postos
SELECT   p.Designacao                       AS Posto,
         COUNT(o.IDOcorrencia)              AS NumeroOcorrencias,
         ISNULL(SUM(o.CustoIntervencao), 0) AS CustoTotalManutencao,
         CASE WHEN COUNT(o.IDOcorrencia) = 0 THEN 'Sem manutencoes' ELSE '' END AS Nota
FROM     Posto p
         LEFT JOIN Ocorrencia o ON o.IDPosto = p.IDPosto
GROUP BY p.Designacao
ORDER BY NumeroOcorrencias DESC, p.Designacao;
GO

-- 7b) os 10 com mais manutenções
--     TOP sem ORDER BY seriam 10 quaisquer: sem ordenação
--     explícita, a ordem das linhas não é garantida
SELECT   TOP 10
         p.Designacao                       AS Posto,
         COUNT(o.IDOcorrencia)              AS NumeroOcorrencias,
         ISNULL(SUM(o.CustoIntervencao), 0) AS CustoTotalManutencao
FROM     Posto p
         LEFT JOIN Ocorrencia o ON o.IDPosto = p.IDPosto
GROUP BY p.Designacao
ORDER BY NumeroOcorrencias DESC, CustoTotalManutencao DESC;
GO
