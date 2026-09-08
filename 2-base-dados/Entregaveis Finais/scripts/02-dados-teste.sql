/* ============================================================================
   VoltGo — 02 — Dados de teste                                      PARTE B
   ============================================================================
   Correr depois do 01. A ordem dos INSERT segue a ordem das dependências.
   Os números à direita são os ID que o IDENTITY vai gerar.
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO


/* ---- Catálogos ---- */

INSERT INTO Concelho (Nome) VALUES
    (N'Braga'),      -- 1
    (N'Porto'),      -- 2
    (N'Lisboa'),     -- 3
    (N'Guimarães'),  -- 4
    (N'Coimbra');    -- 5  sem postos

INSERT INTO TipoConector (Designacao) VALUES
    (N'Type 2'),     -- 1
    (N'CCS2'),       -- 2
    (N'CHAdeMO'),    -- 3
    (N'Type 1');     -- 4  sem carregamentos

INSERT INTO TipoAvaria (Designacao) VALUES
    (N'Falha no conector'),      -- 1
    (N'Falha de comunicação'),   -- 2
    (N'Vandalismo'),             -- 3
    (N'Falha elétrica');         -- 4
GO


/* ---- Rede ---- */

INSERT INTO Posto (Codigo, IDConcelho, NomePosto, PotenciaKw, DataInstalacao, Ativo, DataDesativacao) VALUES
    (N'P001', 1, N'Braga - Av. Central',         22.00, '2024-03-15', 1, NULL),         -- 1
    (N'P002', 1, N'Braga - Norte Shopping',      50.00, '2024-05-20', 1, NULL),         -- 2
    (N'P003', 1, N'Braga - Nó A3',              150.00, '2024-09-01', 1, NULL),         -- 3
    (N'P004', 1, N'Braga - Parque da Ponte',     22.00, '2026-07-10', 1, NULL),         -- 4  sem carregamentos
    (N'P005', 2, N'Porto - Baixa',               22.00, '2024-02-10', 1, NULL),         -- 5
    (N'P006', 2, N'Porto - Boavista',            50.00, '2024-06-05', 1, NULL),         -- 6
    (N'P007', 2, N'Porto - Campanhã',           150.00, '2025-01-20', 1, NULL),         -- 7
    (N'P008', 2, N'Porto - Matosinhos',           7.40, '2023-11-01', 0, '2026-04-30'), -- 8  desativado
    (N'P009', 3, N'Lisboa - Parque das Nações',  50.00, '2024-04-12', 1, NULL),         -- 9
    (N'P010', 3, N'Lisboa - Oriente',           150.00, '2024-08-30', 1, NULL),         -- 10
    (N'P011', 3, N'Lisboa - Belém',              22.00, '2025-03-18', 1, NULL),         -- 11
    (N'P012', 4, N'Guimarães - Centro',          22.00, '2024-07-22', 1, NULL);         -- 12
GO

/* Cada linha é uma tomada: um posto mais um tipo de conector. */
INSERT INTO PostoConector (IDPosto, IDTipoConector) VALUES
    ( 1, 1),   -- 1
    ( 1, 2),   -- 2
    ( 2, 2),   -- 3
    ( 3, 2),   -- 4
    ( 4, 4),   -- 5   Type 1, nunca usado
    ( 5, 1),   -- 6
    ( 5, 2),   -- 7
    ( 6, 2),   -- 8
    ( 7, 2),   -- 9
    ( 7, 3),   -- 10  CHAdeMO, nunca usado
    ( 8, 1),   -- 11  posto desativado
    ( 9, 2),   -- 12
    (10, 2),   -- 13
    (11, 1),   -- 14
    (12, 1);   -- 15
GO


/* ---- Clientes e veículos ---- */

INSERT INTO Cliente (Nome, NIF, TipoCliente, DataNascimento, Telefone, Email, Ativo) VALUES
    (N'João Silva',     '210345678', N'Particular',  '1988-04-12', N'912345678', N'joao.silva@mail.pt',    1),  -- 1
    (N'Maria Costa',    '215678901', N'Particular',  '1995-11-30', N'913456789', N'maria.costa@mail.pt',   1),  -- 2
    (N'TransNorte Lda', '501234567', N'Empresarial', NULL,         N'253200100', N'frota@transnorte.pt',   1),  -- 3
    (N'Carla Mendes',   '218901234', N'Particular',  '1979-02-08', N'915678901', N'carla.mendes@mail.pt',  1),  -- 4
    (N'Elsa Rocha',     '219012345', N'Particular',  '2001-06-25', N'916789012', N'elsa.rocha@mail.pt',    1),  -- 5  um carregamento só
    (N'Filipe Nunes',   '211123456', N'Particular',  '1992-09-17', N'917890123', N'filipe.nunes@mail.pt',  1),  -- 6  sem carregamentos
    (N'EcoFrota SA',    '502345678', N'Empresarial', NULL,         N'220300400', N'gestao@ecofrota.pt',    1);  -- 7
GO

INSERT INTO Veiculo (IDCliente, Matricula, Marca, Modelo) VALUES
    (1, N'AA-01-BB', N'Renault', N'Zoe'),        -- 1
    (2, N'CC-02-DD', N'Nissan',  N'Leaf'),       -- 2
    (3, N'EE-03-FF', N'Peugeot', N'e-Expert'),   -- 3
    (3, N'GG-04-HH', N'Renault', N'Kangoo E'),   -- 4
    (4, N'II-05-JJ', N'Fiat',    N'500e'),       -- 5
    (5, N'KK-06-LL', N'Dacia',   N'Spring'),     -- 6
    (7, N'MM-07-NN', N'Tesla',   N'Model 3');    -- 7
GO


/* ---- Tarifários ---- */

INSERT INTO Tarifario (Nome, Comercializado) VALUES
    (N'Normal',      1),   -- 1
    (N'Verde',       1),   -- 2
    (N'Empresarial', 1),   -- 3
    (N'Rápido',      0);   -- 4  descontinuado
GO

/* DataFim a NULL significa "em vigor". O Normal tem duas vigências: em julho
   o preço subiu, e a antiga foi fechada em vez de alterada. */
INSERT INTO TarifarioPreco (IDTarifario, DataInicio, DataFim, PrecoKwh, TaxaAtivacao) VALUES
    (1, '2026-01-01', '2026-06-30', 0.2500, 0.00),
    (1, '2026-07-01', NULL,         0.2800, 0.00),
    (2, '2026-01-01', NULL,         0.2200, 0.50),
    (3, '2026-01-01', NULL,         0.2000, 0.00),
    (4, '2026-01-01', '2026-05-31', 0.3500, 1.00);
GO


/* ---- Reservas ---- */

INSERT INTO Reserva (IDCliente, IDPosto, DataHoraInicio, DataHoraFim, Estado, DataCriacao) VALUES
    (1,  1, '2026-02-10 09:00', '2026-02-10 11:00', N'Concretizada', '2026-02-09 18:20'),  -- 1
    (2,  5, '2026-03-05 14:00', '2026-03-05 16:00', N'Concretizada', '2026-03-04 21:00'),  -- 2
    (3,  7, '2026-05-20 17:00', '2026-05-20 19:00', N'Concretizada', '2026-05-19 08:40'),  -- 3
    (4,  3, '2026-06-15 10:00', '2026-06-15 12:00', N'Cancelada',    '2026-06-14 12:30'),  -- 4
    (5, 11, '2026-07-01 08:00', '2026-07-01 10:00', N'Expirada',     '2026-06-30 22:10');  -- 5
GO


/* ---- Faturação ---- */

INSERT INTO Fatura (Numero, IDClientePagador, DataEmissao, DataVencimento, Metodo, Estado) VALUES
    (N'FT2026/0001', 1, '2026-02-10', '2026-02-10', N'Imediato', N'Paga'),      -- 1
    (N'FT2026/0002', 2, '2026-03-05', '2026-03-05', N'Imediato', N'Paga'),      -- 2
    (N'FT2026/0003', 3, '2026-05-31', '2026-06-30', N'Mensal',   N'Paga'),      -- 3  duas prestações
    (N'FT2026/0004', 5, '2026-07-13', '2026-07-13', N'Imediato', N'Paga'),      -- 4
    (N'FT2026/0005', 4, '2026-06-11', '2026-06-26', N'Imediato', N'Emitida'),   -- 5  vencida, por pagar
    (N'FT2026/0006', 2, '2026-07-02', '2026-07-17', N'Imediato', N'Emitida'),   -- 6  vencida, por pagar
    (N'FT2026/0007', 3, '2026-07-31', '2026-08-30', N'Mensal',   N'Emitida'),   -- 7  vencida, paga em parte
    (N'FT2026/0008', 7, '2026-08-31', '2026-09-30', N'Mensal',   N'Emitida');   -- 8  dentro do prazo
GO


/* ---- Carregamentos ----
   A coluna IDPostoConector é o número da tomada, da lista acima. */

INSERT INTO Carregamento
      (IDPostoConector, IDClienteCondutor, IDVeiculo, IDTarifario, IDReserva, IDFatura,
       DataHoraInicio, DataHoraFim, EnergiaKwh, CustoTotal, Estado) VALUES
    ( 1, 1, 1, 1,    1,    1, '2026-02-10 09:05', '2026-02-10 10:50', 20.000,  5.00, N'Faturado'),  -- 1
    ( 6, 2, 2, 2,    2,    2, '2026-03-05 14:10', '2026-03-05 15:25', 18.000,  4.46, N'Faturado'),  -- 2
    ( 9, 3, 3, 3,    3,    3, '2026-05-20 17:05', '2026-05-20 18:20', 40.000,  8.00, N'Faturado'),  -- 3
    ( 8, 3, 4, 3, NULL,    3, '2026-05-22 07:30', '2026-05-22 08:40', 35.000,  7.00, N'Faturado'),  -- 4
    ( 2, 1, 1, 1, NULL,    1, '2026-02-18 08:30', '2026-02-18 09:40', 15.000,  3.75, N'Faturado'),  -- 5
    ( 4, 4, 5, 1, NULL,    5, '2026-06-11 12:10', '2026-06-11 13:20', 24.640,  6.16, N'Faturado'),  -- 6  vencida
    ( 3, 2, 2, 2, NULL,    6, '2026-07-02 14:00', '2026-07-02 15:30', 30.270,  7.16, N'Faturado'),  -- 7  vencida
    (12, 3, 3, 3, NULL,    7, '2026-07-08 06:10', '2026-07-08 07:55', 40.000,  8.00, N'Faturado'),  -- 8  parcial
    (13, 3, 4, 3, NULL,    7, '2026-07-21 08:00', '2026-07-21 09:10', 38.000,  7.60, N'Faturado'),  -- 9
    (14, 7, 7, 3, NULL,    8, '2026-08-25 19:00', '2026-08-25 21:00', 33.500,  6.70, N'Faturado'),  -- 10 dentro do prazo
    ( 7, 5, 6, 1, NULL,    4, '2026-07-13 10:30', '2026-07-13 12:00', 20.000,  5.60, N'Faturado'),  -- 11 único da Elsa

    ( 2, 1, 1, 1, NULL, NULL, '2026-08-03 09:00', '2026-08-03 10:20', 27.500,  7.70, N'Terminado'), -- 12
    (11, 2, 2, 2, NULL, NULL, '2026-03-02 07:45', '2026-03-02 10:15',  9.000,  2.48, N'Terminado'), -- 13 posto hoje desativado
    (13, 3, 3, 3, NULL, NULL, '2026-08-26 12:00', '2026-08-26 13:10', 44.000,  8.80, N'Terminado'), -- 14

    ( 1, 1, 1, 1, NULL, NULL, '2026-09-08 08:30', NULL, NULL, NULL, N'EmCurso'),                    -- 15
    ( 6, 2, 2, 2, NULL, NULL, '2026-04-30 10:00', '2026-04-30 10:04',  0.200,  0.54, N'Anulado'),   -- 16

    /* Dois registos fisicamente impossíveis, deixados de propósito: passam por
       todas as restrições e mesmo assim estão errados. São os da Parte E. */
    ( 1, 1, 1, 1, NULL, NULL, '2026-08-27 09:00', '2026-08-27 10:00', 45.000, 12.60, N'Terminado'), -- 17 P001, 22 kW
    (15, 1, 1, 1, NULL, NULL, '2026-08-28 14:00', '2026-08-28 14:30', 30.000,  8.40, N'Terminado'); -- 18 P012, 22 kW
GO


/* ---- Pagamentos ---- */

INSERT INTO Pagamento (IDFatura, Valor, DataPagamento, MeioPagamento) VALUES
    (1,  8.75, '2026-02-10', N'MBWay'),
    (2,  4.46, '2026-03-05', N'Cartão'),
    (3, 10.00, '2026-06-20', N'Transferência'),   -- primeira prestação
    (3,  5.00, '2026-06-28', N'Transferência'),   -- segunda
    (4,  5.60, '2026-07-13', N'MBWay'),
    (7, 10.00, '2026-08-20', N'Transferência');   -- parcial: faltam 5,60
