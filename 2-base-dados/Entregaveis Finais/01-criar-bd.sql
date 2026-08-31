/* ============================================================================
   VoltGo — 01 — Criação da base de dados                          SQL Server
   ============================================================================
   Trabalho Prático de Bases de Dados · UpSkill/IPCA · Fred & Tarik

   Ordem de execução:  01 → 02 → 03 → 04 → 05 → 06 → 07

   ORDEM DE CRIAÇÃO = ORDEM DAS DEPENDÊNCIAS
       catálogos → entidades base → dependentes → Carregamento → filhas
   Uma tabela só pode nascer depois daquelas para onde ela aponta, senão a
   chave estrangeira não tem para onde apontar.

   CONVENÇÃO DE NOMES
       PK_   chave primária          FK_   chave estrangeira
       UQ_   chave alternativa       CHK_  restrição de domínio
       DF_   valor por omissão       TR_   trigger
   Todas as restrições têm nome próprio: sem ele, o SQL Server inventa algo
   como UQ__Concelho__72E12F1B, que torna as mensagens de erro ilegíveis e
   impossível apagar a restrição sem a ir descobrir primeiro.

   SEM CASCADE EM LADO NENHUM
   A regra 3.8 proíbe a remoção física de dados. Uma remoção em cascata é
   exatamente isso, feita automaticamente — seria o contrário do que se pede.
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

/* Obrigatório para os índices únicos filtrados do fim do script.
   O SSMS liga estas opções por omissão; o sqlcmd não. Sem elas, os
   CREATE INDEX falham com "SET options have incorrect settings". */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


/* ############################################################################
   1. CATÁLOGOS
   Listas de valores fixos. Não apontam para ninguém, por isso vêm primeiro.
   ############################################################################ */

/* Entidade e não texto dentro do Posto: o relatório 6 agrupa faturação por
   concelho, e agrupar por texto livre parte-se com o primeiro erro de escrita
   ("Braga" e "braga" seriam dois concelhos). */
CREATE TABLE Concelho (
    IDConcelho  INT           IDENTITY(1,1)  NOT NULL,
    Nome        NVARCHAR(60)                 NOT NULL,

    CONSTRAINT PK_Concelho      PRIMARY KEY (IDConcelho),
    CONSTRAINT UQ_Concelho_Nome UNIQUE      (Nome)
);
GO

/* Catálogo próprio porque o relatório 1 exige listar os tipos de conector
   SEM carregamentos. Um tipo tem de poder existir sem nunca ter sido usado —
   o que é impossível se for apenas uma coluna do posto. */
CREATE TABLE TipoConector (
    IDTipoConector  INT           IDENTITY(1,1)  NOT NULL,
    Designacao      NVARCHAR(40)                 NOT NULL,   -- 'Type 2', 'CCS2', 'CHAdeMO'

    CONSTRAINT PK_TipoConector       PRIMARY KEY (IDTipoConector),
    CONSTRAINT UQ_TipoConector_Desig UNIQUE      (Designacao)
);
GO

/* Regra 3.7: "devem ser registados o tipo de avaria". Catálogo em vez de texto
   livre, para a análise de fiabilidade por tipo ser possível. */
CREATE TABLE TipoAvaria (
    IDTipoAvaria  INT           IDENTITY(1,1)  NOT NULL,
    Designacao    NVARCHAR(60)                 NOT NULL,

    CONSTRAINT PK_TipoAvaria       PRIMARY KEY (IDTipoAvaria),
    CONSTRAINT UQ_TipoAvaria_Desig UNIQUE      (Designacao)
);
GO


/* ############################################################################
   2. ENTIDADES BASE
   ############################################################################ */

/* Regra 3.1. Codigo é chave alternativa: é o identificador de negócio que a
   aplicação da Fase 1 usa em todo o lado ('P001'). A PK continua artificial
   porque um código de negócio pode mudar de formato; um ID nunca muda.

   Ativo + DataDesativacao implementam a remoção lógica da regra 3.8: um posto
   em fim de vida sai de serviço mas continua a segurar todo o histórico de
   carregamentos que fez. */
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

    /* As duas colunas guardam o mesmo facto. Sem isto, "WHERE Ativo = 1" e
       "WHERE DataDesativacao IS NULL" podiam devolver conjuntos diferentes. */
    CONSTRAINT CHK_Posto_Desativacao
        CHECK ((Ativo = 1 AND DataDesativacao IS NULL)
            OR (Ativo = 0 AND DataDesativacao IS NOT NULL))
);
GO

