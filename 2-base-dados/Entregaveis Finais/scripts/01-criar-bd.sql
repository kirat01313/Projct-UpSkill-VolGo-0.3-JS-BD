/* ============================================================================
   VoltGo — 01 — Criação da base de dados                            PARTE B
   Trabalho Prático de Bases de Dados · UpSkill/IPCA · Fred & Tarik
   ----------------------------------------------------------------------------
   Apaga a base e cria-a de raiz: 16 tabelas, 1 vista e as restrições.
   As decisões de modelação estão explicadas em ../../guias/.
   ============================================================================ */

USE master;
GO

/* Permite correr este script as vezes que forem precisas. */
IF DB_ID('VoltGo') IS NOT NULL
BEGIN
    ALTER DATABASE VoltGo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE VoltGo;
END
GO

CREATE DATABASE VoltGo;
GO

USE VoltGo;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


CREATE TABLE Concelho (
    IDConcelho  INT           IDENTITY(1,1)  NOT NULL,
    Nome        NVARCHAR(60)                 NOT NULL,

    CONSTRAINT PK_Concelho      PRIMARY KEY (IDConcelho),
    CONSTRAINT UQ_Concelho_Nome UNIQUE      (Nome)
);
GO

CREATE TABLE TipoConector (
    IDTipoConector  INT           IDENTITY(1,1)  NOT NULL,
    Designacao      NVARCHAR(40)                 NOT NULL,   -- 'Type 2', 'CCS2', 'CHAdeMO'

    CONSTRAINT PK_TipoConector       PRIMARY KEY (IDTipoConector),
    CONSTRAINT UQ_TipoConector_Desig UNIQUE      (Designacao)
);
GO

CREATE TABLE TipoAvaria (
    IDTipoAvaria  INT           IDENTITY(1,1)  NOT NULL,
    Designacao    NVARCHAR(60)                 NOT NULL,

    CONSTRAINT PK_TipoAvaria       PRIMARY KEY (IDTipoAvaria),
    CONSTRAINT UQ_TipoAvaria_Desig UNIQUE      (Designacao)
);
GO


CREATE TABLE Posto (
    IDPosto          INT           IDENTITY(1,1)  NOT NULL,
    Codigo           NVARCHAR(10)                 NOT NULL,
    IDConcelho       INT                          NOT NULL,
    NomePosto        NVARCHAR(80)                 NOT NULL,
    PotenciaKw       DECIMAL(6,2)                 NOT NULL,   -- teto, não garantia
    DataInstalacao   DATE                         NOT NULL,
    Ativo            BIT                          NOT NULL  CONSTRAINT DF_Posto_Ativo DEFAULT 1,
    DataDesativacao  DATE                             NULL,

    CONSTRAINT PK_Posto           PRIMARY KEY (IDPosto),
    CONSTRAINT UQ_Posto_Codigo    UNIQUE      (Codigo),
    CONSTRAINT FK_Posto_Concelho  FOREIGN KEY (IDConcelho) REFERENCES Concelho (IDConcelho),
    CONSTRAINT CHK_Posto_Potencia CHECK (PotenciaKw > 0),

    CONSTRAINT CHK_Posto_Desativacao
        CHECK ((Ativo = 1 AND DataDesativacao IS NULL)
            OR (Ativo = 0 AND DataDesativacao IS NOT NULL))
);
GO

CREATE TABLE Cliente (
    IDCliente       INT            IDENTITY(1,1)  NOT NULL,
    Nome            NVARCHAR(100)                 NOT NULL,
    NIF             CHAR(9)                       NOT NULL,
    TipoCliente     NVARCHAR(12)                  NOT NULL,
    DataNascimento  DATE                              NULL,
    Telefone        NVARCHAR(20)                      NULL,
    Email           NVARCHAR(100)                     NULL,
    Ativo           BIT                           NOT NULL  CONSTRAINT DF_Cliente_Ativo DEFAULT 1,

    CONSTRAINT PK_Cliente       PRIMARY KEY (IDCliente),
    CONSTRAINT UQ_Cliente_NIF   UNIQUE      (NIF),
    CONSTRAINT CHK_Cliente_Tipo CHECK (TipoCliente IN ('Particular', 'Empresarial')),

    CONSTRAINT CHK_Cliente_Nascimento
        CHECK ((TipoCliente = 'Particular'  AND DataNascimento IS NOT NULL)
            OR (TipoCliente = 'Empresarial' AND DataNascimento IS NULL))
);
GO

