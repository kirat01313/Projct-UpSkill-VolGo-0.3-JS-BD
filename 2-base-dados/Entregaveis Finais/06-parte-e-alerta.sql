/* ============================================================================
   VoltGo — 06 — Nova funcionalidade: ALERTA                         PARTE E
   ============================================================================
   Correr depois do 01, 02 e 03.

   ============================================================================
   DESCRIÇÃO FUNCIONAL
   ============================================================================
   O sistema passa a detetar e registar automaticamente os carregamentos cuja
   energia medida é impossível para o posto onde foram feitos — mais energia do
   que o equipamento consegue debitar no tempo que a sessão durou.

   Cada deteção gera um ALERTA, com ciclo de vida próprio: alguém o analisa e
   classifica-o como justificado (erro de medição conhecido) ou confirmado
   (problema real no posto ou no registo).

   ============================================================================
   REGRAS DE NEGÓCIO ASSOCIADAS
   ============================================================================
   1. Um carregamento é suspeito se:      EnergiaKwh > PotenciaKw x horas
   2. Admite-se uma margem de 10% para arredondamento do contador e dos
      minutos. Uma sessão registada como "1 hora" pode ter durado 63 minutos.
   3. Só se avaliam sessões terminadas: uma sessão em curso ainda não tem
      energia final.
   4. O alerta NÃO bloqueia o registo. Regista-se e sinaliza-se.
   5. Um alerta aberto no mesmo carregamento não é duplicado.

   ============================================================================
   PORQUE É UMA TABELA E NÃO UMA CONSULTA
   ============================================================================
   Uma consulta devolve sempre o mesmo e não guarda nada. Um alerta precisa de
   memória: quem o viu, o que decidiu, e porquê. Sem tabela, a mesma anomalia
   voltava a aparecer todos os dias, já analisada, e ninguém sabia disso.

   Os valores são CONGELADOS no momento da deteção. Se a potência do posto for
   corrigida mais tarde, o alerta antigo continua a poder ser explicado — caso
   contrário passaria a parecer um erro do sistema.

   ============================================================================
   PORQUE NÃO É UM CHECK
   ============================================================================
   A energia está no Carregamento e a potência está no Posto. Um CHECK só
   consegue ver colunas da própria linha que está a ser inserida. Esta regra
   cruza duas tabelas — só um trigger a alcança.

   Era esta a "limitação assumida" documentada no dicionário. Fecha-se aqui.

   ============================================================================
   CONTINUIDADE COM A FASE 1
   ============================================================================
   Evolui a função de AUDITORIA da aplicação de consola (analiseService.js),
   que percorria os carregamentos à procura de registos incoerentes.

   O que muda:
     Fase 1   um ciclo em JavaScript, corrido a pedido, sem memória.
              Só apanhava o que estivesse nos ficheiros no momento.
     Fase 2   a deteção acontece no instante do registo, sem ninguém a pedir,
              e o resultado da análise humana fica guardado.

   ============================================================================
   IMPACTO ESPERADO
   ============================================================================
   · Um posto com alertas repetidos é candidato a inspeção antes de avariar —
     hoje só se sabe que um posto tem problema quando alguém abre ocorrência.
   · Impede faturação de energia que não foi entregue.
   · Dá à operação uma fila de trabalho concreta, em vez de um relatório que
     alguém tem de se lembrar de correr.

   ============================================================================
   ALTERAÇÕES AO MODELO RELACIONAL
   ============================================================================
   Uma tabela nova: Alerta (já criada no script 01).
   Nenhuma tabela existente muda. Nenhum dos sete relatórios obrigatórios muda
   de resultado. A funcionalidade acrescenta, não interfere.
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO

DROP TRIGGER  IF EXISTS TR_Carregamento_Alerta;
DROP FUNCTION IF EXISTS dbo.fn_EnergiaMaxima;
GO


/* ############################################################################
   1. A FUNÇÃO QUE DEFINE A REGRA
   ############################################################################
   Energia máxima que um posto consegue debitar entre dois instantes.

   Fica numa função e não repetida em três sítios: assim a margem de 10% está
   escrita UMA vez. No dia em que mudar, muda aqui e muda em todo o lado.
   ############################################################################ */

CREATE FUNCTION dbo.fn_EnergiaMaxima
    (@PotenciaKw DECIMAL(6,2), @Inicio DATETIME2(0), @Fim DATETIME2(0))
RETURNS DECIMAL(8,3)
AS
BEGIN
    DECLARE @Margem DECIMAL(4,2) = 1.10;   -- 10% para arredondamentos de medição

    RETURN CAST(@PotenciaKw
                * (DATEDIFF(SECOND, @Inicio, @Fim) / 3600.0)
                * @Margem AS DECIMAL(8,3));
END
GO


/* ############################################################################
   2. O TRIGGER QUE DETETA
   ############################################################################
   Dispara a cada INSERT ou UPDATE no Carregamento. Escrito em conjunto
   (INSERT...SELECT) e não linha a linha: um UPDATE em massa dispara o trigger
   uma vez só, com todas as linhas dentro do 'inserted'.
   ############################################################################ */

CREATE TRIGGER TR_Carregamento_Alerta
ON Carregamento
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Alerta (IDCarregamento, TipoAlerta, EnergiaRegistada, EnergiaMaxima, Observacao)
    SELECT i.IDCarregamento,
           N'EnergiaAcimaCapacidade',
           i.EnergiaKwh,
           dbo.fn_EnergiaMaxima(p.PotenciaKw, i.DataHoraInicio, i.DataHoraFim),
           N'Detetado automaticamente no registo da sessão'
    FROM   inserted i
           INNER JOIN PostoConector pc ON pc.IDPostoConector = i.IDPostoConector
           INNER JOIN Posto         p  ON p.IDPosto          = pc.IDPosto
    WHERE  i.DataHoraFim IS NOT NULL             -- regra 3: só sessões terminadas
      AND  i.EnergiaKwh  IS NOT NULL
      AND  i.EnergiaKwh > dbo.fn_EnergiaMaxima(p.PotenciaKw, i.DataHoraInicio, i.DataHoraFim)
      /* regra 5: não duplicar um alerta que já esteja aberto para o mesmo
         carregamento. Sem isto, cada correção de custo gerava um alerta novo. */
      AND  NOT EXISTS (SELECT 1 FROM Alerta a
                       WHERE a.IDCarregamento = i.IDCarregamento
                         AND a.TipoAlerta     = N'EnergiaAcimaCapacidade'
                         AND a.Estado         = N'Aberto');
END
GO


/* ############################################################################
   3. VARREDURA INICIAL
   ############################################################################
   Os dados do script 02 entraram antes de o trigger existir. Esta varredura
   aplica a regra ao que já lá está — é o equivalente a correr a auditoria da
   Fase 1 uma última vez, antes de a deteção passar a ser automática.
   ############################################################################ */

INSERT INTO Alerta (IDCarregamento, TipoAlerta, EnergiaRegistada, EnergiaMaxima, Observacao)
SELECT c.IDCarregamento,
       N'EnergiaAcimaCapacidade',
       c.EnergiaKwh,
       dbo.fn_EnergiaMaxima(p.PotenciaKw, c.DataHoraInicio, c.DataHoraFim),
       N'Varredura inicial sobre dados anteriores ao trigger'
FROM   Carregamento c
       INNER JOIN PostoConector pc ON pc.IDPostoConector = c.IDPostoConector
       INNER JOIN Posto         p  ON p.IDPosto          = pc.IDPosto
WHERE  c.DataHoraFim IS NOT NULL
  AND  c.EnergiaKwh  IS NOT NULL
  AND  c.EnergiaKwh > dbo.fn_EnergiaMaxima(p.PotenciaKw, c.DataHoraInicio, c.DataHoraFim)
  AND  NOT EXISTS (SELECT 1 FROM Alerta a WHERE a.IDCarregamento = c.IDCarregamento);
GO


/* ############################################################################
   4. O QUE A VARREDURA APANHOU
   ############################################################################
   Estes registos passaram por TODAS as restrições do modelo — datas coerentes,
   energia positiva, tomada válida, tarifário existente. E mesmo assim estão
   fisicamente errados.

   É a demonstração de que a funcionalidade se justifica: sem ela, estes
   valores eram faturados ao cliente.
   ############################################################################ */

SELECT   a.IDAlerta,
         a.IDCarregamento,
         p.Codigo                                              AS Posto,
         p.PotenciaKw,
         DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim)     AS DuracaoMin,
         a.EnergiaRegistada,
         a.EnergiaMaxima,
         CAST(a.EnergiaRegistada - a.EnergiaMaxima AS DECIMAL(8,3)) AS Excesso,
         CAST(a.EnergiaRegistada
              / NULLIF(DATEDIFF(SECOND, c.DataHoraInicio, c.DataHoraFim)/3600.0, 0)
              AS DECIMAL(8,2))                                 AS PotenciaImplicitaKw,
         a.Estado
FROM     Alerta a
         INNER JOIN Carregamento  c  ON c.IDCarregamento    = a.IDCarregamento
         INNER JOIN PostoConector pc ON pc.IDPostoConector  = c.IDPostoConector
         INNER JOIN Posto         p  ON p.IDPosto           = pc.IDPosto
ORDER BY Excesso DESC;
GO


/* ############################################################################
   5. O TRIGGER A FUNCIONAR EM TEMPO REAL
   ############################################################################ */

PRINT N'--- Alertas antes ---';
SELECT COUNT(*) AS Alertas FROM Alerta;
GO

PRINT N'--- Registar um carregamento impossível: 90 kWh num posto de 22 kW em 1 hora ---';
INSERT INTO Carregamento
      (IDPostoConector, IDClienteCondutor, IDVeiculo, IDTarifario, DataHoraInicio, DataHoraFim, EnergiaKwh, CustoTotal, Estado)
SELECT TOP 1 pc.IDPostoConector, 1, 1, 1, '2026-08-30 09:00', '2026-08-30 10:00', 90.000, 25.20, N'Terminado'
FROM   PostoConector pc
       INNER JOIN Posto p ON p.IDPosto = pc.IDPosto
WHERE  p.Codigo = 'P001';
GO

PRINT N'--- Alertas depois (ninguém escreveu na tabela Alerta) ---';
SELECT COUNT(*) AS Alertas FROM Alerta;
GO

PRINT N'--- Registar um carregamento plausível: 20 kWh no mesmo posto ---';
INSERT INTO Carregamento
      (IDPostoConector, IDClienteCondutor, IDVeiculo, IDTarifario, DataHoraInicio, DataHoraFim, EnergiaKwh, CustoTotal, Estado)
SELECT TOP 1 pc.IDPostoConector, 1, 1, 1, '2026-08-30 14:00', '2026-08-30 15:00', 20.000, 5.60, N'Terminado'
FROM   PostoConector pc
       INNER JOIN Posto p ON p.IDPosto = pc.IDPosto
WHERE  p.Codigo = 'P001';
GO

PRINT N'--- Continua igual: o plausível não gera alerta ---';
SELECT COUNT(*) AS Alertas FROM Alerta;
GO


/* ############################################################################
   6. CICLO DE VIDA DO ALERTA
   ############################################################################
   É isto que uma consulta não conseguiria fazer: guardar o que foi decidido.
   ############################################################################ */

PRINT N'--- Analisar dois alertas: um justificado, um confirmado ---';

UPDATE Alerta
SET    Estado = N'Justificado',
       Observacao = N'Contador do posto recalibrado em 2026-08-28; leitura anterior inflacionada.'
WHERE  IDAlerta = (SELECT MIN(IDAlerta) FROM Alerta);

UPDATE Alerta
SET    Estado = N'Confirmado',
       Observacao = N'Erro real de registo. Carregamento a corrigir e a não faturar.'
WHERE  IDAlerta = (SELECT MAX(IDAlerta) FROM Alerta);
GO

SELECT   Estado, COUNT(*) AS Quantos
FROM     Alerta
GROUP BY Estado
ORDER BY Estado;
GO


/* ############################################################################
   7. FILA DE TRABALHO DA OPERAÇÃO
   ############################################################################
   Alertas por analisar, do maior excesso para o menor. É o ecrã que a equipa
   de manutenção abriria de manhã.
   ############################################################################ */

SELECT   a.IDAlerta,
         p.Codigo                       AS Posto,
         p.NomePosto,
         c.DataHoraInicio,
         a.EnergiaRegistada,
         a.EnergiaMaxima,
         CAST(a.EnergiaRegistada - a.EnergiaMaxima AS DECIMAL(8,3)) AS Excesso
FROM     Alerta a
         INNER JOIN Carregamento  c  ON c.IDCarregamento   = a.IDCarregamento
         INNER JOIN PostoConector pc ON pc.IDPostoConector = c.IDPostoConector
         INNER JOIN Posto         p  ON p.IDPosto          = pc.IDPosto
WHERE    a.Estado = N'Aberto'
ORDER BY Excesso DESC;
GO


/* ############################################################################
   8. POSTOS COM ALERTAS REPETIDOS — o valor a médio prazo
   ############################################################################
   Um posto que gera alertas com frequência tem provavelmente um contador
   avariado. Hoje, só se saberia disso quando alguém abrisse uma ocorrência.

   LEFT JOIN a partir do Posto: mostra também os que nunca deram problemas, que
   é a informação de contraste.
   ############################################################################ */

SELECT   p.Codigo,
         p.NomePosto,
         p.PotenciaKw,
         COUNT(a.IDAlerta)                              AS TotalAlertas,
         SUM(CASE WHEN a.Estado = N'Confirmado' THEN 1 ELSE 0 END) AS Confirmados,
         (SELECT COUNT(*) FROM Ocorrencia o WHERE o.IDPosto = p.IDPosto) AS OcorrenciasAbertasOuFechadas
FROM     Posto p
         LEFT JOIN PostoConector pc ON pc.IDPosto        = p.IDPosto
         LEFT JOIN Carregamento  c  ON c.IDPostoConector = pc.IDPostoConector
         LEFT JOIN Alerta        a  ON a.IDCarregamento  = c.IDCarregamento
GROUP BY p.IDPosto, p.Codigo, p.NomePosto, p.PotenciaKw
HAVING   COUNT(a.IDAlerta) > 0
ORDER BY TotalAlertas DESC;
GO


/* ============================================================================
   LIMPAR A DEMONSTRAÇÃO (opcional)
   Remove os dois carregamentos criados no ponto 5 e os alertas deles.
   ============================================================================

   DELETE FROM Alerta WHERE IDCarregamento IN
       (SELECT IDCarregamento FROM Carregamento WHERE DataHoraInicio >= '2026-08-30');
   DELETE FROM CarregamentoHistorico WHERE IDCarregamento IN
       (SELECT IDCarregamento FROM Carregamento WHERE DataHoraInicio >= '2026-08-30');
   DELETE FROM Carregamento WHERE DataHoraInicio >= '2026-08-30';
   GO
   ============================================================================ */
