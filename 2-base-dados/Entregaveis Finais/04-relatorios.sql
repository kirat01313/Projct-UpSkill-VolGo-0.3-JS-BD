/* ============================================================================
   VoltGo — 04 — Relatórios obrigatórios                            PARTE C
   ============================================================================
   Correr depois do 01, 02 e 03.

   REGRA PARA ESCOLHER A JUNÇÃO
     LEFT JOIN   quando o enunciado diz "listar TODOS" ou "incluir os que
                 não têm" — os sem ligação têm de sobreviver
     INNER JOIN  quando só interessam os registos que têm ligação

   AS DUAS ARMADILHAS QUE ESTRAGAM UM LEFT JOIN

     1. Filtrar a tabela da direita no WHERE ANULA o LEFT JOIN.
        As linhas sem correspondência vêm com NULL, o WHERE deita-as fora, e
        fica-se com um INNER JOIN disfarçado. O filtro pertence ao ON.

     2. COUNT(*) conta a linha vazia do LEFT JOIN e devolve 1 onde devia
        devolver 0. COUNT(coluna) ignora os NULL. É sempre COUNT(coluna).

   NOTA SOBRE A TOMADA
   O Carregamento aponta para PostoConector (a tomada), não para o Posto.
   Para chegar ao posto ou ao tipo de conector é preciso passar por lá — é o
   preço de não repetir o IDPosto em duas tabelas.

   DIVISÃO DO TRABALHO:  Fred → 3, 5, 6   |   Tarik → 1, 2, 4, 7
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO


/* ############################################################################
   1. CARREGAMENTOS POR TIPO DE CONECTOR
   ############################################################################
   "listar todos os tipos de conector existentes; incluir também os tipos sem
    carregamentos; permitir identificar os mais e menos utilizados"

   Dois LEFT JOIN em cadeia. Basta um deles ser INNER para o Type 1 (que não
   existe em posto nenhum) desaparecer — e é justamente ele a prova de que a
   consulta está certa.
   ############################################################################ */

SELECT   tc.Designacao             AS TipoConector,
         COUNT(DISTINCT pc.IDPosto)   AS PostosComEsteTipo,
         COUNT(c.IDCarregamento)      AS NumeroCarregamentos
FROM     TipoConector tc
         LEFT JOIN PostoConector pc ON pc.IDTipoConector  = tc.IDTipoConector
         LEFT JOIN Carregamento  c  ON c.IDPostoConector  = pc.IDPostoConector
GROUP BY tc.Designacao
ORDER BY NumeroCarregamentos DESC, tc.Designacao;
GO


/* ############################################################################
   2. POSTOS E NÚMERO DE CARREGAMENTOS TERMINADOS
   ############################################################################
   "listar todos os postos; nº de carregamentos TERMINADOS; incluir postos sem
    carregamentos; ordenar por número, decrescente"

   O filtro do estado vai no ON e não no WHERE. No WHERE, os postos sem
   carregamentos nenhuns eram apagados do resultado — e o enunciado manda
   incluí-los.
   ############################################################################ */

SELECT   p.Codigo,
         p.NomePosto                AS Posto,
         p.PotenciaKw,
         CASE p.Ativo WHEN 1 THEN 'Ativo' ELSE 'Desativado' END AS Situacao,
         COUNT(c.IDCarregamento)    AS CarregamentosTerminados
FROM     Posto p
         LEFT JOIN PostoConector pc ON pc.IDPosto         = p.IDPosto
         LEFT JOIN Carregamento  c  ON c.IDPostoConector  = pc.IDPostoConector
                                   AND c.Estado          = 'Terminado'   -- filtro no ON
GROUP BY p.Codigo, p.NomePosto, p.PotenciaKw, p.Ativo
ORDER BY CarregamentosTerminados DESC, p.Codigo;
GO


/* ############################################################################
   3. CUSTO MÉDIO POR TARIFÁRIO
   ############################################################################
   "relacionar carregamentos e tarifários; calcular o valor médio do custo por
    tarifário; considerar APENAS carregamentos faturados"

   É o único dos sete que usa INNER JOIN: não pede para incluir os que não têm,
   e a média de um tarifário sem carregamentos faturados não existe — seria
   NULL, não zero.

   Aqui o WHERE está certo justamente porque não há linhas vazias a proteger.
   ############################################################################ */

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


/* ############################################################################
   4. CLIENTES E NÚMERO DE CARREGAMENTOS
   ############################################################################
   "listar todos os clientes; nº de carregamentos; incluir clientes SEM
    carregamentos; identificar clientes com MAIS do que um"

   As duas últimas exigências não cabem na mesma consulta: incluir os que têm
   zero e mostrar só os que têm mais do que um são filtros contrários.
   Por isso são duas — 4a responde à primeira, 4b à segunda.

   A junção é por IDClienteCondutor: quem carregou. Um cliente que só PAGA
   (a TransNorte a pagar pelo Bruno) não conta como tendo carregado.
   ############################################################################ */

-- 4a) todos, com marcação de quem passa o critério
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
SELECT   cl.Nome                   AS Cliente,
         cl.TipoCliente,
         COUNT(c.IDCarregamento)   AS NumeroCarregamentos
FROM     Cliente cl
         LEFT JOIN Carregamento c ON c.IDClienteCondutor = cl.IDCliente
GROUP BY cl.Nome, cl.TipoCliente
HAVING   COUNT(c.IDCarregamento) > 1
ORDER BY NumeroCarregamentos DESC, cl.Nome;
GO


/* ############################################################################
   5. CARREGAMENTOS E RESPETIVOS PAGAMENTOS
   ############################################################################
   "listar todos os carregamentos; nº de pagamentos registados por
    carregamento; incluir carregamentos que ainda não tenham qualquer
    pagamento associado"

   Com a entidade Fatura no meio, o caminho passou a ter três tabelas:
        Carregamento → Fatura → Pagamento

   O LEFT é o ponto do relatório, não uma opção: o objetivo é encontrar os
   carregamentos SEM pagamento.

   Três situações distintas aparecem no resultado:
        sem fatura          → ainda não faturado (terminado, em curso, anulado)
        com fatura, 0 pag.  → faturado e por cobrar   ← é este que interessa
        com fatura, N pag.  → pago (ou pago em parte)
   ############################################################################ */

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


/* ############################################################################
   6. CONCELHOS E VALOR TOTAL FATURADO
   ############################################################################
   "relacionar concelhos, postos, carregamentos e pagamentos; calcular o valor
    total faturado por concelho; incluir concelhos sem valores faturados;
    apresentar apenas concelhos cujo valor ultrapasse um limite"

   Cadeia de cinco tabelas. TODOS os JOIN são LEFT: basta um INNER a meio para
   se perder a linha inteira, e Coimbra (que não tem postos nenhuns) tem de
   chegar ao fim com zero.

   DOIS CUIDADOS
   
   COUNT(DISTINCT ...) — a cadeia repete o posto uma vez por cada tomada e por
   cada carregamento. Sem DISTINCT, um posto com 3 tomadas contava 3 vezes.

   ISNULL(..., 0) — sem ele Coimbra vinha a NULL, e NULL não se compara com o
   limite do HAVING: a linha desaparecia justamente do sítio onde tinha de
   aparecer.

   O QUE É "VALOR FATURADO"
   É o custo dos carregamentos que já têm fatura. Calcula-se pelo carregamento
   e não pelo pagamento, por uma razão de modelação: com a entidade Fatura, o
   pagamento está um nível ACIMA do concelho — uma fatura mensal pode cobrir
   postos de concelhos diferentes, e nesse caso o valor recebido não é
   atribuível a um concelho só. O faturado é; o recebido trata-se ao nível da
   fatura (ver 6c).
   ############################################################################ */

-- 6a) todos os concelhos, incluindo os de valor zero
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


/* ############################################################################
   7. POSTOS E EXISTÊNCIA DE MANUTENÇÕES
   ############################################################################
   "listar todos os postos; nº de ocorrências associadas; incluir postos sem
    qualquer ocorrência; permitir distinguir os 10 postos com maior número"

   Mesma tensão do relatório 4: "incluir os que não têm" e "os 10 com mais" não
   cabem na mesma consulta — num TOP 10 ordenado por número, os zeros são
   sempre os primeiros a ser cortados. 7a lista todos, 7b isola o TOP 10.
   ############################################################################ */

-- 7a) todos os postos
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