GO


/* ---- Manutenção ---- */

INSERT INTO Ocorrencia (IDPosto, IDTipoAvaria, DataAbertura, Descricao, CustoIntervencao, Estado) VALUES
    ( 1, 1, '2026-01-15 08:30', N'Conector Type 2 sem encaixe',      120.00, N'Resolvida'),    -- 1
    ( 1, 2, '2026-04-02 11:15', N'Posto sem ligação à central',       80.00, N'Resolvida'),    -- 2
    ( 2, 4, '2026-02-20 16:40', N'Disjuntor a disparar',             250.00, N'Resolvida'),    -- 3
    ( 3, 3, '2026-03-11 23:05', N'Grafitos no painel',                90.00, N'Resolvida'),    -- 4
    ( 5, 1, '2026-08-11 07:20', N'Cabo danificado',                    NULL, N'EmResolucao'),  -- 5
    ( 5, 2, '2026-05-30 09:50', N'Falha intermitente de rede',        60.00, N'Resolvida'),    -- 6
    ( 6, 4, '2026-06-18 14:25', N'Quebra de tensão',                 310.00, N'Resolvida'),    -- 7
    ( 7, 1, '2026-07-09 10:00', N'CHAdeMO não inicia sessão',        140.00, N'Resolvida'),    -- 8
    ( 8, 4, '2026-04-28 08:00', N'Avaria que levou à desativação',   520.00, N'Resolvida'),    -- 9
    ( 9, 3, '2026-08-20 22:40', N'Tentativa de furto de cabo',         NULL, N'Aberta'),       -- 10
    (10, 2, '2026-02-25 06:50', N'Sem comunicação após atualização',  75.00, N'Resolvida'),    -- 11
    (12, 1, '2026-08-30 18:10', N'Encaixe folgado',                    NULL, N'Aberta');       -- 12
GO


/* ---- Histórico ----
   Preenchido à mão porque o trigger só nasce no script 03. */

INSERT INTO CarregamentoHistorico (IDCarregamento, DataHora, EstadoNovo) VALUES
    ( 1, '2026-02-10 09:05', N'EmCurso'),
    ( 1, '2026-02-10 10:50', N'Terminado'),
    ( 1, '2026-02-10 11:02', N'Faturado'),
    (12, '2026-08-03 09:00', N'EmCurso'),
    (12, '2026-08-03 10:20', N'Terminado'),
    (15, '2026-09-08 08:30', N'EmCurso'),
    (16, '2026-04-30 10:00', N'EmCurso'),
    (16, '2026-04-30 10:04', N'Anulado');
GO


/* ---- Conferir ---- */

SELECT 'Concelho' AS Tabela, COUNT(*) AS Linhas FROM Concelho
UNION ALL SELECT 'TipoConector',          COUNT(*) FROM TipoConector
UNION ALL SELECT 'TipoAvaria',            COUNT(*) FROM TipoAvaria
UNION ALL SELECT 'Posto',                 COUNT(*) FROM Posto
UNION ALL SELECT 'PostoConector',         COUNT(*) FROM PostoConector
UNION ALL SELECT 'Cliente',               COUNT(*) FROM Cliente
UNION ALL SELECT 'Veiculo',               COUNT(*) FROM Veiculo
UNION ALL SELECT 'Tarifario',             COUNT(*) FROM Tarifario
UNION ALL SELECT 'TarifarioPreco',        COUNT(*) FROM TarifarioPreco
UNION ALL SELECT 'Reserva',               COUNT(*) FROM Reserva
UNION ALL SELECT 'Fatura',                COUNT(*) FROM Fatura
UNION ALL SELECT 'Carregamento',          COUNT(*) FROM Carregamento
UNION ALL SELECT 'Pagamento',             COUNT(*) FROM Pagamento
UNION ALL SELECT 'Ocorrencia',            COUNT(*) FROM Ocorrencia
UNION ALL SELECT 'CarregamentoHistorico', COUNT(*) FROM CarregamentoHistorico
UNION ALL SELECT 'Alerta',                COUNT(*) FROM Alerta;
GO
