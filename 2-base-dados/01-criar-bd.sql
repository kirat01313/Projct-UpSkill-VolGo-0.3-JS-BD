/* ============================================================
   VoltGo — 01 — Criação da base de dados          SQL Server
   ============================================================
   Ordem: 01 -> 02 -> 03 -> 04.
   As justificações de cada decisão estão no documento de estudo
   e no VoltGo-GuiaModelacao-v2.docx.

   Ordem de criação = ordem das dependências:
     catálogos -> entidades base -> dependentes -> Carregamento -> filhas

   Nomes: PK_ FK_ UQ_ CHK_ DF_
   Sem CASCADE em lado nenhum: a regra 3.8 proíbe remoção física.
   ============================================================ */

CREATE DATABASE VoltGo;
GO

USE VoltGo;
GO


/* ============================================================
   1. CATÁLOGOS
   ============================================================ */

/* Entidade e não texto no Posto: o relatório 6 agrupa por concelho. */
CREATE TABLE Concelho (
    IDConcelho  INT           IDENTITY(1,1)  NOT NULL,
    Nome        NVARCHAR(60)                 NOT NULL,

    CONSTRAINT PK_Concelho      PRIMARY KEY (IDConcelho),
    CONSTRAINT UQ_Concelho_Nome UNIQUE      (Nome)
);
GO


/* Catálogo próprio: o relatório 1 exige listar tipos SEM carregamentos. */
CREATE TABLE TipoConector (
    IDTipoConector  INT           IDENTITY(1,1)  NOT NULL,
    Designacao      NVARCHAR(40)                 NOT NULL,   -- 'Type 2', 'CCS2', 'CHAdeMO'

    CONSTRAINT PK_TipoConector       PRIMARY KEY (IDTipoConector),
    CONSTRAINT UQ_TipoConector_Desig UNIQUE      (Designacao)
);
GO


/* Regra 3.7. Catálogo evita texto livre inconsistente nas análises. */
CREATE TABLE TipoAvaria (
    IDTipoAvaria  INT           IDENTITY(1,1)  NOT NULL,
    Designacao    NVARCHAR(60)                 NOT NULL,

    CONSTRAINT PK_TipoAvaria       PRIMARY KEY (IDTipoAvaria),
    CONSTRAINT UQ_TipoAvaria_Desig UNIQUE      (Designacao)
);
GO


/* ============================================================
   2. ENTIDADES BASE
   ============================================================ */

/* Regra 3.1. Ativo + DataDesativacao = remoção lógica (3.8). */
CREATE TABLE Posto (
    IDPosto          INT           IDENTITY(1,1)  NOT NULL,
    IDConcelho       INT                          NOT NULL,
    Designacao       NVARCHAR(80)                 NOT NULL,
    PotenciaKw       DECIMAL(6,2)                 NOT NULL,   -- potência máxima, não garantida
    DataInstalacao   DATE                         NOT NULL,
    Ativo            BIT                          NOT NULL  CONSTRAINT DF_Posto_Ativo DEFAULT 1,
    DataDesativacao  DATE                             NULL,

    CONSTRAINT PK_Posto           PRIMARY KEY (IDPosto),
    CONSTRAINT FK_Posto_Concelho  FOREIGN KEY (IDConcelho) REFERENCES Concelho (IDConcelho),
    CONSTRAINT CHK_Posto_Potencia CHECK (PotenciaKw > 0),

    -- impede as duas colunas de se contradizerem
    CONSTRAINT CHK_Posto_Desativacao
        CHECK ((Ativo = 1 AND DataDesativacao IS NULL)
            OR (Ativo = 0 AND DataDesativacao IS NOT NULL))
);
GO


/* Regra 3.3. Os papéis não são colunas: são o lugar onde o cliente aparece
   (Veiculo.IDCliente, Carregamento.IDCliente, Pagamento.IDClientePagador). */
CREATE TABLE Cliente (
    IDCliente       INT            IDENTITY(1,1)  NOT NULL,
    Nome            NVARCHAR(100)                 NOT NULL,
    NIF             CHAR(9)                       NOT NULL,    
    TipoCliente     NVARCHAR(12)                  NOT NULL,
    DataNascimento  DATE                              NULL,
    Email           NVARCHAR(100)                     NULL,
    Ativo           BIT                           NOT NULL  CONSTRAINT DF_Cliente_Ativo DEFAULT 1,

    CONSTRAINT PK_Cliente       PRIMARY KEY (IDCliente),
    CONSTRAINT UQ_Cliente_NIF   UNIQUE      (NIF),
    CONSTRAINT CHK_Cliente_Tipo CHECK (TipoCliente IN ('Particular', 'Empresarial')),

    -- obrigatória nos particulares (regra 3.3, análises demográficas), proibida nas empresas
    CONSTRAINT CHK_Cliente_Nascimento
        CHECK ((TipoCliente = 'Particular'  AND DataNascimento IS NOT NULL)
            OR (TipoCliente = 'Empresarial' AND DataNascimento IS NULL))
);
GO


/* Regra 3.2. O preço não está aqui: varia no tempo, vive na TarifarioPreco. */
CREATE TABLE Tarifario (
    IDTarifario     INT           IDENTITY(1,1)  NOT NULL,
    Nome            NVARCHAR(40)                 NOT NULL,
    Comercializado  BIT                          NOT NULL  CONSTRAINT DF_Tarifario_Comerc DEFAULT 1,

    CONSTRAINT PK_Tarifario      PRIMARY KEY (IDTarifario),
    CONSTRAINT UQ_Tarifario_Nome UNIQUE      (Nome)
);
GO


/* ============================================================
   3. DEPENDENTES
   ============================================================ */

/* Junção N:M (regra 3.1). PK composta: o que é único é o par.
   Cada linha representa, na prática, uma tomada. */
CREATE TABLE PostoConector (
    IDPosto         INT  NOT NULL,
    IDTipoConector  INT  NOT NULL,

    CONSTRAINT PK_PostoConector       PRIMARY KEY (IDPosto, IDTipoConector),
    CONSTRAINT FK_PostoConector_Posto FOREIGN KEY (IDPosto)        REFERENCES Posto (IDPosto),
    CONSTRAINT FK_PostoConector_Tipo  FOREIGN KEY (IDTipoConector) REFERENCES TipoConector (IDTipoConector)
);
GO


/* Regra 3.3: um cliente tem vários veículos. A FK vive no lado N. */
CREATE TABLE Veiculo (
    IDVeiculo   INT           IDENTITY(1,1)  NOT NULL,
    IDCliente   INT                          NOT NULL,   -- papel 'titular'
    Matricula   NVARCHAR(10)                 NOT NULL,
    Marca       NVARCHAR(40)                     NULL,
    Modelo      NVARCHAR(40)                     NULL,
    Ativo       BIT                          NOT NULL  CONSTRAINT DF_Veiculo_Ativo DEFAULT 1,

    CONSTRAINT PK_Veiculo           PRIMARY KEY (IDVeiculo),
    CONSTRAINT FK_Veiculo_Cliente   FOREIGN KEY (IDCliente) REFERENCES Cliente (IDCliente),
    CONSTRAINT UQ_Veiculo_Matricula UNIQUE      (Matricula)
);
GO


/* Regra 3.2: o preço depende do tarifário E do momento.
   DataFim NULL = vigência em vigor. */
CREATE TABLE TarifarioPreco (
    IDTarifarioPreco  INT           IDENTITY(1,1)  NOT NULL,
    IDTarifario       INT                          NOT NULL,
    DataInicio        DATE                         NOT NULL,
    DataFim           DATE                             NULL,
    PrecoKwh          DECIMAL(8,4)                 NOT NULL,
    TaxaAtivacao      DECIMAL(8,2)                 NOT NULL  CONSTRAINT DF_TarifPreco_Taxa DEFAULT 0,

    CONSTRAINT PK_TarifarioPreco       PRIMARY KEY (IDTarifarioPreco),
    CONSTRAINT FK_TarifPreco_Tarifario FOREIGN KEY (IDTarifario) REFERENCES Tarifario (IDTarifario),
    CONSTRAINT CHK_TarifPreco_Preco    CHECK (PrecoKwh > 0),
    CONSTRAINT UQ_TarifPreco_Vigencia  UNIQUE (IDTarifario, DataInicio),
    CONSTRAINT CHK_TarifPreco_Datas    CHECK (DataFim IS NULL OR DataFim > DataInicio)
);
GO


/* Regra 3.4. Entidade própria e não junção: tem dados seus, e o mesmo
   cliente pode reservar o mesmo posto muitas vezes. */
CREATE TABLE Reserva (
    IDReserva       INT           IDENTITY(1,1)  NOT NULL,
    IDCliente       INT                          NOT NULL,
    IDPosto         INT                          NOT NULL,
    DataHoraInicio  DATETIME2(0)                 NOT NULL,
    DataHoraFim     DATETIME2(0)                 NOT NULL,
    Estado          NVARCHAR(12)                 NOT NULL  CONSTRAINT DF_Reserva_Estado DEFAULT 'Ativa',
    DataCriacao     DATETIME2(0)                 NOT NULL  CONSTRAINT DF_Reserva_Criacao DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Reserva          PRIMARY KEY (IDReserva),
    CONSTRAINT FK_Reserva_Cliente  FOREIGN KEY (IDCliente) REFERENCES Cliente (IDCliente),
    CONSTRAINT FK_Reserva_Posto    FOREIGN KEY (IDPosto)   REFERENCES Posto (IDPosto),
    CONSTRAINT CHK_Reserva_Estado  CHECK (Estado IN ('Ativa', 'Concretizada', 'Cancelada', 'Expirada')),
    CONSTRAINT CHK_Reserva_Periodo CHECK (DataHoraFim > DataHoraInicio),

    -- redundante (IDReserva já é único), mas necessária: uma FK só aponta
    -- para uma chave, e o Carregamento vai apontar para este par
    CONSTRAINT UQ_Reserva_Posto    UNIQUE (IDReserva, IDPosto)
);
GO


/* Regra 3.7. Sem DataResolucao: essa data está no OcorrenciaHistorico. */
CREATE TABLE Ocorrencia (
    IDOcorrencia      INT            IDENTITY(1,1)  NOT NULL,
    IDPosto           INT                           NOT NULL,
    IDTipoAvaria      INT                           NOT NULL,
    DataAbertura      DATETIME2(0)                  NOT NULL,
    Descricao         NVARCHAR(400)                     NULL,
    CustoIntervencao  DECIMAL(9,2)                      NULL,   -- NULL até à resolução
    Estado            NVARCHAR(15)                  NOT NULL  CONSTRAINT DF_Ocorrencia_Estado DEFAULT 'Aberta',

    CONSTRAINT PK_Ocorrencia         PRIMARY KEY (IDOcorrencia),
    CONSTRAINT FK_Ocorrencia_Posto   FOREIGN KEY (IDPosto)      REFERENCES Posto (IDPosto),
    CONSTRAINT FK_Ocorrencia_Tipo    FOREIGN KEY (IDTipoAvaria) REFERENCES TipoAvaria (IDTipoAvaria),
    CONSTRAINT CHK_Ocorrencia_Estado CHECK (Estado IN ('Aberta', 'EmResolucao', 'Resolvida')),
    CONSTRAINT CHK_Ocorrencia_Custo  CHECK (CustoIntervencao IS NULL OR CustoIntervencao >= 0)
);
GO


/* ============================================================
   4. CENTRAL — Carregamento
   ============================================================
   Regra 3.5. Aponta para seis tabelas, daí ser das últimas.
   CustoTotal é gravado (e não calculado) para congelar o valor
   faturado — exceção declarada à regra do atributo derivado.
   ------------------------------------------------------------ */

CREATE TABLE Carregamento (
    IDCarregamento  INT            IDENTITY(1,1)  NOT NULL,
    IDPosto         INT                           NOT NULL,
    IDTipoConector  INT                           NOT NULL,
    IDCliente       INT                           NOT NULL,   -- papel 'condutor'
    IDVeiculo       INT                           NOT NULL,
    IDTarifario     INT                           NOT NULL,
    IDReserva       INT                               NULL,   -- NULL = espontâneo (3.4)
    DataHoraInicio  DATETIME2(0)                  NOT NULL,
    DataHoraFim     DATETIME2(0)                      NULL,   -- NULL enquanto em curso
    EnergiaKwh      DECIMAL(8,3)                      NULL,
    CustoTotal      DECIMAL(9,2)                      NULL,
    Estado          NVARCHAR(10)                  NOT NULL  CONSTRAINT DF_Carreg_Estado DEFAULT 'EmCurso',

    CONSTRAINT PK_Carregamento     PRIMARY KEY (IDCarregamento),
    CONSTRAINT FK_Carreg_Posto     FOREIGN KEY (IDPosto)     REFERENCES Posto (IDPosto),
    CONSTRAINT FK_Carreg_Cliente   FOREIGN KEY (IDCliente)   REFERENCES Cliente (IDCliente),
    CONSTRAINT FK_Carreg_Veiculo   FOREIGN KEY (IDVeiculo)   REFERENCES Veiculo (IDVeiculo),
    CONSTRAINT FK_Carreg_Tarifario FOREIGN KEY (IDTarifario) REFERENCES Tarifario (IDTarifario),

    -- FK composta: o conector tem de existir NAQUELE posto, e não só no catálogo
    CONSTRAINT FK_Carreg_PostoConector FOREIGN KEY (IDPosto, IDTipoConector)
                                       REFERENCES PostoConector (IDPosto, IDTipoConector),

    -- FK composta: o carregamento tem de acontecer no posto reservado.
    -- Com IDReserva NULL a verificação não se aplica — é o que permite os espontâneos.
    CONSTRAINT FK_Carreg_Reserva_Posto FOREIGN KEY (IDReserva, IDPosto)
                                       REFERENCES Reserva (IDReserva, IDPosto),

    CONSTRAINT CHK_Carreg_Estado  CHECK (Estado IN ('EmCurso', 'Terminado', 'Faturado', 'Anulado')),
    CONSTRAINT CHK_Carreg_Energia CHECK (EnergiaKwh IS NULL OR EnergiaKwh >= 0),
    CONSTRAINT CHK_Carreg_Custo   CHECK (CustoTotal IS NULL OR CustoTotal >= 0),
    CONSTRAINT CHK_Carreg_Datas   CHECK (DataHoraFim IS NULL OR DataHoraFim >= DataHoraInicio)
);
GO


/* ============================================================
   5. FILHAS
   ============================================================ */

/* Regra 3.6. 1:N com Carregamento (o relatório 5 conta pagamentos).
   Sem coluna de estado: pago = DataPagamento preenchida;
   em dívida = vencido e por pagar. */
CREATE TABLE Pagamento (
    IDPagamento       INT           IDENTITY(1,1)  NOT NULL,
    IDCarregamento    INT                          NOT NULL,
    IDClientePagador  INT                          NOT NULL,   -- papel 'pagador'; pode diferir do condutor
    Valor             DECIMAL(9,2)                 NOT NULL,
    Metodo            NVARCHAR(12)                 NOT NULL,
    DataEmissao       DATE                         NOT NULL,
    DataVencimento    DATE                         NOT NULL,
    DataPagamento     DATE                             NULL,   -- NULL = por pagar

    CONSTRAINT PK_Pagamento          PRIMARY KEY (IDPagamento),
    CONSTRAINT FK_Pag_Carregamento   FOREIGN KEY (IDCarregamento)   REFERENCES Carregamento (IDCarregamento),
    CONSTRAINT FK_Pag_ClientePagador FOREIGN KEY (IDClientePagador) REFERENCES Cliente (IDCliente),
    CONSTRAINT CHK_Pag_Valor         CHECK (Valor > 0),
    CONSTRAINT CHK_Pag_Metodo        CHECK (Metodo IN ('Imediato', 'Mensal')),
    CONSTRAINT CHK_Pag_Datas         CHECK (DataVencimento >= DataEmissao)
);
GO


/* Regras 3.5 e 3.8. Uma linha por transição de estado; nada se reescreve.
   EstadoAnterior é NULL na criação. */
CREATE TABLE CarregamentoHistorico (
    IDCarregamentoHistorico  INT            IDENTITY(1,1)  NOT NULL,
    IDCarregamento           INT                           NOT NULL,
    DataHora                 DATETIME2(0)                  NOT NULL  CONSTRAINT DF_CarregHist_DataHora DEFAULT SYSDATETIME(),
    EstadoAnterior           NVARCHAR(10)                      NULL,
    EstadoNovo               NVARCHAR(10)                  NOT NULL,
    Observacao               NVARCHAR(200)                     NULL,

    CONSTRAINT PK_CarregamentoHistorico PRIMARY KEY (IDCarregamentoHistorico),
    CONSTRAINT FK_CarregHist_Carreg     FOREIGN KEY (IDCarregamento) REFERENCES Carregamento (IDCarregamento),
    CONSTRAINT CHK_CarregHist_Anterior  CHECK (EstadoAnterior IS NULL OR EstadoAnterior IN ('EmCurso', 'Terminado', 'Faturado', 'Anulado')),
    CONSTRAINT CHK_CarregHist_Novo      CHECK (EstadoNovo IN ('EmCurso', 'Terminado', 'Faturado', 'Anulado'))
);
GO


/* Regras 3.7 e 3.8. É aqui que está a data de resolução de cada ocorrência:
   a linha com EstadoNovo = 'Resolvida'. */
CREATE TABLE OcorrenciaHistorico (
    IDOcorrenciaHistorico  INT            IDENTITY(1,1)  NOT NULL,
    IDOcorrencia           INT                           NOT NULL,
    DataHora               DATETIME2(0)                  NOT NULL  CONSTRAINT DF_OcorrHist_DataHora DEFAULT SYSDATETIME(),
    EstadoNovo             NVARCHAR(15)                  NOT NULL,
    Observacao             NVARCHAR(200)                     NULL,

    CONSTRAINT PK_OcorrenciaHistorico  PRIMARY KEY (IDOcorrenciaHistorico),
    CONSTRAINT FK_OcorrHist_Ocorrencia FOREIGN KEY (IDOcorrencia) REFERENCES Ocorrencia (IDOcorrencia),
    CONSTRAINT CHK_OcorrHist_Estado    CHECK (EstadoNovo IN ('Aberta', 'EmResolucao', 'Resolvida'))
);
GO


/* ============================================================
   6. ÍNDICES ÚNICOS FILTRADOS
   ============================================================
   O WHERE é o que permite ter muitos NULL sem o UNIQUE se queixar.

   O SET abaixo é obrigatório: o SSMS liga-o por omissão, o sqlcmd não,
   e sem ele os dois CREATE INDEX falham.
   ------------------------------------------------------------ */

SET QUOTED_IDENTIFIER ON;
GO

/* Uma reserva concretiza no máximo um carregamento (1:0..1). */
CREATE UNIQUE INDEX UQ_Carreg_Reserva
    ON Carregamento (IDReserva)
    WHERE IDReserva IS NOT NULL;
GO

/* Cada tarifário tem no máximo um preço em vigor.
   Sobreposição entre vigências fechadas fica por cobrir: exigiria TRIGGER. */
CREATE UNIQUE INDEX UQ_TarifPreco_EmVigor
    ON TarifarioPreco (IDTarifario)
    WHERE DataFim IS NULL;
GO


/* ------------------------------------------------------------
   Recomeçar do zero:

     USE master;
     ALTER DATABASE VoltGo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
     DROP DATABASE VoltGo;
   ------------------------------------------------------------ */