/* Regra 3.3: "uma pessoa ou entidade pode assumir diferentes papéis".
   Os papéis NÃO são uma coluna — exercem-se no lugar onde o cliente aparece:
       Veiculo.IDCliente           → titular
       Carregamento.IDClienteCondutor → condutor
       Fatura.IDClientePagador     → entidade pagadora
   Uma coluna "Papel" não funcionaria: a mesma pessoa é condutora num
   carregamento e pagadora noutro, ao mesmo tempo. */
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

    /* Obrigatória nos particulares (3.3 pede análises demográficas), proibida
       nas empresas (uma empresa não nasce, e uma data inventada contaminaria
       as médias de idade). É uma regra CONDICIONAL: depende de outra coluna,
       por isso não pode ser um NOT NULL. */
    CONSTRAINT CHK_Cliente_Nascimento
        CHECK ((TipoCliente = 'Particular'  AND DataNascimento IS NOT NULL)
            OR (TipoCliente = 'Empresarial' AND DataNascimento IS NULL))
);
GO

/* Regra 3.2. PrecoKwhAtual e TaxaAtivacaoAtual são uma CÓPIA do preço em vigor,
   mantida aqui para simplificar as consultas mais comuns (evita o JOIN com a
   TarifarioPreco sempre que só se quer o preço de hoje).

   É uma desnormalização deliberada. A fonte da verdade continua a ser a
   TarifarioPreco — e a cópia é mantida em sincronia pelo trigger
   TR_TarifarioPreco_SincronizaAtual (script 07). Sem esse trigger, isto seria
   duas versões do mesmo facto à espera de divergirem. */
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


/* ############################################################################
   3. DEPENDENTES
   ############################################################################ */

/* Junção N:M da regra 3.1 ("cada posto tem um ou mais tipos de conector").
   Cada linha representa, na prática, UMA TOMADA física.

   PK artificial e não composta: é para ela que o Carregamento aponta. Com uma
   PK composta (IDPosto, IDTipoConector), o Carregamento teria de repetir as
   duas colunas — e o IDPosto ficaria lá duas vezes, uma pela FK do posto e
   outra pela FK da tomada. A PK artificial elimina essa redundância.
   O par continua único, garantido pela chave alternativa. */
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

/* Regra 3.3: "um cliente pode ter vários veículos". A FK vive no lado dos
   muitos. Marca e Modelo ficam como texto: nenhuma regra nem relatório os usa
   para agrupar, e promovê-los a catálogo seria modelação a mais. */
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

/* Regra 3.2: "as condições de um tarifário podem variar ao longo do tempo".
   O preço não depende só do tarifário — depende do tarifário E do período.
   DataFim NULL = vigência em vigor.

   Se o preço vivesse apenas dentro do Tarifario, cada atualização apagaria o
   passado e as faturas antigas deixariam de ser explicáveis. */
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

    /* >= e não >: DataFim é o último dia INCLUSIVE, por isso uma vigência que
       durou um único dia é válida. Acontece sempre que um preço é substituído
       no dia seguinte ao de entrada em vigor. */
    CONSTRAINT CHK_TarifPreco_Datas    CHECK (DataFim IS NULL OR DataFim >= DataInicio)
);
GO

/* Regra 3.4. Entidade própria e não tabela de junção: tem dados seus (período,
   estado) e o mesmo cliente pode reservar o mesmo posto muitas vezes — o que
   uma PK (IDCliente, IDPosto) tornaria impossível. */
CREATE TABLE Reserva (
    IDReserva       INT           IDENTITY(1,1)  NOT NULL,
    IDCliente       INT                          NOT NULL,
    IDPosto         INT                          NOT NULL,
    DataHoraInicio  DATETIME2(0)                 NOT NULL,
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

/* Regra 3.7. Sem coluna DataResolucao: essa data está no OcorrenciaHistorico,
   na linha em que o estado passou a 'Resolvida'. Duplicá-la aqui criaria duas
   versões do mesmo facto. */
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


/* ############################################################################
   4. FATURAÇÃO
   ############################################################################
   Regra 3.6: "diferentes formas e periodicidades (imediato, mensal para
   clientes empresariais)".

   Uma fatura mensal cobre DEZENAS de carregamentos. Sem esta entidade, um
   pagamento só conseguia apontar para um carregamento de cada vez, e a
   periodicidade mensal era impossível de representar.

   Separa três conceitos que estavam colados:
       o consumo    → Carregamento
       a dívida     → Fatura
       a liquidação → Pagamento
   ############################################################################ */

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

/* Regra 3.6. Uma fatura pode ser liquidada em VÁRIAS prestações — daí ser 1:N.
   DataPagamento é NOT NULL: uma linha aqui significa dinheiro recebido.
   O "por pagar" e o "em atraso" não são colunas — derivam-se da fatura:
       em dívida = Fatura.Estado 'Emitida' com pagamentos a somar menos que o total
       em atraso = o mesmo, e DataVencimento já passada */
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


/* ############################################################################
   5. CENTRAL — Carregamento
   ############################################################################
   Regra 3.5. Aponta para cinco tabelas, daí ser das últimas a nascer.

   IDPostoConector e não (IDPosto + IDTipoConector): a tomada já identifica o
   posto. Guardar o posto outra vez seria repetir um facto que a PostoConector
   já garante — e abria a porta a que as duas versões se contradissessem.

   CustoTotal é GRAVADO e não calculado. É a única exceção assumida à regra do
   atributo derivado: uma fatura emitida não pode mudar de valor porque o
   tarifário subiu depois. Congela-se no fecho da sessão.

   LIMITAÇÃO ASSUMIDA: sem IDPosto nesta tabela, deixa de se poder garantir por
   chave estrangeira que o carregamento acontece no posto que foi reservado.
   Fica documentado; garanti-lo exigiria um trigger.
   ---------------------------------------------------------------------------- */

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

    /* Coerência entre o estado e a fatura: um carregamento faturado tem de ter
       fatura, e um que não está faturado não pode ter. */
    CONSTRAINT CHK_Carreg_Faturado
        CHECK ((Estado =  'Faturado' AND IDFatura IS NOT NULL)
            OR (Estado <> 'Faturado' AND IDFatura IS NULL))
);
GO


/* ############################################################################
   6. AUDITORIA
   Uma linha por transição de estado. Nunca se reescreve nem se apaga nada:
   acrescenta-se. Um histórico que se pode editar não é um histórico.
   ############################################################################ */

/* Regras 3.5 e 3.8. EstadoAnterior é NULL na primeira linha: antes disso o
   carregamento não existia, logo não tinha estado nenhum. */
CREATE TABLE CarregamentoHistorico (
    IDCarregamentoHistorico  INT            IDENTITY(1,1)  NOT NULL,
    IDCarregamento           INT                           NOT NULL,
    DataHora                 DATETIME2(0)                  NOT NULL  CONSTRAINT DF_CarregHist_DataHora DEFAULT SYSDATETIME(),
    EstadoAnterior           NVARCHAR(10)                      NULL,
    EstadoNovo               NVARCHAR(10)                  NOT NULL,
    Observacao               NVARCHAR(200)                     NULL,

    CONSTRAINT PK_CarregamentoHistorico PRIMARY KEY (IDCarregamentoHistorico),
    CONSTRAINT FK_CarregHist_Carreg     FOREIGN KEY (IDCarregamento) REFERENCES Carregamento (IDCarregamento),
    CONSTRAINT CHK_CarregHist_Anterior  CHECK (EstadoAnterior IS NULL OR EstadoAnterior IN ('EmCurso','Terminado','Faturado','Anulado')),
    CONSTRAINT CHK_CarregHist_Novo      CHECK (EstadoNovo IN ('EmCurso','Terminado','Faturado','Anulado'))
);
GO

/* Regras 3.7 e 3.8. É aqui que está a data de resolução de cada ocorrência.
   EstadoAnterior existe pelo mesmo motivo do histórico do carregamento: torna
   cada linha legível sozinha ("estava assim, passou a assim"). */
CREATE TABLE OcorrenciaHistorico (
    IDOcorrenciaHistorico  INT            IDENTITY(1,1)  NOT NULL,
    IDOcorrencia           INT                           NOT NULL,
    DataHora               DATETIME2(0)                  NOT NULL  CONSTRAINT DF_OcorrHist_DataHora DEFAULT SYSDATETIME(),
    EstadoAnterior         NVARCHAR(15)                      NULL,
    EstadoNovo             NVARCHAR(15)                  NOT NULL,
    Observacao             NVARCHAR(200)                     NULL,

    CONSTRAINT PK_OcorrenciaHistorico  PRIMARY KEY (IDOcorrenciaHistorico),
    CONSTRAINT FK_OcorrHist_Ocorrencia FOREIGN KEY (IDOcorrencia) REFERENCES Ocorrencia (IDOcorrencia),
    CONSTRAINT CHK_OcorrHist_Anterior  CHECK (EstadoAnterior IS NULL OR EstadoAnterior IN ('Aberta','EmResolucao','Resolvida')),
    CONSTRAINT CHK_OcorrHist_Estado    CHECK (EstadoNovo IN ('Aberta','EmResolucao','Resolvida'))
);
GO


/* ############################################################################
   7. ALERTA — funcionalidade proposta na Parte E
   ############################################################################
   Regista automaticamente os carregamentos em que a energia medida excede o
   que o posto consegue fisicamente debitar no tempo da sessão.

   Porque é uma TABELA e não uma consulta: um alerta tem ciclo de vida próprio
   (alguém o analisa, justifica ou confirma) e o resultado dessa análise tem de
   ficar registado. Uma consulta devolve sempre o mesmo e não guarda nada.

   Os valores são CONGELADOS no momento da deteção. Se a potência do posto for
   corrigida mais tarde, o alerta continua a poder ser explicado — sem isso,
   um alerta antigo passaria a parecer um erro do sistema.
   ---------------------------------------------------------------------------- */

CREATE TABLE Alerta (
    IDAlerta         INT            IDENTITY(1,1)  NOT NULL,
    IDCarregamento   INT                           NOT NULL,
    DataDetecao      DATETIME2(0)                  NOT NULL  CONSTRAINT DF_Alerta_Data DEFAULT SYSDATETIME(),
    TipoAlerta       NVARCHAR(30)                  NOT NULL,
    EnergiaRegistada DECIMAL(8,3)                  NOT NULL,   -- o que veio no carregamento
    EnergiaMaxima    DECIMAL(8,3)                  NOT NULL,   -- potência x horas, congelado
    Estado           NVARCHAR(12)                  NOT NULL  CONSTRAINT DF_Alerta_Estado DEFAULT 'Aberto',
    Observacao       NVARCHAR(300)                     NULL,

    CONSTRAINT PK_Alerta        PRIMARY KEY (IDAlerta),
    CONSTRAINT FK_Alerta_Carreg FOREIGN KEY (IDCarregamento) REFERENCES Carregamento (IDCarregamento),
    CONSTRAINT CHK_Alerta_Tipo  CHECK (TipoAlerta IN ('EnergiaAcimaCapacidade', 'DuracaoImplausivel')),
    CONSTRAINT CHK_Alerta_Estado CHECK (Estado IN ('Aberto', 'Justificado', 'Confirmado')),
    CONSTRAINT CHK_Alerta_Valores CHECK (EnergiaRegistada >= 0 AND EnergiaMaxima >= 0)
);
GO


/* ############################################################################
   8. ÍNDICES ÚNICOS FILTRADOS
   ############################################################################
   O WHERE é o que permite ter muitos NULL sem o UNIQUE se queixar: em SQL
   Server um UNIQUE normal só aceita UM NULL, e aqui precisamos de muitos.
   ############################################################################ */

/* Regra 3.4: uma reserva concretiza no máximo um carregamento (1:0..1).
   Sem o filtro, o segundo carregamento espontâneo (IDReserva NULL) era
   recusado — o que seria absurdo. */
CREATE UNIQUE INDEX UQ_Carreg_Reserva
    ON Carregamento (IDReserva)
    WHERE IDReserva IS NOT NULL;
GO

/* Regra 3.2: cada tarifário tem no máximo UM preço em vigor ao mesmo tempo.
   É isto que garante que a consulta do preço do dia devolve sempre uma linha.

   LIMITAÇÃO ASSUMIDA: a sobreposição entre duas vigências já FECHADAS não é
   detetada — exigiria comparar linhas diferentes, coisa que nem um CHECK nem
   um índice conseguem fazer. Regra de operação: fechar a vigência anterior
   antes de abrir a nova. */
CREATE UNIQUE INDEX UQ_TarifPreco_EmVigor
    ON TarifarioPreco (IDTarifario)
    WHERE DataFim IS NULL;
GO


/* ============================================================================
   CONFERIR — devem aparecer 17 tabelas
   ============================================================================ */
SELECT TABLE_NAME AS Tabela
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO
