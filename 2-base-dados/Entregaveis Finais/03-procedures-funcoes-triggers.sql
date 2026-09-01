/* ============================================================================
   VoltGo — 03 — Procedimentos, funções e triggers
   ============================================================================
   Correr depois do 01 e do 02, e ANTES dos relatórios: o trigger de
   sincronização preenche o preço em vigor de cada tarifário, que o
   relatório 3 mostra.

   NOTA: este script responde a um pedido feito em aula, para aplicar os
   conceitos dados. Não corresponde a nenhuma das partes A–E do enunciado
   (a Parte B é o esquema, no script 01).

   ----------------------------------------------------------------------------
   OS TRÊS OBJETOS, E A DIFERENÇA ENTRE ELES
     Trigger      REAGE sozinho a uma alteração. Ninguém o chama.
     Procedure    FAZ coisas. Chama-se com EXEC. Pode alterar dados.
     Função       RESPONDE a uma pergunta. Usa-se dentro de um SELECT.
                  Nunca altera dados.

   ----------------------------------------------------------------------------
   AS TRÊS CONVENÇÕES USADAS EM TODO O SCRIPT

   1. Erros com THROW <numero>, N'<mensagem>', 1
      Numeração por tabela, para se saber de onde veio o erro:
          501xx  TipoConector      502xx  Concelho      503xx  Tarifario

   2. SET XACT_ABORT ON nas procedures que abrem transação.
      Quer dizer: "se alguma coisa correr mal, desfaz tudo automaticamente".
      Poupa o bloco TRY/CATCH inteiro.

   3. Validar antes de agir, e sair logo (THROW interrompe a procedure).
      O corpo principal fica só com o trabalho, sem IFs encaixados.
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO

/* Limpeza, para o script poder ser corrido as vezes que forem precisas.
   As funções saem por último: a de tabela não depende da escalar, mas manter
   a ordem inversa da criação evita surpresas. */
DROP TRIGGER   IF EXISTS TR_Carregamento_Historico;
DROP TRIGGER   IF EXISTS TR_Ocorrencia_Historico;
DROP TRIGGER   IF EXISTS TR_TarifarioPreco_SincronizaAtual;
DROP PROCEDURE IF EXISTS dbo.usp_TipoConector_Inserir;
DROP PROCEDURE IF EXISTS dbo.usp_TipoConector_Listar;
DROP PROCEDURE IF EXISTS dbo.usp_TipoConector_Atualizar;
DROP PROCEDURE IF EXISTS dbo.usp_TipoConector_Eliminar;
DROP PROCEDURE IF EXISTS dbo.usp_Concelho_Inserir;
DROP PROCEDURE IF EXISTS dbo.usp_Concelho_Listar;
DROP PROCEDURE IF EXISTS dbo.usp_Concelho_Atualizar;
DROP PROCEDURE IF EXISTS dbo.usp_Concelho_Eliminar;
DROP PROCEDURE IF EXISTS dbo.usp_Tarifario_Inserir;
DROP PROCEDURE IF EXISTS dbo.usp_Tarifario_Listar;
DROP PROCEDURE IF EXISTS dbo.usp_Tarifario_Atualizar;
DROP PROCEDURE IF EXISTS dbo.usp_Tarifario_Descontinuar;
DROP FUNCTION  IF EXISTS dbo.fn_EstatisticasPosto;
DROP FUNCTION  IF EXISTS dbo.fn_PrecoEmVigor;
GO


/* ############################################################################
   PARTE 1 — TRIGGERS
   ############################################################################

   O QUE É PRECISO SABER ANTES DE LER

   Quando um trigger dispara, o SQL Server cria duas tabelas temporárias:

        inserted   →  como as linhas ficaram DEPOIS
        deleted    →  como as linhas estavam ANTES

   É a combinação delas que diz que operação aconteceu:

        só no inserted   →  INSERT   (não havia "antes")
        nas duas         →  UPDATE
        só no deleted    →  DELETE   (não há "depois")

   E a armadilha número um: SÃO TABELAS, NÃO SÃO LINHAS.
   Um UPDATE que mexa em 50 linhas dispara o trigger UMA vez, com 50 linhas
   lá dentro. Por isso aqui não há ciclos nem variáveis — só INSERT...SELECT
   e UPDATE...FROM, que tratam o conjunto todo de uma vez.
   ############################################################################ */


/* ----------------------------------------------------------------------------
   TR_Carregamento_Historico
   Regra 3.5: "alterações relevantes devem ser registadas para consulta futura"

   Sem o trigger, o histórico dependia de alguém se lembrar de o escrever.
   Basta uma distração e passa a mentir.
   ---------------------------------------------------------------------------- */
CREATE TRIGGER TR_Carregamento_Historico
ON Carregamento
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* REGISTOS NOVOS: estão no inserted e não existiam antes.
       EstadoAnterior fica NULL — não havia estado nenhum antes disto. */
    INSERT INTO CarregamentoHistorico
           (IDCarregamento, DataHora, EstadoAnterior, EstadoNovo, Observacao)
    SELECT i.IDCarregamento, SYSDATETIME(), NULL, i.Estado, N'Registo criado'
    FROM   inserted i
    WHERE  NOT EXISTS (SELECT 1 FROM deleted d
                       WHERE d.IDCarregamento = i.IDCarregamento);

    /* MUDANÇAS DE ESTADO: existiam antes, e o estado mudou mesmo.
       O <> é o filtro que interessa: um UPDATE que só corrija o custo não é
       uma mudança de estado e não deve sujar o histórico. */
    INSERT INTO CarregamentoHistorico
           (IDCarregamento, DataHora, EstadoAnterior, EstadoNovo, Observacao)
    SELECT i.IDCarregamento, SYSDATETIME(), d.Estado, i.Estado, N'Mudança de estado'
    FROM   inserted i
           INNER JOIN deleted d ON d.IDCarregamento = i.IDCarregamento
    WHERE  d.Estado <> i.Estado;
END
GO


/* ----------------------------------------------------------------------------
   TR_Ocorrencia_Historico
   Regra 3.7: "estados distintos ao longo do seu ciclo de vida"
   Exatamente o mesmo padrão, aplicado às manutenções.
   ---------------------------------------------------------------------------- */
CREATE TRIGGER TR_Ocorrencia_Historico
ON Ocorrencia
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO OcorrenciaHistorico
           (IDOcorrencia, DataHora, EstadoAnterior, EstadoNovo, Observacao)
    SELECT i.IDOcorrencia, SYSDATETIME(), NULL, i.Estado, N'Ocorrência registada'
    FROM   inserted i
    WHERE  NOT EXISTS (SELECT 1 FROM deleted d
                       WHERE d.IDOcorrencia = i.IDOcorrencia);

    INSERT INTO OcorrenciaHistorico
           (IDOcorrencia, DataHora, EstadoAnterior, EstadoNovo, Observacao)
    SELECT i.IDOcorrencia, SYSDATETIME(), d.Estado, i.Estado, N'Mudança de estado'
    FROM   inserted i
           INNER JOIN deleted d ON d.IDOcorrencia = i.IDOcorrencia
    WHERE  d.Estado <> i.Estado;
END
GO


/* ----------------------------------------------------------------------------
   TR_TarifarioPreco_SincronizaAtual
   ----------------------------------------------------------------------------
   O Tarifario tem uma CÓPIA do preço em vigor, para as consultas não terem de
   ir sempre à TarifarioPreco. É uma redundância assumida — e dois sítios com o
   mesmo facto acabam sempre por divergir, a menos que alguém garanta que não.
   É este trigger esse alguém.

   O LEFT JOIN resolve os dois casos de uma vez: se o tarifário tiver vigência
   aberta, copia o preço; se não tiver, o JOIN não encontra nada e a cópia fica
   a NULL — que é a resposta certa para "não há preço em vigor".
   ---------------------------------------------------------------------------- */
CREATE TRIGGER TR_TarifarioPreco_SincronizaAtual
ON TarifarioPreco
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET    t.PrecoKwhAtual     = tp.PrecoKwh,
           t.TaxaAtivacaoAtual = tp.TaxaAtivacao
    FROM   Tarifario t
           LEFT JOIN TarifarioPreco tp
                  ON tp.IDTarifario = t.IDTarifario
                 AND tp.DataFim IS NULL           -- a vigência em vigor
    /* Só os tarifários afetados. Podem vir do inserted (criou/alterou) ou do
       deleted (apagou/alterou), por isso é a união dos dois. */
    WHERE  t.IDTarifario IN (SELECT IDTarifario FROM inserted
                             UNION
                             SELECT IDTarifario FROM deleted);
END
GO


/* ----------------------------------------------------------------------------
   SINCRONIZAÇÃO INICIAL
   Os dados do script 02 entraram antes de este trigger existir, por isso a
   cópia está a NULL. Um UPDATE que não muda nada chega para o disparar.
   ---------------------------------------------------------------------------- */
UPDATE TarifarioPreco SET IDTarifario = IDTarifario;
GO

SELECT Nome, Comercializado, PrecoKwhAtual, TaxaAtivacaoAtual
FROM   Tarifario
ORDER BY Nome;
GO


/* ############################################################################
   PARTE 2 — CRUD
   ############################################################################

   Três tabelas, com a MESMA estrutura em todas as procedures. Quem perceber
   uma percebe as doze.

   O que muda entre elas é só a regra de remoção — e é de propósito, porque
   são as duas metades da regra 3.8 ("os dados não devem ser fisicamente
   removidos quando perdem validade operacional"):

     TipoConector   remoção FÍSICA    nunca teve histórico a preservar; um tipo
     Concelho       remoção FÍSICA    que ninguém usa é um engano de inserção,
                                      e corrigir um engano não é destruir nada

     Tarifario      remoção LÓGICA    tem carregamentos e faturas antigas
                                      agarradas. Apagá-lo tornava-as
                                      inexplicáveis. Marca-se como não
                                      comercializado e fica tudo intacto.
   ############################################################################ */


/* ############################################################################
   2A — TIPO DE CONECTOR   ·   remoção física, travada pela FK
   ############################################################################ */

CREATE PROCEDURE dbo.usp_TipoConector_Inserir
    @Designacao     NVARCHAR(40),
    @IDTipoConector INT = NULL OUTPUT      -- devolve o ID criado
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@Designacao, N''))) = N''
        THROW 50101, N'A designação do tipo de conector é obrigatória.', 1;

    /* A coluna já tem UNIQUE. Isto não substitui a restrição — só troca o
       erro 2627 do SQL Server por uma frase que se percebe. */
    IF EXISTS (SELECT 1 FROM TipoConector WHERE Designacao = @Designacao)
        THROW 50102, N'Já existe um tipo de conector com essa designação.', 1;

    INSERT INTO TipoConector (Designacao) VALUES (@Designacao);

    SET @IDTipoConector = SCOPE_IDENTITY();   -- o ID que o IDENTITY gerou
END
GO


/* LEFT JOIN de propósito: um tipo sem tomadas TEM de aparecer na listagem —
   é precisamente o que pode ser eliminado. Com INNER JOIN desaparecia. */
CREATE PROCEDURE dbo.usp_TipoConector_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT   tc.IDTipoConector,
             tc.Designacao,
             COUNT(pc.IDPostoConector)  AS TomadasAssociadas,
             CASE WHEN COUNT(pc.IDPostoConector) = 0
                  THEN N'Pode ser eliminado'
                  ELSE N'Em uso' END    AS Situacao
    FROM     TipoConector tc
             LEFT JOIN PostoConector pc ON pc.IDTipoConector = tc.IDTipoConector
    GROUP BY tc.IDTipoConector, tc.Designacao
    ORDER BY tc.Designacao;
END
GO