CREATE TABLE Tarifario (
    IDTarifario        INT           IDENTITY(1,1)  NOT NULL,
    Nome               NVARCHAR(40)                 NOT NULL,
    Comercializado     BIT                          NOT NULL  CONSTRAINT DF_Tarifario_Comerc DEFAULT 1,
    PrecoKwhAtual      DECIMAL(8,4)                     NULL,   -- cópia; NULL = sem preço em vigor
    TaxaAtivacaoAtual  DECIMAL(8,2)                     NULL,   -- cópia

    CONSTRAINT PK_Tarifario       PRIMARY KEY (IDTarifario),
    CONSTRAINT UQ_Tarifario_Nome  UNIQUE      (Nome),
    CONSTRAINT CHK_Tarifario_Preco CHECK (PrecoKwhAtual IS NULL OR PrecoKwhAtual > 0),
    CONSTRAINT CHK_Tarifario_Taxa  CHECK (TaxaAtivacaoAtual IS NULL OR TaxaAtivacaoAtual >= 0)
);
GO


CREATE TABLE PostoConector (
    IDPostoConector  INT  IDENTITY(1,1)  NOT NULL,
    IDPosto          INT                 NOT NULL,
    IDTipoConector   INT                 NOT NULL,

    CONSTRAINT PK_PostoConector       PRIMARY KEY (IDPostoConector),
    CONSTRAINT UQ_PostoConector_Par   UNIQUE      (IDPosto, IDTipoConector),
    CONSTRAINT FK_PostoConector_Posto FOREIGN KEY (IDPosto)        REFERENCES Posto (IDPosto),
    CONSTRAINT FK_PostoConector_Tipo  FOREIGN KEY (IDTipoConector) REFERENCES TipoConector (IDTipoConector)
);
GO

CREATE TABLE Veiculo (
    IDVeiculo   INT           IDENTITY(1,1)  NOT NULL,
    IDCliente   INT                          NOT NULL,   -- papel 'titular'
    Matricula   NVARCHAR(10)                 NOT NULL,
    Marca       NVARCHAR(40)                     NULL,
    Modelo      NVARCHAR(40)                     NULL,

    CONSTRAINT PK_Veiculo           PRIMARY KEY (IDVeiculo),
    CONSTRAINT UQ_Veiculo_Matricula UNIQUE      (Matricula),
    CONSTRAINT FK_Veiculo_Cliente   FOREIGN KEY (IDCliente) REFERENCES Cliente (IDCliente)
);
GO

CREATE TABLE TarifarioPreco (
    IDTarifarioPreco  INT           IDENTITY(1,1)  NOT NULL,
    IDTarifario       INT                          NOT NULL,
    DataInicio        DATE                         NOT NULL,
    DataFim           DATE                             NULL,
    PrecoKwh          DECIMAL(8,4)                 NOT NULL,
    TaxaAtivacao      DECIMAL(8,2)                 NOT NULL  CONSTRAINT DF_TarifPreco_Taxa DEFAULT 0,

    CONSTRAINT PK_TarifarioPreco       PRIMARY KEY (IDTarifarioPreco),
    CONSTRAINT FK_TarifPreco_Tarifario FOREIGN KEY (IDTarifario) REFERENCES Tarifario (IDTarifario),
    CONSTRAINT UQ_TarifPreco_Vigencia  UNIQUE      (IDTarifario, DataInicio),
    CONSTRAINT CHK_TarifPreco_Preco    CHECK (PrecoKwh > 0),
    CONSTRAINT CHK_TarifPreco_Taxa     CHECK (TaxaAtivacao >= 0),

    CONSTRAINT CHK_TarifPreco_Datas    CHECK (DataFim IS NULL OR DataFim >= DataInicio)
);
GO

CREATE TABLE Reserva (
    IDReserva       INT           IDENTITY(1,1)  NOT NULL,
    IDCliente       INT                          NOT NULL,
    IDPosto         INT                          NOT NULL,
    DataHoraInicio  DATETIME2(0)                 NOT NULL, -- o (zero) arredonda os segundos
    DataHoraFim     DATETIME2(0)                 NOT NULL,
    Estado          NVARCHAR(12)                 NOT NULL  CONSTRAINT DF_Reserva_Estado  DEFAULT 'Ativa',
    DataCriacao     DATETIME2(0)                 NOT NULL  CONSTRAINT DF_Reserva_Criacao DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Reserva          PRIMARY KEY (IDReserva),
    CONSTRAINT FK_Reserva_Cliente  FOREIGN KEY (IDCliente) REFERENCES Cliente (IDCliente),
    CONSTRAINT FK_Reserva_Posto    FOREIGN KEY (IDPosto)   REFERENCES Posto (IDPosto),
    CONSTRAINT CHK_Reserva_Estado  CHECK (Estado IN ('Ativa', 'Concretizada', 'Cancelada', 'Expirada')),
    CONSTRAINT CHK_Reserva_Periodo CHECK (DataHoraFim > DataHoraInicio)
);
GO

CREATE TABLE Ocorrencia (
    IDOcorrencia      INT            IDENTITY(1,1)  NOT NULL,
    IDPosto           INT                           NOT NULL,
    IDTipoAvaria      INT                           NOT NULL,
    DataAbertura      DATETIME2(0)                  NOT NULL,
    Descricao         NVARCHAR(400)                     NULL,   -- o caso concreto
    CustoIntervencao  DECIMAL(9,2)                      NULL,   -- só se sabe na resolução
    Estado            NVARCHAR(15)                  NOT NULL  CONSTRAINT DF_Ocorrencia_Estado DEFAULT 'Aberta',

    CONSTRAINT PK_Ocorrencia         PRIMARY KEY (IDOcorrencia),
    CONSTRAINT FK_Ocorrencia_Posto   FOREIGN KEY (IDPosto)      REFERENCES Posto (IDPosto),
    CONSTRAINT FK_Ocorrencia_Tipo    FOREIGN KEY (IDTipoAvaria) REFERENCES TipoAvaria (IDTipoAvaria),
    CONSTRAINT CHK_Ocorrencia_Estado CHECK (Estado IN ('Aberta', 'EmResolucao', 'Resolvida')),
    CONSTRAINT CHK_Ocorrencia_Custo  CHECK (CustoIntervencao IS NULL OR CustoIntervencao >= 0)
);
GO


CREATE TABLE Fatura (
    IDFatura          INT           IDENTITY(1,1)  NOT NULL,
    Numero            NVARCHAR(20)                 NOT NULL,   -- 'FT2026/0001'
    IDClientePagador  INT                          NOT NULL,   -- papel 'entidade pagadora'
    DataEmissao       DATE                         NOT NULL,
    DataVencimento    DATE                         NOT NULL,
    Metodo            NVARCHAR(12)                 NOT NULL,   -- periodicidade (3.6)
    Estado            NVARCHAR(12)                 NOT NULL  CONSTRAINT DF_Fatura_Estado DEFAULT 'Emitida',

    CONSTRAINT PK_Fatura         PRIMARY KEY (IDFatura),
    CONSTRAINT UQ_Fatura_Numero  UNIQUE      (Numero),
    CONSTRAINT FK_Fatura_Cliente FOREIGN KEY (IDClientePagador) REFERENCES Cliente (IDCliente),
    CONSTRAINT CHK_Fatura_Metodo CHECK (Metodo IN ('Imediato', 'Mensal')),
    CONSTRAINT CHK_Fatura_Estado CHECK (Estado IN ('Emitida', 'Paga', 'Anulada')),
    CONSTRAINT CHK_Fatura_Datas  CHECK (DataVencimento >= DataEmissao)
);
GO

CREATE TABLE Pagamento (
    IDPagamento    INT           IDENTITY(1,1)  NOT NULL,
    IDFatura       INT                          NOT NULL,
    Valor          DECIMAL(9,2)                 NOT NULL,
    DataPagamento  DATE                         NOT NULL,
    MeioPagamento  NVARCHAR(20)                     NULL,   -- 'MB Way', 'Cartão', ...

    CONSTRAINT PK_Pagamento      PRIMARY KEY (IDPagamento),
    CONSTRAINT FK_Pag_Fatura     FOREIGN KEY (IDFatura) REFERENCES Fatura (IDFatura),
    CONSTRAINT CHK_Pag_Valor     CHECK (Valor > 0)
);
GO


