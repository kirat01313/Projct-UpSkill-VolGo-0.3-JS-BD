/* ============================================================================
   VoltGo — 03 — Procedimentos, funções e triggers                   PARTE B
   ============================================================================
   Correr depois do 01 e do 02, e ANTES dos relatórios: o trigger de
   sincronização preenche o preço em vigor de cada tarifário, que o relatório 3
   mostra.

   O QUE ESTÁ AQUI E PORQUÊ

     PROCEDIMENTOS  CRUD completo do Tarifário.
                    Escolhido por ser simples (3 colunas) mas não trivial: tem
                    tabela filha e uma regra de negócio própria (não se apaga,
                    descontinua-se). Dá para mostrar transação, tratamento de
                    erro e remoção lógica num objeto só.

     FUNÇÕES        Uma escalar (devolve um número) e uma de tabela (devolve
                    linhas), para cobrir os dois tipos.

     TRIGGERS       Três. Dois de auditoria — o histórico deixa de depender de
                    quem escreve o código. Um de sincronização — é ele que
                    torna segura a cópia do preço dentro do Tarifario.

   DIFERENÇA ENTRE OS TRÊS OBJETOS
     Procedimento   FAZ coisas. Chama-se com EXEC. Pode alterar dados.
     Função         RESPONDE a uma pergunta. Usa-se dentro de um SELECT.
                    Nunca altera dados.
     Trigger        REAGE sozinho. Ninguém o chama.
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO

/* Limpeza, para o script poder ser corrido as vezes que forem precisas.
   As funções saem pela ordem inversa da dependência: a de tabela usa a escalar. */
DROP TRIGGER   IF EXISTS TR_Carregamento_Historico;
DROP TRIGGER   IF EXISTS TR_Ocorrencia_Historico;
DROP TRIGGER   IF EXISTS TR_TarifarioPreco_SincronizaAtual;
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

   A ÚNICA COISA QUE É PRECISO PERCEBER ANTES DE LER O CÓDIGO

   Dentro de um trigger existem duas tabelas especiais, criadas pelo SQL Server:

        inserted   →  como as linhas ficaram DEPOIS
        deleted    →  como as linhas estavam ANTES

   E a armadilha número um de quem começa:

        SÃO TABELAS, NÃO SÃO LINHAS.

   Um UPDATE que mexa em 50 linhas dispara o trigger UMA vez, com 50 linhas
   dentro do 'inserted'. Quem o escreve a pensar numa linha só (SELECT @var = ...)
   trata uma e ignora as outras 49 — sem erro nenhum, em silêncio.

   Por isso tudo aqui dentro é INSERT...SELECT, que trata o conjunto de uma vez.

   Como saber que operação foi:
        está em inserted e não em deleted  →  INSERT
        está nas duas                      →  UPDATE
        está só em deleted                 →  DELETE
   ############################################################################ */


/* ----------------------------------------------------------------------------
   TR_Carregamento_Historico
   Regra 3.5: "alterações relevantes devem ser registadas para consulta futura"

   Até agora o histórico era preenchido à mão, no script 02. Isso tem um
   problema: basta alguém esquecer-se uma vez e o histórico passa a mentir.
   Com o trigger, deixa de depender de quem escreve o código — qualquer INSERT
   ou UPDATE fica registado, venha de uma procedure, de uma aplicação ou de
   alguém a escrever SQL à mão.
   ---------------------------------------------------------------------------- */
CREATE TRIGGER TR_Carregamento_Historico
ON Carregamento
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* Carregamentos NOVOS: estão no inserted e não no deleted.
       EstadoAnterior fica NULL — antes disto o carregamento não existia. */
    INSERT INTO CarregamentoHistorico (IDCarregamento, DataHora, EstadoAnterior, EstadoNovo, Observacao)
    SELECT i.IDCarregamento, SYSDATETIME(), NULL, i.Estado, N'Registo criado'
    FROM   inserted i
           LEFT JOIN deleted d ON d.IDCarregamento = i.IDCarregamento
    WHERE  d.IDCarregamento IS NULL;

    /* MUDANÇAS DE ESTADO: estão nas duas tabelas.
       Só se regista se o estado mudou mesmo — um UPDATE que corrija o custo
       não é uma mudança de estado e não deve sujar o histórico. */
    INSERT INTO CarregamentoHistorico (IDCarregamento, DataHora, EstadoAnterior, EstadoNovo, Observacao)
    SELECT i.IDCarregamento, SYSDATETIME(), d.Estado, i.Estado, N'Mudança de estado'
    FROM   inserted i
           INNER JOIN deleted d ON d.IDCarregamento = i.IDCarregamento
    WHERE  d.Estado <> i.Estado;
END
GO


/* ----------------------------------------------------------------------------
   TR_Ocorrencia_Historico
   Regra 3.7: "estados distintos ao longo do seu ciclo de vida"
   Mesmo padrão, para as manutenções.
   ---------------------------------------------------------------------------- */
CREATE TRIGGER TR_Ocorrencia_Historico
ON Ocorrencia
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO OcorrenciaHistorico (IDOcorrencia, DataHora, EstadoAnterior, EstadoNovo, Observacao)
    SELECT i.IDOcorrencia, SYSDATETIME(), NULL, i.Estado, N'Ocorrência registada'
    FROM   inserted i
           LEFT JOIN deleted d ON d.IDOcorrencia = i.IDOcorrencia
    WHERE  d.IDOcorrencia IS NULL;

    INSERT INTO OcorrenciaHistorico (IDOcorrencia, DataHora, EstadoAnterior, EstadoNovo, Observacao)
    SELECT i.IDOcorrencia, SYSDATETIME(), d.Estado, i.Estado, N'Mudança de estado'
    FROM   inserted i
           INNER JOIN deleted d ON d.IDOcorrencia = i.IDOcorrencia
    WHERE  d.Estado <> i.Estado;
END
GO


/* ----------------------------------------------------------------------------
   TR_TarifarioPreco_SincronizaAtual                       ★ O MAIS IMPORTANTE
   ----------------------------------------------------------------------------
   O Tarifario tem uma CÓPIA do preço em vigor (PrecoKwhAtual, TaxaAtivacaoAtual)
   para simplificar as consultas — evita o JOIN com a TarifarioPreco sempre que
   só se quer o preço de hoje.

   Isso é uma desnormalização deliberada: o mesmo facto passa a estar em dois
   sítios. E dois sítios com o mesmo facto acabam sempre por divergir — a menos
   que alguém garanta o contrário. É este trigger esse alguém.

   Sempre que uma vigência é criada, alterada ou apagada, ele recalcula a cópia
   a partir da fonte da verdade, que continua a ser a TarifarioPreco.

   O que se ganha: consultas simples E histórico completo.
   O que se paga: este trigger tem de existir e não pode ser desligado.
   ---------------------------------------------------------------------------- */
CREATE TRIGGER TR_TarifarioPreco_SincronizaAtual
ON TarifarioPreco
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    /* Os tarifários afetados podem vir de qualquer uma das duas tabelas:
       de inserted (criou/alterou) ou de deleted (apagou/alterou). */
    ;WITH Afetados AS (
        SELECT IDTarifario FROM inserted
        UNION
        SELECT IDTarifario FROM deleted
    )
    UPDATE t
    SET    t.PrecoKwhAtual     = v.PrecoKwh,
           t.TaxaAtivacaoAtual = v.TaxaAtivacao
    FROM   Tarifario t
           INNER JOIN Afetados a ON a.IDTarifario = t.IDTarifario
           /* OUTER APPLY e não JOIN: se o tarifário ficar sem vigência aberta,
              a cópia tem de ir a NULL em vez de ficar com o valor antigo. */
           OUTER APPLY (
               SELECT TOP 1 tp.PrecoKwh, tp.TaxaAtivacao
               FROM   TarifarioPreco tp
               WHERE  tp.IDTarifario = t.IDTarifario
                 AND  tp.DataFim IS NULL          -- a vigência em vigor
           ) v;
END
GO


/* ----------------------------------------------------------------------------
   SINCRONIZAÇÃO INICIAL
   Os dados do script 02 entraram antes de este trigger existir, por isso a
   cópia está a NULL. Um UPDATE que não muda nada é suficiente para disparar o
   trigger e pôr tudo em dia.
   ---------------------------------------------------------------------------- */
UPDATE TarifarioPreco SET IDTarifario = IDTarifario;
GO

SELECT Nome, Comercializado, PrecoKwhAtual, TaxaAtivacaoAtual
FROM   Tarifario
ORDER BY Nome;
GO


/* ############################################################################
   PARTE 2 — CRUD DO TARIFÁRIO (procedimentos)
   ############################################################################ */

/* ----------------------------------------------------------------------------
   C — CREATE
   Cria o tarifário E a sua primeira vigência de preço numa só operação.

   As duas coisas têm de acontecer juntas: um tarifário sem preço não serve
   para nada. Por isso vão dentro de uma TRANSAÇÃO — ou entram as duas, ou não
   entra nenhuma. Se o segundo INSERT falhar, o ROLLBACK desfaz o primeiro.
   ---------------------------------------------------------------------------- */
CREATE PROCEDURE dbo.usp_Tarifario_Inserir
    @Nome         NVARCHAR(40),
    @PrecoKwh     DECIMAL(8,4),
    @TaxaAtivacao DECIMAL(8,2) = 0,        -- valor por omissão
    @DataInicio   DATE         = NULL,     -- NULL = a partir de hoje
    @IDTarifario  INT          OUTPUT      -- devolve o ID criado
AS
BEGIN
    SET NOCOUNT ON;

    IF @DataInicio IS NULL
        SET @DataInicio = CAST(GETDATE() AS DATE);

    /* Validações próprias, antes de tocar na base de dados: dão mensagens em
       português em vez do erro cru do SQL Server. */
    IF EXISTS (SELECT 1 FROM Tarifario WHERE Nome = @Nome)
    BEGIN
        RAISERROR(N'Já existe um tarifário com o nome "%s".', 16, 1, @Nome);
        RETURN;
    END

    IF @PrecoKwh <= 0
    BEGIN
        RAISERROR(N'O preço por kWh tem de ser maior do que zero.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO Tarifario (Nome, Comercializado)
            VALUES (@Nome, 1);

            SET @IDTarifario = SCOPE_IDENTITY();   -- o ID que o IDENTITY gerou

            INSERT INTO TarifarioPreco (IDTarifario, DataInicio, DataFim, PrecoKwh, TaxaAtivacao)
            VALUES (@IDTarifario, @DataInicio, NULL, @PrecoKwh, @TaxaAtivacao);
            /* o trigger de sincronização preenche a cópia sozinho, aqui */

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;   -- devolve o erro original, com o número e a linha certos
    END CATCH
END
GO


/* ----------------------------------------------------------------------------
   R — READ
   @IDTarifario NULL → todos.   @SoAtivos 1 → esconde os descontinuados.
   ---------------------------------------------------------------------------- */
CREATE PROCEDURE dbo.usp_Tarifario_Listar
    @IDTarifario INT = NULL,
    @SoAtivos    BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT t.IDTarifario,
           t.Nome,
           CASE t.Comercializado WHEN 1 THEN 'Sim' ELSE 'Nao' END AS AindaSeVende,
           t.PrecoKwhAtual,
           t.TaxaAtivacaoAtual,
           (SELECT COUNT(*) FROM TarifarioPreco h WHERE h.IDTarifario = t.IDTarifario) AS AlteracoesDePreco,
           (SELECT COUNT(*) FROM Carregamento  c WHERE c.IDTarifario = t.IDTarifario) AS Carregamentos
    FROM   Tarifario t
    WHERE  (@IDTarifario IS NULL OR t.IDTarifario = @IDTarifario)
      AND  (@SoAtivos = 0       OR t.Comercializado = 1)
    ORDER BY t.Nome;
END
GO


/* ----------------------------------------------------------------------------
   U — UPDATE
   O preço NÃO se escreve por cima do antigo: fecha-se a vigência atual e
   abre-se outra. É a regra 3.2 — as condições variam ao longo do tempo, e o
   histórico tem de ficar.
   ---------------------------------------------------------------------------- */
CREATE PROCEDURE dbo.usp_Tarifario_Atualizar
    @IDTarifario  INT,
    @NovoNome     NVARCHAR(40) = NULL,     -- NULL = não mexer no nome
    @NovoPrecoKwh DECIMAL(8,4) = NULL,     -- NULL = não mexer no preço
    @NovaTaxa     DECIMAL(8,2) = NULL,
    @DataInicio   DATE         = NULL      -- quando o preço novo entra em vigor
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Tarifario WHERE IDTarifario = @IDTarifario)
    BEGIN
        RAISERROR(N'Não existe nenhum tarifário com o ID %d.', 16, 1, @IDTarifario);
        RETURN;
    END

    IF @DataInicio IS NULL
        SET @DataInicio = CAST(GETDATE() AS DATE);

    /* A vigência nova tem de começar DEPOIS da que está aberta. Senão, ao
       fechar a antiga com DataFim = @DataInicio - 1, ela ficaria com um fim
       anterior ao próprio início — e o CHK_TarifPreco_Datas recusa. */
    DECLARE @InicioAtual DATE =
        (SELECT DataInicio FROM TarifarioPreco
         WHERE IDTarifario = @IDTarifario AND DataFim IS NULL);

    IF @NovoPrecoKwh IS NOT NULL AND @InicioAtual IS NOT NULL AND @DataInicio <= @InicioAtual
    BEGIN
        /* o RAISERROR não aceita DATE nos %s: tem de ir convertida para texto */
        DECLARE @Txt VARCHAR(10) = CONVERT(VARCHAR(10), @InicioAtual, 23);
        RAISERROR(N'O preço novo tem de começar depois de %s, início da vigência atual.', 16, 1, @Txt);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

            IF @NovoNome IS NOT NULL
                UPDATE Tarifario SET Nome = @NovoNome WHERE IDTarifario = @IDTarifario;

            IF @NovoPrecoKwh IS NOT NULL
            BEGIN
                -- 1) fecha a vigência que estava aberta
                UPDATE TarifarioPreco
                SET    DataFim = DATEADD(DAY, -1, @DataInicio)
                WHERE  IDTarifario = @IDTarifario AND DataFim IS NULL;

                -- 2) abre a nova (o trigger sincroniza a cópia)
                INSERT INTO TarifarioPreco (IDTarifario, DataInicio, DataFim, PrecoKwh, TaxaAtivacao)
                VALUES (@IDTarifario, @DataInicio, NULL, @NovoPrecoKwh, ISNULL(@NovaTaxa, 0));
            END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


/* ----------------------------------------------------------------------------
   D — DELETE (que não apaga nada)

   Regra 3.8: "os dados não devem ser fisicamente removidos quando perdem
   validade operacional".

   Um tarifário com carregamentos antigos NÃO pode desaparecer: as faturas
   passadas deixariam de fazer sentido. Por isso o "delete" é lógico —
   Comercializado = 0. Deixa de se vender, o histórico fica intacto.

   Só se apaga a sério se nunca tiver sido usado por ninguém.
   ---------------------------------------------------------------------------- */
CREATE PROCEDURE dbo.usp_Tarifario_Descontinuar
    @IDTarifario INT,
    @Forcar      BIT = 0     -- 1 = apagar mesmo, se nunca tiver sido usado
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Tarifario WHERE IDTarifario = @IDTarifario)
    BEGIN
        RAISERROR(N'Não existe nenhum tarifário com o ID %d.', 16, 1, @IDTarifario);
        RETURN;
    END

    DECLARE @Usos INT = (SELECT COUNT(*) FROM Carregamento WHERE IDTarifario = @IDTarifario);

    BEGIN TRY
        BEGIN TRANSACTION;

            IF @Forcar = 1 AND @Usos = 0
            BEGIN
                DELETE FROM TarifarioPreco WHERE IDTarifario = @IDTarifario;
                DELETE FROM Tarifario      WHERE IDTarifario = @IDTarifario;
                PRINT N'Tarifário removido (nunca tinha sido usado).';
            END
            ELSE
            BEGIN
                UPDATE Tarifario SET Comercializado = 0 WHERE IDTarifario = @IDTarifario;

                /* Fecha o preço em vigor: deixou de haver preço a praticar.
                   Fecha-se hoje — exceto se a vigência ainda nem começou
                   (preço agendado), caso em que fecha no próprio dia de início:
                   nada pode acabar antes de começar. */
                DECLARE @Hoje DATE = CAST(GETDATE() AS DATE);
                UPDATE TarifarioPreco
                SET    DataFim = CASE WHEN DataInicio > @Hoje THEN DataInicio ELSE @Hoje END
                WHERE  IDTarifario = @IDTarifario AND DataFim IS NULL;

                PRINT N'Tarifário descontinuado. Histórico preservado.';
            END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


/* ############################################################################
   PARTE 3 — FUNÇÕES
   ############################################################################ */

/* ----------------------------------------------------------------------------
   FUNÇÃO ESCALAR — devolve UM valor
   O preço que estava em vigor numa data qualquer.

   É isto que a cópia dentro do Tarifario NÃO consegue responder: ela só sabe
   o preço de hoje. Para explicar uma fatura de fevereiro é preciso ir à
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
      AND (@Data <= tp.DataFim OR tp.DataFim IS NULL);

    RETURN @Preco;      -- toda a função tem de terminar num RETURN
END
GO


/* ----------------------------------------------------------------------------
   FUNÇÃO DE TABELA — devolve LINHAS
   Estatísticas por posto. Usa-se dentro de um FROM, como se fosse uma tabela.

   @IDPosto NULL → todos os postos.
   ---------------------------------------------------------------------------- */
CREATE FUNCTION dbo.fn_EstatisticasPosto (@IDPosto INT)
RETURNS TABLE
AS
RETURN
    SELECT p.IDPosto,
           p.Codigo,
           p.NomePosto,
           p.PotenciaKw,
           COUNT(c.IDCarregamento)                      AS Carregamentos,
           SUM(c.EnergiaKwh)                            AS EnergiaTotalKwh,
           CAST(AVG(c.CustoTotal) AS DECIMAL(9,2))      AS CustoMedio,
           CAST(SUM(c.CustoTotal) AS DECIMAL(9,2))      AS ReceitaTotal,
           /* Potência média realmente entregue: energia a dividir pelo tempo.
              Comparada com a PotenciaKw do posto, mostra o quanto ele está a
              ser aproveitado — e é a base do Alerta da Parte E. */
           CAST(AVG(c.EnergiaKwh /
                NULLIF(DATEDIFF(SECOND, c.DataHoraInicio, c.DataHoraFim) / 3600.0, 0))
                AS DECIMAL(8,2))                        AS PotenciaMediaKw
    FROM   Posto p
           /* LEFT JOIN: os postos sem carregamentos aparecem com 0 e NULL em
              vez de desaparecerem da estatística. */
           LEFT JOIN PostoConector pc ON pc.IDPosto        = p.IDPosto
           LEFT JOIN Carregamento  c  ON c.IDPostoConector = pc.IDPostoConector
                                     AND c.Estado IN ('Terminado','Faturado')
                                     AND c.DataHoraFim IS NOT NULL
    WHERE  @IDPosto IS NULL OR p.IDPosto = @IDPosto
    GROUP BY p.IDPosto, p.Codigo, p.NomePosto, p.PotenciaKw;
GO


/* ############################################################################
   DEMONSTRAÇÃO
   ############################################################################ */

PRINT N'--- READ: todos os tarifários (a cópia do preço já está sincronizada) ---';
EXEC dbo.usp_Tarifario_Listar;
GO

PRINT N'--- CREATE: um tarifário novo ---';
DECLARE @NovoID INT;
EXEC dbo.usp_Tarifario_Inserir
        @Nome        = N'Fim de Semana',
        @PrecoKwh    = 0.2100,
        @DataInicio  = '2026-08-01',
        @IDTarifario = @NovoID OUTPUT;
PRINT N'Criado com o ID ' + CAST(@NovoID AS VARCHAR(10));
GO

PRINT N'--- UPDATE: subir o preço (fecha a vigência antiga, abre a nova) ---';
DECLARE @ID INT = (SELECT IDTarifario FROM Tarifario WHERE Nome = N'Fim de Semana');
EXEC dbo.usp_Tarifario_Atualizar @IDTarifario = @ID, @NovoPrecoKwh = 0.2400, @DataInicio = '2026-09-01';
GO

PRINT N'--- O histórico de preços que ficou, e a cópia sincronizada ---';
SELECT t.Nome, t.PrecoKwhAtual AS CopiaNoTarifario,
       p.DataInicio, p.DataFim, p.PrecoKwh
FROM   TarifarioPreco p
       INNER JOIN Tarifario t ON t.IDTarifario = p.IDTarifario
WHERE  t.Nome = N'Fim de Semana'
ORDER BY p.DataInicio;
GO

PRINT N'--- DELETE lógico ---';
DECLARE @ID INT = (SELECT IDTarifario FROM Tarifario WHERE Nome = N'Fim de Semana');
EXEC dbo.usp_Tarifario_Descontinuar @IDTarifario = @ID;
GO

PRINT N'--- Erro tratado: nome repetido ---';
BEGIN TRY
    DECLARE @X INT;
    EXEC dbo.usp_Tarifario_Inserir @Nome = N'Normal', @PrecoKwh = 0.30, @IDTarifario = @X OUTPUT;
END TRY
BEGIN CATCH
    PRINT N'Erro apanhado: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT N'--- FUNÇÃO ESCALAR: o preço do Normal em duas datas diferentes ---';
SELECT dbo.fn_PrecoEmVigor(1, '2026-03-15') AS PrecoEmMarco,
       dbo.fn_PrecoEmVigor(1, '2026-08-15') AS PrecoEmAgosto;
GO

PRINT N'--- FUNÇÃO DE TABELA: estatísticas de todos os postos ---';
SELECT * FROM dbo.fn_EstatisticasPosto(NULL)
ORDER BY Carregamentos DESC, Codigo;
GO

PRINT N'--- TRIGGER de histórico: uma mudança de estado gera a linha sozinha ---';
DECLARE @C INT = (SELECT MIN(IDCarregamento) FROM Carregamento WHERE Estado = 'Terminado');
DECLARE @Antes INT = (SELECT COUNT(*) FROM CarregamentoHistorico WHERE IDCarregamento = @C);

UPDATE Carregamento SET CustoTotal = CustoTotal WHERE IDCarregamento = @C;   -- não muda o estado
DECLARE @Meio INT = (SELECT COUNT(*) FROM CarregamentoHistorico WHERE IDCarregamento = @C);

PRINT N'Depois de um UPDATE que NAO muda o estado: ' + CAST(@Antes AS VARCHAR) + N' -> ' + CAST(@Meio AS VARCHAR) + N' (igual)';
GO