CREATE PROCEDURE dbo.usp_TipoConector_Atualizar
    @IDTipoConector INT,
    @Designacao     NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM TipoConector WHERE IDTipoConector = @IDTipoConector)
        THROW 50103, N'Tipo de conector inexistente.', 1;

    /* O <> exclui a própria linha: gravar um registo com o nome que já tem
       não pode ser tratado como duplicado. */
    IF EXISTS (SELECT 1 FROM TipoConector
               WHERE Designacao = @Designacao AND IDTipoConector <> @IDTipoConector)
        THROW 50104, N'Já existe outro tipo de conector com essa designação.', 1;

    UPDATE TipoConector
    SET    Designacao = @Designacao
    WHERE  IDTipoConector = @IDTipoConector;
END
GO


/* Quem decide se pode sair não é esta procedure: é a chave estrangeira. Se
   houver tomadas a apontar para o tipo, o SQL Server recusa o DELETE de
   qualquer forma. O que a verificação acrescenta é a mensagem. */
CREATE PROCEDURE dbo.usp_TipoConector_Eliminar
    @IDTipoConector INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM TipoConector WHERE IDTipoConector = @IDTipoConector)
        THROW 50105, N'Tipo de conector inexistente.', 1;

    IF EXISTS (SELECT 1 FROM PostoConector WHERE IDTipoConector = @IDTipoConector)
        THROW 50106, N'Não é possível eliminar: há tomadas com este tipo de conector.', 1;

    DELETE FROM TipoConector WHERE IDTipoConector = @IDTipoConector;
END
GO


/* ############################################################################
   2B — CONCELHO   ·   remoção física, travada pela FK
   ############################################################################
   Mesma estrutura da anterior. O que muda é a tabela que trava o DELETE:
   aqui são os postos instalados no concelho.
   ############################################################################ */

CREATE PROCEDURE dbo.usp_Concelho_Inserir
    @Nome       NVARCHAR(60),
    @IDConcelho INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@Nome, N''))) = N''
        THROW 50201, N'O nome do concelho é obrigatório.', 1;

    IF EXISTS (SELECT 1 FROM Concelho WHERE Nome = @Nome)
        THROW 50202, N'Já existe um concelho com esse nome.', 1;

    INSERT INTO Concelho (Nome) VALUES (@Nome);

    SET @IDConcelho = SCOPE_IDENTITY();
END
GO


CREATE PROCEDURE dbo.usp_Concelho_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT   co.IDConcelho,
             co.Nome,
             COUNT(p.IDPosto)          AS PostosInstalados,
             CASE WHEN COUNT(p.IDPosto) = 0
                  THEN N'Pode ser eliminado'
                  ELSE N'Em uso' END   AS Situacao
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

    IF NOT EXISTS (SELECT 1 FROM Concelho WHERE IDConcelho = @IDConcelho)
        THROW 50203, N'Concelho inexistente.', 1;

    IF EXISTS (SELECT 1 FROM Concelho
               WHERE Nome = @Nome AND IDConcelho <> @IDConcelho)
        THROW 50204, N'Já existe outro concelho com esse nome.', 1;

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

    IF NOT EXISTS (SELECT 1 FROM Concelho WHERE IDConcelho = @IDConcelho)
        THROW 50205, N'Concelho inexistente.', 1;

    IF EXISTS (SELECT 1 FROM Posto WHERE IDConcelho = @IDConcelho)
        THROW 50206, N'Não é possível eliminar: há postos instalados neste concelho.', 1;

    DELETE FROM Concelho WHERE IDConcelho = @IDConcelho;
END
GO


/* ############################################################################
   2C — TARIFÁRIO   ·   remoção lógica
   ############################################################################
   É a mais rica das três, por duas razões:

   1. Mexe em DUAS tabelas ao mesmo tempo (Tarifario + TarifarioPreco), o que
      obriga a uma TRANSAÇÃO: ou entram as duas, ou não entra nenhuma. Um
      tarifário sem preço não serve para nada.

   2. O preço não se escreve por cima do antigo. Fecha-se a vigência atual e
      abre-se outra — é a regra 3.2, e é o que permite explicar uma fatura de
      março com o preço de março.
   ############################################################################ */

CREATE PROCEDURE dbo.usp_Tarifario_Inserir
    @Nome         NVARCHAR(40),
    @PrecoKwh     DECIMAL(8,4),
    @TaxaAtivacao DECIMAL(8,2) = 0,        -- valor por omissão
    @DataInicio   DATE         = NULL,     -- NULL = a partir de hoje
    @IDTarifario  INT          = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;      -- se algo falhar, a transação é desfeita sozinha

    IF LTRIM(RTRIM(ISNULL(@Nome, N''))) = N''
        THROW 50301, N'O nome do tarifário é obrigatório.', 1;

    IF EXISTS (SELECT 1 FROM Tarifario WHERE Nome = @Nome)
        THROW 50302, N'Já existe um tarifário com esse nome.', 1;

    IF @PrecoKwh IS NULL OR @PrecoKwh <= 0
        THROW 50303, N'O preço por kWh tem de ser maior do que zero.', 1;

    IF @DataInicio IS NULL
        SET @DataInicio = CAST(GETDATE() AS DATE);

    BEGIN TRANSACTION;

        INSERT INTO Tarifario (Nome, Comercializado)
        VALUES (@Nome, 1);

        SET @IDTarifario = SCOPE_IDENTITY();

        INSERT INTO TarifarioPreco (IDTarifario, DataInicio, DataFim, PrecoKwh, TaxaAtivacao)
        VALUES (@IDTarifario, @DataInicio, NULL, @PrecoKwh, @TaxaAtivacao);
        -- o trigger de sincronização preenche a cópia sozinho, aqui

    COMMIT TRANSACTION;
END
GO


/* Os dois parâmetros são opcionais, e o padrão é sempre o mesmo:
   "ou não me disseste nada — e passam todos — ou disseste, e passa só esse". */
CREATE PROCEDURE dbo.usp_Tarifario_Listar
    @IDTarifario INT = NULL,
    @SoAtivos    BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT   t.IDTarifario,
             t.Nome,
             CASE t.Comercializado WHEN 1 THEN N'Sim' ELSE N'Não' END AS AindaSeVende,
             t.PrecoKwhAtual,
             t.TaxaAtivacaoAtual,
             COUNT(c.IDCarregamento) AS Carregamentos
    FROM     Tarifario t
             LEFT JOIN Carregamento c ON c.IDTarifario = t.IDTarifario
    WHERE    (@IDTarifario IS NULL OR t.IDTarifario = @IDTarifario)
      AND    (@SoAtivos = 0        OR t.Comercializado = 1)
    GROUP BY t.IDTarifario, t.Nome, t.Comercializado,
             t.PrecoKwhAtual, t.TaxaAtivacaoAtual
    ORDER BY t.Nome;
END
GO


CREATE PROCEDURE dbo.usp_Tarifario_Atualizar
    @IDTarifario  INT,
    @NovoNome     NVARCHAR(40) = NULL,     -- NULL = não mexer no nome
    @NovoPrecoKwh DECIMAL(8,4) = NULL,     -- NULL = não mexer no preço
    @NovaTaxa     DECIMAL(8,2) = NULL,
    @DataInicio   DATE         = NULL      -- quando o preço novo entra em vigor
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM Tarifario WHERE IDTarifario = @IDTarifario)
        THROW 50304, N'Tarifário inexistente.', 1;

    IF @NovoNome IS NOT NULL
       AND EXISTS (SELECT 1 FROM Tarifario
                   WHERE Nome = @NovoNome AND IDTarifario <> @IDTarifario)
        THROW 50305, N'Já existe outro tarifário com esse nome.', 1;

    IF @DataInicio IS NULL
        SET @DataInicio = CAST(GETDATE() AS DATE);

    /* A vigência nova tem de começar DEPOIS da que está aberta. Senão, ao
       fechar a antiga com DataInicio - 1, ela ficava com um fim anterior ao
       próprio início — e a restrição CHK_TarifPreco_Datas recusava. */
    IF @NovoPrecoKwh IS NOT NULL
       AND EXISTS (SELECT 1 FROM TarifarioPreco
                   WHERE IDTarifario = @IDTarifario
                     AND DataFim IS NULL
                     AND DataInicio >= @DataInicio)
        THROW 50306, N'O preço novo tem de começar depois do início da vigência atual.', 1;

    BEGIN TRANSACTION;

        IF @NovoNome IS NOT NULL
            UPDATE Tarifario SET Nome = @NovoNome WHERE IDTarifario = @IDTarifario;

        IF @NovoPrecoKwh IS NOT NULL
        BEGIN
            -- 1) fecha a vigência que estava aberta, no dia anterior à nova
            UPDATE TarifarioPreco
            SET    DataFim = DATEADD(DAY, -1, @DataInicio)
            WHERE  IDTarifario = @IDTarifario AND DataFim IS NULL;

            -- 2) abre a nova (o trigger sincroniza a cópia)
            INSERT INTO TarifarioPreco (IDTarifario, DataInicio, DataFim, PrecoKwh, TaxaAtivacao)
            VALUES (@IDTarifario, @DataInicio, NULL, @NovoPrecoKwh, ISNULL(@NovaTaxa, 0));
        END

    COMMIT TRANSACTION;
END
GO


/* D — o "delete" que não apaga nada.
   Regra 3.8. Um tarifário com carregamentos antigos não pode desaparecer: as
   faturas passadas deixavam de fazer sentido. Deixa de se vender, e o
   histórico fica intacto. */
CREATE PROCEDURE dbo.usp_Tarifario_Descontinuar
    @IDTarifario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM Tarifario WHERE IDTarifario = @IDTarifario)
        THROW 50307, N'Tarifário inexistente.', 1;

    DECLARE @Hoje DATE = CAST(GETDATE() AS DATE);

    BEGIN TRANSACTION;

        UPDATE Tarifario
        SET    Comercializado = 0
        WHERE  IDTarifario = @IDTarifario;

        /* Fecha o preço em vigor: deixou de haver preço a praticar.
           O CASE trata o caso do preço agendado para o futuro, que ainda nem
           começou — fecha no próprio dia de início, porque nada pode acabar
           antes de começar. */
        UPDATE TarifarioPreco
        SET    DataFim = CASE WHEN DataInicio > @Hoje THEN DataInicio ELSE @Hoje END
        WHERE  IDTarifario = @IDTarifario AND DataFim IS NULL;

    COMMIT TRANSACTION;
END
GO


/* ############################################################################
   PARTE 3 — FUNÇÕES
   ############################################################################
   Uma de cada tipo:
     ESCALAR      devolve UM valor.    Usa-se onde caberia uma coluna.
     DE TABELA    devolve LINHAS.      Usa-se no FROM, como se fosse tabela.
   ############################################################################ */


/* ----------------------------------------------------------------------------
   ESCALAR — o preço que estava em vigor numa data qualquer.

   É isto que a cópia dentro do Tarifario NÃO consegue responder: ela só sabe
   o preço de hoje. Para explicar uma fatura de março é preciso ir à
   TarifarioPreco — e é por isso que as duas coexistem.
   ---------------------------------------------------------------------------- */
CREATE FUNCTION dbo.fn_PrecoEmVigor (@IDTarifario INT, @Data DATE)
RETURNS DECIMAL(8,4)
AS
BEGIN
    DECLARE @Preco DECIMAL(8,4);

    SELECT @Preco = tp.PrecoKwh
    FROM   TarifarioPreco tp
    WHERE  tp.IDTarifario = @IDTarifario
      AND  @Data >= tp.DataInicio
      /* O OR é obrigatório: DataFim a NULL quer dizer "ainda em vigor", e
         qualquer comparação com NULL dá desconhecido, nunca verdadeiro. */
      AND (@Data <= tp.DataFim OR tp.DataFim IS NULL);

    RETURN @Preco;      -- NULL se nesse dia não havia preço em vigor
END
GO


/* ----------------------------------------------------------------------------
   DE TABELA — estatísticas por posto.   @IDPosto NULL → todos.

   Dois pontos que se repetem dos relatórios da Parte C:
     · os filtros do carregamento estão no ON, não no WHERE — no WHERE
       anulavam o LEFT JOIN e os postos sem carregamentos desapareciam
     · COUNT(coluna) e não COUNT(*), que contaria a linha vazia como 1
   ---------------------------------------------------------------------------- */
CREATE FUNCTION dbo.fn_EstatisticasPosto (@IDPosto INT)
RETURNS TABLE
AS
RETURN
    SELECT p.IDPosto,
           p.Codigo,
           p.NomePosto,
           p.PotenciaKw,
           COUNT(c.IDCarregamento)                        AS Carregamentos,
           ISNULL(SUM(c.EnergiaKwh), 0)                   AS EnergiaTotalKwh,
           CAST(ISNULL(AVG(c.CustoTotal), 0) AS DECIMAL(9,2)) AS CustoMedio,
           CAST(ISNULL(SUM(c.CustoTotal), 0) AS DECIMAL(9,2)) AS ReceitaTotal
    FROM   Posto p
           LEFT JOIN PostoConector pc ON pc.IDPosto        = p.IDPosto
           LEFT JOIN Carregamento  c  ON c.IDPostoConector = pc.IDPostoConector
                                     AND c.Estado IN ('Terminado', 'Faturado')
    WHERE  @IDPosto IS NULL OR p.IDPosto = @IDPosto
    GROUP BY p.IDPosto, p.Codigo, p.NomePosto, p.PotenciaKw;
GO


/* ############################################################################
   PARTE 4 — DEMONSTRAÇÃO
   ############################################################################
   Cada bloco mostra uma coisa só. Os que testam erros usam TRY/CATCH para o
   script não parar — é aqui que o TRY/CATCH faz sentido: em quem CHAMA, para
   apanhar o erro, e não dentro da procedure.
   ############################################################################ */

PRINT N'';
PRINT N'=== CRUD DO TARIFÁRIO (remoção lógica) ===';

PRINT N'--- Estado inicial ---';
EXEC dbo.usp_Tarifario_Listar;
GO

PRINT N'--- C: criar um tarifário (cria também a 1a vigência de preço) ---';
DECLARE @NovoID INT;
EXEC dbo.usp_Tarifario_Inserir
     @Nome = N'Fim de Semana', @PrecoKwh = 0.1900, @TaxaAtivacao = 0.30,
     @DataInicio = '2026-08-01', @IDTarifario = @NovoID OUTPUT;
PRINT N'Criado com o ID ' + CAST(@NovoID AS VARCHAR(10));
GO

PRINT N'--- U: subir o preço (fecha a vigência antiga, abre a nova) ---';
DECLARE @ID INT = (SELECT IDTarifario FROM Tarifario WHERE Nome = N'Fim de Semana');
EXEC dbo.usp_Tarifario_Atualizar
     @IDTarifario = @ID, @NovoPrecoKwh = 0.2400, @DataInicio = '2026-09-01';
GO

PRINT N'--- O histórico de preços que ficou, e a cópia sincronizada ---';
SELECT t.Nome, t.PrecoKwhAtual AS CopiaNoTarifario,
       p.DataInicio, p.DataFim, p.PrecoKwh
FROM   TarifarioPreco p
       INNER JOIN Tarifario t ON t.IDTarifario = p.IDTarifario
WHERE  t.Nome = N'Fim de Semana'
ORDER BY p.DataInicio;
GO

PRINT N'--- D: descontinuar. Nao apaga: marca como nao comercializado ---';
DECLARE @ID INT = (SELECT IDTarifario FROM Tarifario WHERE Nome = N'Fim de Semana');
EXEC dbo.usp_Tarifario_Descontinuar @IDTarifario = @ID;
EXEC dbo.usp_Tarifario_Listar @IDTarifario = @ID;
GO

PRINT N'--- Erro tratado: nome repetido ---';
BEGIN TRY
    EXEC dbo.usp_Tarifario_Inserir @Nome = N'Normal', @PrecoKwh = 0.30;
END TRY
BEGIN CATCH
    PRINT N'Erro apanhado: ' + ERROR_MESSAGE();
END CATCH
GO


PRINT N'';
PRINT N'=== CRUD DO TIPO DE CONECTOR (remoção física) ===';

PRINT N'--- Estado inicial ---';
EXEC dbo.usp_TipoConector_Listar;
GO

PRINT N'--- C, U e D sobre um tipo novo: ninguem o usa, por isso sai ---';
DECLARE @IDNovo INT;
EXEC dbo.usp_TipoConector_Inserir @Designacao = N'Tesla NACS', @IDTipoConector = @IDNovo OUTPUT;
EXEC dbo.usp_TipoConector_Atualizar @IDTipoConector = @IDNovo, @Designacao = N'NACS';
EXEC dbo.usp_TipoConector_Eliminar  @IDTipoConector = @IDNovo;
PRINT N'Inserido, alterado e eliminado.';
GO

PRINT N'--- D: tentar eliminar um que ESTA em uso ---';
BEGIN TRY
    DECLARE @EmUso INT = (SELECT TOP 1 IDTipoConector FROM PostoConector);
    EXEC dbo.usp_TipoConector_Eliminar @IDTipoConector = @EmUso;
END TRY
BEGIN CATCH
    PRINT N'Travado como devia: ' + ERROR_MESSAGE();
END CATCH
GO


PRINT N'';
PRINT N'=== CRUD DO CONCELHO (remoção física) ===';

PRINT N'--- Estado inicial: repara em Coimbra, com zero postos ---';
EXEC dbo.usp_Concelho_Listar;
GO

PRINT N'--- C, U e D sobre um concelho novo ---';
DECLARE @IDCon INT;
EXEC dbo.usp_Concelho_Inserir   @Nome = N'Vila Verde', @IDConcelho = @IDCon OUTPUT;
EXEC dbo.usp_Concelho_Atualizar @IDConcelho = @IDCon, @Nome = N'Vila Verde (Braga)';
EXEC dbo.usp_Concelho_Eliminar  @IDConcelho = @IDCon;
PRINT N'Inserido, alterado e eliminado: nao tinha postos.';
GO

PRINT N'--- D: tentar eliminar um concelho COM postos ---';
BEGIN TRY
    DECLARE @ComPostos INT = (SELECT TOP 1 IDConcelho FROM Posto);
    EXEC dbo.usp_Concelho_Eliminar @IDConcelho = @ComPostos;
END TRY
BEGIN CATCH
    PRINT N'Travado como devia: ' + ERROR_MESSAGE();
END CATCH
GO


PRINT N'';
PRINT N'=== FUNÇÕES ===';

PRINT N'--- Escalar: o preco do tarifario 1 em duas datas diferentes ---';
SELECT dbo.fn_PrecoEmVigor(1, '2026-03-15') AS PrecoEmMarco,
       dbo.fn_PrecoEmVigor(1, '2026-08-15') AS PrecoEmAgosto;
GO

PRINT N'--- De tabela: estatisticas de todos os postos ---';
SELECT * FROM dbo.fn_EstatisticasPosto(NULL)
ORDER BY Carregamentos DESC, Codigo;
GO


PRINT N'';
PRINT N'=== TRIGGER DE HISTÓRICO ===';

PRINT N'--- Um UPDATE que NAO muda o estado nao deve escrever no historico ---';
DECLARE @C INT = (SELECT MIN(IDCarregamento) FROM Carregamento WHERE Estado = 'Terminado');
DECLARE @Antes INT = (SELECT COUNT(*) FROM CarregamentoHistorico WHERE IDCarregamento = @C);

UPDATE Carregamento SET CustoTotal = CustoTotal WHERE IDCarregamento = @C;

DECLARE @Depois INT = (SELECT COUNT(*) FROM CarregamentoHistorico WHERE IDCarregamento = @C);
PRINT N'Linhas de historico: ' + CAST(@Antes AS VARCHAR) + N' -> ' + CAST(@Depois AS VARCHAR)
    + N' (tem de ser igual)';
GO
