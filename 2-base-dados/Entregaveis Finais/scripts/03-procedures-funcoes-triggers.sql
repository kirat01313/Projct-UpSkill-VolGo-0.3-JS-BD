/* ============================================================================
   VoltGo — 03 — Procedimentos, funções e triggers          REQUISITO ORAL
   ----------------------------------------------------------------------------
   Correr depois do 01 e do 02, e antes dos relatórios.
   CRUD em três tabelas de catálogo, uma função de estatística, dois triggers.
   A demonstração de tudo isto está no 07-demonstracao.sql
   Explicação em ../../guias/02-procedures-funcoes-triggers.md
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO

/* Limpeza, para o script poder ser corrido as vezes que forem precisas. */
DROP TRIGGER   IF EXISTS TR_Carregamento_Historico;
DROP TRIGGER   IF EXISTS TR_TarifarioPreco_SincronizaAtual;
DROP PROCEDURE IF EXISTS dbo.usp_TipoConector_Inserir;
DROP PROCEDURE IF EXISTS dbo.usp_TipoConector_Listar;
DROP PROCEDURE IF EXISTS dbo.usp_TipoConector_Atualizar;
DROP PROCEDURE IF EXISTS dbo.usp_TipoConector_Eliminar;
DROP PROCEDURE IF EXISTS dbo.usp_Concelho_Inserir;
DROP PROCEDURE IF EXISTS dbo.usp_Concelho_Listar;
DROP PROCEDURE IF EXISTS dbo.usp_Concelho_Atualizar;
DROP PROCEDURE IF EXISTS dbo.usp_Concelho_Eliminar;
DROP PROCEDURE IF EXISTS dbo.usp_TipoAvaria_Inserir;
DROP PROCEDURE IF EXISTS dbo.usp_TipoAvaria_Listar;
DROP PROCEDURE IF EXISTS dbo.usp_TipoAvaria_Atualizar;
DROP PROCEDURE IF EXISTS dbo.usp_TipoAvaria_Eliminar;
DROP FUNCTION  IF EXISTS dbo.fn_EnergiaTotalPosto;
GO


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
GO


CREATE TRIGGER TR_TarifarioPreco_SincronizaAtual
ON TarifarioPreco
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Tarifario
    SET    PrecoKwhAtual = (SELECT TOP 1 tp.PrecoKwh
                            FROM   TarifarioPreco tp
                            WHERE  tp.IDTarifario = Tarifario.IDTarifario
                              AND  tp.DataFim IS NULL),      -- a vigência em vigor
           TaxaAtivacaoAtual = (SELECT TOP 1 tp.TaxaAtivacao
                                FROM   TarifarioPreco tp
                                WHERE  tp.IDTarifario = Tarifario.IDTarifario
                                  AND  tp.DataFim IS NULL)
    WHERE  IDTarifario IN (SELECT IDTarifario FROM inserted)
       OR  IDTarifario IN (SELECT IDTarifario FROM deleted);
END
GO

UPDATE TarifarioPreco SET IDTarifario = IDTarifario;
GO


/* ############################ TIPO DE CONECTOR ############################ */


CREATE PROCEDURE dbo.usp_TipoConector_Inserir
    @Designacao NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO TipoConector (Designacao) VALUES (@Designacao);
END
GO


CREATE PROCEDURE dbo.usp_TipoConector_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT   tc.IDTipoConector,
             tc.Designacao,
             COUNT(pc.IDPostoConector)  AS TomadasAssociadas
    FROM     TipoConector tc
             LEFT JOIN PostoConector pc ON pc.IDTipoConector = tc.IDTipoConector
    GROUP BY tc.IDTipoConector, tc.Designacao
    ORDER BY tc.Designacao;
END
GO


/* U — UPDATE */
CREATE PROCEDURE dbo.usp_TipoConector_Atualizar
    @IDTipoConector INT,
    @Designacao     NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE TipoConector
    SET    Designacao = @Designacao
    WHERE  IDTipoConector = @IDTipoConector;
END
GO


/* D — DELETE, com verificação */
CREATE PROCEDURE dbo.usp_TipoConector_Eliminar
    @IDTipoConector INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Tomadas INT =
        (SELECT COUNT(*) FROM PostoConector WHERE IDTipoConector = @IDTipoConector);

    IF @Tomadas > 0
    BEGIN
        DECLARE @Msg NVARCHAR(300) =
            N'Nao e possivel eliminar: existem ' + CAST(@Tomadas AS NVARCHAR(10))
            + N' tomadas associadas a este tipo de conector.';
        THROW 50101, @Msg, 1;
    END

    DELETE FROM TipoConector WHERE IDTipoConector = @IDTipoConector;
END
GO


/* ################################ CONCELHO ################################ */

CREATE PROCEDURE dbo.usp_Concelho_Inserir
    @Nome NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Concelho (Nome) VALUES (@Nome);
END
GO


CREATE PROCEDURE dbo.usp_Concelho_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT   co.IDConcelho,
             co.Nome,
             COUNT(p.IDPosto)  AS PostosInstalados
    FROM     Concelho co
             LEFT JOIN Posto p ON p.IDConcelho = co.IDConcelho
    GROUP BY co.IDConcelho, co.Nome
    ORDER BY co.Nome;
END
GO


CREATE PROCEDURE dbo.usp_Concelho_Atualizar
    @IDConcelho INT,
    @Nome       NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Concelho
    SET    Nome = @Nome
    WHERE  IDConcelho = @IDConcelho;
END
GO


CREATE PROCEDURE dbo.usp_Concelho_Eliminar
    @IDConcelho INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Postos INT =
        (SELECT COUNT(*) FROM Posto WHERE IDConcelho = @IDConcelho);

    IF @Postos > 0
    BEGIN
        DECLARE @Msg NVARCHAR(300) =
            N'Nao e possivel eliminar: existem ' + CAST(@Postos AS NVARCHAR(10))
            + N' postos instalados neste concelho.';
        THROW 50102, @Msg, 1;
    END

    DELETE FROM Concelho WHERE IDConcelho = @IDConcelho;
END
GO


/* ############################# TIPO DE AVARIA ############################# */

CREATE PROCEDURE dbo.usp_TipoAvaria_Inserir
    @Designacao NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO TipoAvaria (Designacao) VALUES (@Designacao);
END
GO


CREATE PROCEDURE dbo.usp_TipoAvaria_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT   ta.IDTipoAvaria,
             ta.Designacao,
             COUNT(o.IDOcorrencia)  AS OcorrenciasRegistadas
    FROM     TipoAvaria ta
             LEFT JOIN Ocorrencia o ON o.IDTipoAvaria = ta.IDTipoAvaria
    GROUP BY ta.IDTipoAvaria, ta.Designacao
    ORDER BY ta.Designacao;
END
GO


CREATE PROCEDURE dbo.usp_TipoAvaria_Atualizar
    @IDTipoAvaria INT,
    @Designacao   NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE TipoAvaria
    SET    Designacao = @Designacao
    WHERE  IDTipoAvaria = @IDTipoAvaria;
END
GO


CREATE PROCEDURE dbo.usp_TipoAvaria_Eliminar
    @IDTipoAvaria INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ocorrencias INT =
        (SELECT COUNT(*) FROM Ocorrencia WHERE IDTipoAvaria = @IDTipoAvaria);

    IF @Ocorrencias > 0
    BEGIN
        DECLARE @Msg NVARCHAR(300) =
            N'Nao e possivel eliminar: existem ' + CAST(@Ocorrencias AS NVARCHAR(10))
            + N' ocorrencias deste tipo de avaria.';
        THROW 50103, @Msg, 1;
    END

    DELETE FROM TipoAvaria WHERE IDTipoAvaria = @IDTipoAvaria;
END
GO


CREATE FUNCTION dbo.fn_EnergiaTotalPosto (@IDPosto INT)
RETURNS DECIMAL(10,3)
AS
BEGIN
    DECLARE @Total DECIMAL(10,3);

    SELECT @Total = SUM(c.EnergiaKwh)
    FROM   Carregamento c
           INNER JOIN PostoConector pc ON pc.IDPostoConector = c.IDPostoConector
    WHERE  pc.IDPosto = @IDPosto;

    -- um posto sem carregamentos faz o SUM devolver NULL, nao zero
    RETURN ISNULL(@Total, 0);
END
GO

