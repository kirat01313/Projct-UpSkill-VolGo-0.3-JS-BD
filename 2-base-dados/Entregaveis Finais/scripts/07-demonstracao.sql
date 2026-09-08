/* ============================================================================
   VoltGo — 07 — Demonstração
   ----------------------------------------------------------------------------
   Mostra os objetos do script 03 a funcionar. Correr depois do 01, 02 e 03.

   Não faz parte do sistema: é a prova de que os triggers, as procedures e a
   função respondem como se espera. Altera dados e repõe-nos a seguir.
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO


-- 1. TRIGGER DE SINCRONIZACAO
--    As copias do preco foram preenchidas sozinhas quando o 03 correu.
--    O Rapido fica a NULL: esta descontinuado e nao tem vigencia aberta.

SELECT Nome, PrecoKwhAtual, TaxaAtivacaoAtual, Comercializado
FROM   Tarifario
ORDER BY IDTarifario;
GO


-- 2. TRIGGER DE HISTORICO
--    Ninguem escreve no historico. Muda-se o estado do carregamento 12 e a
--    linha aparece sozinha.

UPDATE Carregamento SET Estado = 'Anulado' WHERE IDCarregamento = 12;

SELECT IDCarregamento, DataHora, EstadoNovo
FROM   CarregamentoHistorico
WHERE  IDCarregamento = 12
ORDER BY DataHora, IDCarregamentoHistorico;
GO

-- repor o estado. Escreve mais uma linha, e esta correto: houve outra alteracao.
UPDATE Carregamento SET Estado = 'Terminado' WHERE IDCarregamento = 12;
GO


-- 3. CRUD — o R das tres tabelas

EXEC dbo.usp_TipoConector_Listar;
EXEC dbo.usp_Concelho_Listar;
EXEC dbo.usp_TipoAvaria_Listar;
GO


-- 4. CRUD — inserir, alterar e eliminar um tipo de conector novo
--    Ninguem o usa, por isso o DELETE passa.

EXEC dbo.usp_TipoConector_Inserir @Designacao = N'Tesla NACS';
SELECT IDTipoConector, Designacao FROM TipoConector WHERE Designacao = N'Tesla NACS';
GO

DECLARE @ID INT = (SELECT IDTipoConector FROM TipoConector WHERE Designacao = N'Tesla NACS');
EXEC dbo.usp_TipoConector_Atualizar @IDTipoConector = @ID, @Designacao = N'NACS';
EXEC dbo.usp_TipoConector_Eliminar  @IDTipoConector = @ID;
GO


-- 5. CRUD — a eliminacao que TEM de ser travada
--    O Type 2 tem tomadas a apontar para ele. Quem recusa e a chave estrangeira;
--    a procedure so traduz o erro para uma frase que se percebe.
--    O TRY/CATCH e preciso: sem ele o script parava aqui.

BEGIN TRY
    EXEC dbo.usp_TipoConector_Eliminar @IDTipoConector = 1;
END TRY
BEGIN CATCH
    PRINT N'Travado: ' + ERROR_MESSAGE();
END CATCH
GO


-- 6. A restricao UNIQUE a trabalhar
--    A procedure de inserir nao valida nada. Quem recusa o duplicado e a tabela.

BEGIN TRY
    EXEC dbo.usp_TipoConector_Inserir @Designacao = N'CCS2';
END TRY
BEGIN CATCH
    PRINT N'Erro apanhado: ' + ERROR_MESSAGE();
END CATCH
GO


-- 7. FUNCAO DE ESTATISTICA
--    Repara: a funcao aparece como se fosse uma coluna da tabela Posto.
--    E isso que distingue uma funcao de um procedimento.

SELECT   Codigo,
         NomePosto,
         PotenciaKw,
         dbo.fn_EnergiaTotalPosto(IDPosto) AS EnergiaTotalKwh
FROM     Posto
ORDER BY EnergiaTotalKwh DESC, Codigo;
GO