CREATE TABLE Carregamento (
    IDCarregamento     INT            IDENTITY(1,1)  NOT NULL,
    IDPostoConector    INT                           NOT NULL,   -- a tomada usada
    IDClienteCondutor  INT                           NOT NULL,   -- papel 'condutor'
    IDVeiculo          INT                           NOT NULL,
    IDTarifario        INT                           NOT NULL,
    IDReserva          INT                               NULL,   -- NULL = espontâneo (3.4)
    IDFatura           INT                               NULL,   -- NULL = ainda não faturado
    DataHoraInicio     DATETIME2(0)                  NOT NULL,
    DataHoraFim        DATETIME2(0)                      NULL,   -- NULL enquanto em curso
    EnergiaKwh         DECIMAL(8,3)                      NULL,
    CustoTotal         DECIMAL(9,2)                      NULL,
    Estado             NVARCHAR(10)                  NOT NULL  CONSTRAINT DF_Carreg_Estado DEFAULT 'EmCurso',

    CONSTRAINT PK_Carregamento         PRIMARY KEY (IDCarregamento),
    CONSTRAINT FK_Carreg_PostoConector FOREIGN KEY (IDPostoConector)   REFERENCES PostoConector (IDPostoConector),
    CONSTRAINT FK_Carreg_Condutor      FOREIGN KEY (IDClienteCondutor) REFERENCES Cliente (IDCliente),
    CONSTRAINT FK_Carreg_Veiculo       FOREIGN KEY (IDVeiculo)         REFERENCES Veiculo (IDVeiculo),
    CONSTRAINT FK_Carreg_Tarifario     FOREIGN KEY (IDTarifario)       REFERENCES Tarifario (IDTarifario),
    CONSTRAINT FK_Carreg_Reserva       FOREIGN KEY (IDReserva)         REFERENCES Reserva (IDReserva),
    CONSTRAINT FK_Carreg_Fatura        FOREIGN KEY (IDFatura)          REFERENCES Fatura (IDFatura),

    CONSTRAINT CHK_Carreg_Estado  CHECK (Estado IN ('EmCurso', 'Terminado', 'Faturado', 'Anulado')),
    CONSTRAINT CHK_Carreg_Energia CHECK (EnergiaKwh IS NULL OR EnergiaKwh >= 0),
    CONSTRAINT CHK_Carreg_Custo   CHECK (CustoTotal IS NULL OR CustoTotal >= 0),
    CONSTRAINT CHK_Carreg_Datas   CHECK (DataHoraFim IS NULL OR DataHoraFim >= DataHoraInicio),

    CONSTRAINT CHK_Carreg_Faturado
        CHECK ((Estado =  'Faturado' AND IDFatura IS NOT NULL)
            OR (Estado <> 'Faturado' AND IDFatura IS NULL))
);
GO


CREATE TABLE CarregamentoHistorico (
    IDCarregamentoHistorico  INT            IDENTITY(1,1)  NOT NULL,
    IDCarregamento           INT                           NOT NULL,
    DataHora                 DATETIME2(0)                  NOT NULL  CONSTRAINT DF_CarregHist_DataHora DEFAULT SYSDATETIME(),
    EstadoNovo               NVARCHAR(10)                  NOT NULL,

    CONSTRAINT PK_CarregamentoHistorico PRIMARY KEY (IDCarregamentoHistorico),
    CONSTRAINT FK_CarregHist_Carreg     FOREIGN KEY (IDCarregamento) REFERENCES Carregamento (IDCarregamento),
    CONSTRAINT CHK_CarregHist_Novo      CHECK (EstadoNovo IN ('EmCurso','Terminado','Faturado','Anulado'))
);
GO


CREATE TABLE Alerta (
    IDAlerta         INT            IDENTITY(1,1)  NOT NULL,
    IDCarregamento   INT                           NOT NULL,
    DataDetecao      DATETIME2(0)                  NOT NULL  CONSTRAINT DF_Alerta_Data DEFAULT SYSDATETIME(),
    EnergiaRegistada DECIMAL(8,3)                  NOT NULL,   -- o que veio no carregamento
    EnergiaMaxima    DECIMAL(8,3)                  NOT NULL,   -- potência x horas, congelado
    Estado           NVARCHAR(12)                  NOT NULL  CONSTRAINT DF_Alerta_Estado DEFAULT 'Aberto',

    CONSTRAINT PK_Alerta        PRIMARY KEY (IDAlerta),
    CONSTRAINT FK_Alerta_Carreg FOREIGN KEY (IDCarregamento) REFERENCES Carregamento (IDCarregamento),
    CONSTRAINT CHK_Alerta_Estado CHECK (Estado IN ('Aberto', 'Justificado', 'Confirmado')),
    CONSTRAINT CHK_Alerta_Valores CHECK (EnergiaRegistada >= 0 AND EnergiaMaxima >= 0)
);
GO


CREATE UNIQUE INDEX UQ_Carreg_Reserva
    ON Carregamento (IDReserva)
    WHERE IDReserva IS NOT NULL;
GO

CREATE UNIQUE INDEX UQ_TarifPreco_EmVigor
    ON TarifarioPreco (IDTarifario)
    WHERE DataFim IS NULL;
GO


CREATE VIEW dbo.vw_PostosAtivos
AS
SELECT p.Codigo,
       p.NomePosto,
       c.Nome AS Concelho,
       p.PotenciaKw,
       p.DataInstalacao
FROM   Posto p
       INNER JOIN Concelho c ON c.IDConcelho = p.IDConcelho
WHERE  p.Ativo = 1;
GO


SELECT TABLE_NAME AS Tabela
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO
