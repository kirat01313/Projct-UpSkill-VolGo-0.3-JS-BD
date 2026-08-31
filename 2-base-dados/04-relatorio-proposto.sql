/* ============================================================
   VoltGo — 04 — Relatório estratégico proposto (Parte D)
   ============================================================
   Autor: Fred

   QUESTÃO
     "Quanto dinheiro está entregue e por cobrar, de quem,
      e há quanto tempo?"

   PORQUÊ
     A VoltGo entrega energia primeiro e cobra depois; nos clientes
     empresariais (pagamento mensal) o intervalo é longo. É uma
     questão de tesouraria: a rede pode crescer em carregamentos e
     ficar sem liquidez ao mesmo tempo.

     Nenhum dos sete obrigatórios responde: o 3 dá custos médios,
     o 5 conta pagamentos sem olhar a prazos, o 6 soma o faturado
     sem distinguir o recebido do que está em aberto.

   ONDE ESTÁ A INFORMAÇÃO
     A regra 3.6 pede para distinguir faturado, pago e em dívida.
     Os dois primeiros leem-se; o terceiro é derivado:
         pago       = DataPagamento preenchida
         em dívida  = DataPagamento NULL E DataVencimento passada
     Não há coluna "EmDivida" — teria de ser atualizada todos os
     dias, porque a dívida nasce só pela passagem do tempo.

   LIGAÇÃO À FASE 1
     Vem do "por cobrar" pensado para a consola. Lá os ficheiros
     JSON só sabiam se o carregamento estava terminado ou faturado;
     aqui há datas de emissão, vencimento e pagamento.
   ============================================================ */

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
USE VoltGo;
GO


/* ---- Dívida por entidade pagadora ----------------------------
   INNER e não LEFT: um cliente sem dívida não tem lugar num
   relatório de dívidas. Pela mesma razão o filtro vai no WHERE —
   não há linhas vazias a proteger.

   A junção é por IDClientePagador: quem tem de pagar é quem está
   na fatura, que nos casos empresariais não é quem conduziu. */

SELECT   cl.Nome                                          AS EntidadePagadora,
         cl.TipoCliente,
         COUNT(pg.IDPagamento)                            AS FaturasEmDivida,
         SUM(pg.Valor)                                    AS TotalEmDivida,
         MAX(DATEDIFF(DAY, pg.DataVencimento, GETDATE())) AS DiasDaMaisAntiga,
         MIN(pg.DataVencimento)                           AS VencimentoMaisAntigo
FROM     Pagamento pg
         INNER JOIN Cliente cl ON cl.IDCliente = pg.IDClientePagador
WHERE    pg.DataPagamento IS NULL
  AND    pg.DataVencimento < GETDATE()
GROUP BY cl.Nome, cl.TipoCliente
ORDER BY TotalEmDivida DESC;
GO


/* ---- A mesma dívida, por antiguidade -------------------------
   Uma dívida de 30 dias trata-se com um email; uma de 90 é outro
   problema. O CASE constrói o escalão e o GROUP BY agrupa por ele. */

SELECT   CASE
             WHEN DATEDIFF(DAY, pg.DataVencimento, GETDATE()) <= 30 THEN N'1 - ate 30 dias'
             WHEN DATEDIFF(DAY, pg.DataVencimento, GETDATE()) <= 60 THEN N'2 - 31 a 60 dias'
             WHEN DATEDIFF(DAY, pg.DataVencimento, GETDATE()) <= 90 THEN N'3 - 61 a 90 dias'
             ELSE                                                       N'4 - mais de 90 dias'
         END                    AS Escalao,
         COUNT(pg.IDPagamento)  AS Faturas,
         SUM(pg.Valor)          AS Total
FROM     Pagamento pg
WHERE    pg.DataPagamento IS NULL
  AND    pg.DataVencimento < GETDATE()
GROUP BY CASE
             WHEN DATEDIFF(DAY, pg.DataVencimento, GETDATE()) <= 30 THEN N'1 - ate 30 dias'
             WHEN DATEDIFF(DAY, pg.DataVencimento, GETDATE()) <= 60 THEN N'2 - 31 a 60 dias'
             WHEN DATEDIFF(DAY, pg.DataVencimento, GETDATE()) <= 90 THEN N'3 - 61 a 90 dias'
             ELSE                                                       N'4 - mais de 90 dias'
         END
ORDER BY Escalao;
GO


/* ---- Controlo (não faz parte do relatório) -------------------
   Pagamentos por pagar mas ainda DENTRO do prazo: não são dívida
   e têm de ficar de fora das consultas acima. Sem este caso nos
   dados, um filtro que se esquecesse da condição da data devolvia
   o mesmo resultado e ninguém dava por isso. */

SELECT   cl.Nome              AS EntidadePagadora,
         pg.Valor,
         pg.DataVencimento,
         DATEDIFF(DAY, GETDATE(), pg.DataVencimento) AS DiasAteVencer
FROM     Pagamento pg
         INNER JOIN Cliente cl ON cl.IDCliente = pg.IDClientePagador
WHERE    pg.DataPagamento IS NULL
  AND    pg.DataVencimento >= GETDATE()
ORDER BY pg.DataVencimento;
GO
