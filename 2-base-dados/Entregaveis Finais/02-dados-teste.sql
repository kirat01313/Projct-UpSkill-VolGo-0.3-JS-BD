/* ============================================================================
   VoltGo — 02 — Dados de teste
   ============================================================================
   Correr depois do 01. A ordem dos INSERT é a ordem das dependências.

   As PK são IDENTITY: a numeração segue a ordem de inserção. Os comentários à
   direita indicam o ID de cada linha, para se poderem seguir as FK.

   CASOS PREPARADOS DE PROPÓSITO
   Sem eles, um LEFT JOIN devolve o mesmo que um INNER JOIN e não se prova nada:

     Type 1 e CHAdeMO sem carregamentos ......... relatório 1
     Braga - Parque da Ponte sem carregamentos .. relatório 2
     Filipe Nunes sem carregamentos ............. relatório 4
     Elsa Rocha com exatamente um ............... relatório 4 (HAVING > 1)
     Carregamento 5 faturado e por pagar ........ relatório 5
     Coimbra sem postos ......................... relatório 6
     4 postos sem ocorrências ................... relatório 7
     13 postos (mais de 10) ..................... relatório 7 (TOP 10)
     Fatura mensal com 2 carregamentos .......... regra 3.6
     Fatura paga em 2 prestações ................ regra 3.6
     2 faturas vencidas e por pagar ............. Parte D
     2 carregamentos com energia impossível ..... Parte E (Alerta)
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO


/* ############################################################################
   CATÁLOGOS
   ############################################################################ */

INSERT INTO Concelho (Nome) VALUES
    (N'Braga'),      -- 1
    (N'Porto'),      -- 2
    (N'Lisboa'),     -- 3
    (N'Guimarães'),  -- 4
    (N'Coimbra');    -- 5  sem postos — relatório 6

INSERT INTO TipoConector (Designacao) VALUES
    (N'Type 2'),     -- 1  AC até 22 kW
    (N'CCS2'),       -- 2  DC rápido
    (N'CHAdeMO'),    -- 3  existe num posto, nunca usado
    (N'Type 1');     -- 4  não existe em posto nenhum — relatório 1

INSERT INTO TipoAvaria (Designacao) VALUES
    (N'Falha no conector'),      -- 1
    (N'Falha de comunicação'),   -- 2
    (N'Vandalismo'),             -- 3
    (N'Falha elétrica');         -- 4
GO


/* ############################################################################
   ENTIDADES BASE
   ############################################################################ */

INSERT INTO Posto (Codigo, IDConcelho, NomePosto, PotenciaKw, DataInstalacao, Ativo, DataDesativacao) VALUES
    (N'P001', 1, N'Braga - Av. Central',         22.00, '2024-03-15', 1, NULL),          -- 1
    (N'P002', 1, N'Braga - Norte Shopping',      50.00, '2024-05-20', 1, NULL),          -- 2
    (N'P003', 1, N'Braga - Nó A3',              150.00, '2024-09-01', 1, NULL),          -- 3
    (N'P004', 1, N'Braga - Parque da Ponte',     22.00, '2026-07-10', 1, NULL),          -- 4  sem carregamentos
    (N'P005', 2, N'Porto - Baixa',               22.00, '2024-02-10', 1, NULL),          -- 5
    (N'P006', 2, N'Porto - Boavista',            50.00, '2024-06-05', 1, NULL),          -- 6
    (N'P007', 2, N'Porto - Campanhã',           150.00, '2025-01-20', 1, NULL),          -- 7  único com CHAdeMO
    (N'P008', 2, N'Porto - Matosinhos',           7.40, '2023-11-01', 0, '2026-04-30'),  -- 8  desativado, guarda histórico
    (N'P009', 3, N'Lisboa - Parque das Nações',  50.00, '2024-04-12', 1, NULL),          -- 9
    (N'P010', 3, N'Lisboa - Oriente',           150.00, '2024-08-30', 1, NULL),          -- 10
    (N'P011', 3, N'Lisboa - Belém',              22.00, '2025-03-18', 1, NULL),          -- 11
    (N'P012', 4, N'Guimarães - Centro',          22.00, '2024-07-22', 1, NULL),          -- 12
    (N'P013', 4, N'Guimarães - Norte',           50.00, '2025-05-14', 1, NULL);          -- 13

INSERT INTO Cliente (Nome, NIF, TipoCliente, DataNascimento, Telefone, Email, Ativo) VALUES
    (N'Ana Silva',      '210345678', N'Particular',  '1985-03-12', N'912345678', N'ana.silva@mail.pt',    1),  -- 1
    (N'Bruno Costa',    '215678901', N'Particular',  '1992-07-25', N'913456789', N'bruno.costa@mail.pt',  1),  -- 2
    (N'Carla Mendes',   '218901234', N'Particular',  '1978-11-03', N'914567890', N'carla.mendes@mail.pt', 1),  -- 3
    (N'Diogo Ferreira', '221234567', N'Particular',  '2000-02-29', N'915678901', N'diogo.f@mail.pt',      1),  -- 4  data bissexta
    (N'TransNorte Lda', '501234567', N'Empresarial', NULL,         N'253200300', N'geral@transnorte.pt',  1),  -- 5  paga por outros
    (N'EcoFrota SA',    '502345678', N'Empresarial', NULL,         N'220400500', N'frota@ecofrota.pt',    1),  -- 6
    (N'Elsa Rocha',     '224567890', N'Particular',  '1995-06-18', N'916789012', N'elsa.rocha@mail.pt',   1),  -- 7  exatamente 1 carregamento
    (N'Filipe Nunes',   '227890123', N'Particular',  '1988-09-30', N'917890123', N'filipe.nunes@mail.pt', 1),  -- 8  zero carregamentos
    (N'Gabriela Pinto', '230123456', N'Particular',  '1999-12-05', N'918901234', N'gabriela.p@mail.pt',   0);  -- 9  cessou atividade

/* PrecoKwhAtual e TaxaAtivacaoAtual ficam NULL aqui de propósito: são
   preenchidos pelo trigger de sincronização quando as vigências entrarem
   (script 07). É a prova de que a cópia é mantida pela base de dados e não
   escrita à mão. */
INSERT INTO Tarifario (Nome, Comercializado) VALUES
    (N'Normal',      1),   -- 1
    (N'Verde',       1),   -- 2
    (N'Empresarial', 1),   -- 3
    (N'Rápido',      0);   -- 4  descontinuado, mas com carregamentos antigos
GO


/* ############################################################################
   DEPENDENTES
   ############################################################################ */

/* Cada linha é uma tomada física. O Type 1 (id 4) não aparece: é um tipo do
   catálogo que a rede não tem — o órfão do relatório 1. */
INSERT INTO PostoConector (IDPosto, IDTipoConector) VALUES
    (1,1),(1,2),        -- 1, 2
    (2,2),              -- 3
    (3,2),              -- 4
    (4,1),              -- 5   posto sem carregamentos
    (5,1),(5,2),        -- 6, 7
    (6,2),              -- 8
    (7,2),(7,3),        -- 9, 10   o 10 é CHAdeMO: existe, nunca usado
    (8,1),              -- 11
    (9,2),              -- 12
    (10,2),             -- 13
    (11,1),             -- 14
    (12,1),             -- 15
    (13,2);             -- 16

INSERT INTO Veiculo (IDCliente, Matricula, Marca, Modelo) VALUES
    (1, N'AA-01-BB', N'Renault',  N'Zoe'),        -- 1
    (1, N'AA-02-CC', N'Nissan',   N'Leaf'),       -- 2
    (2, N'BB-11-CD', N'Tesla',    N'Model 3'),    -- 3
    (3, N'CC-22-DE', N'Peugeot',  N'e-208'),      -- 4
    (4, N'DD-33-EF', N'VW',       N'ID.3'),       -- 5
    (5, N'EE-44-FG', N'Mercedes', N'eVito'),      -- 6  carrinha da TransNorte
    (5, N'EE-45-FH', N'Mercedes', N'eVito'),      -- 7
    (6, N'FF-55-GH', N'Mercedes', N'eSprinter'),  -- 8
    (7, N'GG-66-HI', N'Opel',     N'Corsa-e'),    -- 9
    (8, N'HH-77-IJ', N'Hyundai',  N'Kona'),       -- 10 tem carro, nunca carregou
    (9, N'II-88-JK', N'BMW',      N'i3');         -- 11

/* O Normal tem duas vigências, uma já fechada. É esta linha a mais que
   justifica a existência da tabela: sem ela, o preço de janeiro tinha
   desaparecido quando o de julho entrou. */
INSERT INTO TarifarioPreco (IDTarifario, DataInicio, DataFim, PrecoKwh, TaxaAtivacao) VALUES
    (1, '2026-01-01', '2026-06-30', 0.2500, 0.00),
    (1, '2026-07-01', NULL,         0.2800, 0.00),   -- em vigor
    (2, '2026-01-01', NULL,         0.2200, 0.50),
    (3, '2026-01-01', NULL,         0.2000, 0.00),
    (4, '2026-01-01', '2026-05-31', 0.3500, 1.00);   -- fechada: tarifário descontinuado

INSERT INTO Reserva (IDCliente, IDPosto, DataHoraInicio, DataHoraFim, Estado, DataCriacao) VALUES
    (1,  1, '2026-02-10 09:00', '2026-02-10 11:00', N'Concretizada', '2026-02-08 18:22'),  -- 1
    (2,  6, '2026-03-05 14:00', '2026-03-05 15:30', N'Concretizada', '2026-03-04 10:15'),  -- 2
    (3,  9, '2026-04-12 08:00', '2026-04-12 09:00', N'Cancelada',    '2026-04-10 21:40'),  -- 3
    (4, 10, '2026-05-20 17:00', '2026-05-20 18:30', N'Concretizada', '2026-05-19 12:05'),  -- 4
    (1,  2, '2026-06-15 10:00', '2026-06-15 11:00', N'Expirada',     '2026-06-14 09:30'),  -- 5
    (5,  7, '2026-07-08 06:00', '2026-07-08 08:00', N'Concretizada', '2026-07-07 16:50'),  -- 6
    (6, 13, '2026-08-01 13:00', '2026-08-01 14:00', N'Concretizada', '2026-07-31 11:11'),  -- 7
    (3,  5, '2026-09-15 09:00', '2026-09-15 10:00', N'Ativa',        '2026-08-25 14:00');  -- 8

/* Distribuição desigual de propósito: o TOP 10 do relatório 7 precisa de ter
   o que ordenar. Os postos 4, 9, 11 e 13 ficam com zero ocorrências. */
INSERT INTO Ocorrencia (IDPosto, IDTipoAvaria, DataAbertura, Descricao, CustoIntervencao, Estado) VALUES
    ( 3, 1, '2026-01-15 08:30', N'Conector CCS2 não engata',            120.00, N'Resolvida'),   -- 1
    ( 3, 2, '2026-02-02 14:10', N'Posto sem comunicação com a central',  80.00, N'Resolvida'),   -- 2
    ( 3, 4, '2026-03-18 09:45', N'Disjuntor a disparar com carga alta', 340.00, N'Resolvida'),   -- 3
    ( 3, 1, '2026-05-22 16:00', N'Cabo danificado',                     210.00, N'Resolvida'),   -- 4
    ( 3, 3, '2026-08-11 07:20', N'Grafitos no ecrã',                      NULL, N'EmResolucao'), -- 5
    ( 6, 2, '2026-01-28 11:00', N'Perda intermitente de rede',            75.00, N'Resolvida'),  -- 6
    ( 6, 4, '2026-04-05 13:30', N'Sobreaquecimento do módulo',          450.00, N'Resolvida'),   -- 7
    ( 6, 1, '2026-06-19 10:15', N'Conector preso',                       95.00, N'Resolvida'),   -- 8
    ( 6, 3, '2026-08-20 22:40', N'Tentativa de furto de cabo',            NULL, N'Aberta'),      -- 9
    ( 1, 1, '2026-02-14 09:00', N'Conector Type 2 com folga',            60.00, N'Resolvida'),   -- 10
    ( 1, 2, '2026-05-30 15:20', N'Leitura de energia inconsistente',    130.00, N'Resolvida'),   -- 11
    ( 1, 4, '2026-08-25 08:05', N'Corte de energia no quadro',            NULL, N'EmResolucao'), -- 12
    (10, 1, '2026-03-09 12:00', N'Conector CCS2 sujo',                   40.00, N'Resolvida'),   -- 13
    (10, 2, '2026-06-27 18:45', N'Sem ligação ao servidor',              90.00, N'Resolvida'),   -- 14
    (10, 4, '2026-08-14 07:30', N'Falha de fase',                         NULL, N'Aberta'),      -- 15
    ( 5, 3, '2026-04-21 23:10', N'Vandalismo no painel',                280.00, N'Resolvida'),   -- 16
    ( 5, 1, '2026-07-16 11:35', N'Conector com desgaste',                70.00, N'Resolvida'),   -- 17
    ( 8, 4, '2026-02-25 06:50', N'Avaria elétrica grave',               620.00, N'Resolvida'),   -- 18
    ( 8, 4, '2026-04-28 09:15', N'Avaria elétrica recorrente',          580.00, N'Resolvida'),   -- 19
    ( 2, 2, '2026-05-11 16:25', N'Comunicação instável',                 85.00, N'Resolvida'),   -- 20
    ( 7, 1, '2026-07-03 10:40', N'Conector CHAdeMO bloqueado',          150.00, N'Resolvida'),   -- 21
    (12, 3, '2026-08-05 21:00', N'Autocolantes no leitor de cartões',    25.00, N'Resolvida');   -- 22
GO


/* ############################################################################
   FATURAS
   ############################################################################
   20 faturas. Repara em quatro delas, que são a razão de esta tabela existir:

     FT2026/0003  paga em DUAS prestações        → 1 fatura : N pagamentos
     FT2026/0019  agrupa DOIS carregamentos      → periodicidade mensal (3.6)
     FT2026/0013  e /0014 vencidas e por pagar   → "em dívida" (Parte D)
     FT2026/0020  emitida e sem pagamento nenhum → relatório 5
   ############################################################################ */

INSERT INTO Fatura (Numero, IDClientePagador, DataEmissao, DataVencimento, Metodo, Estado) VALUES
    (N'FT2026/0001', 1, '2026-02-10', '2026-02-10', N'Imediato', N'Paga'),     -- 1
    (N'FT2026/0002', 2, '2026-03-05', '2026-03-05', N'Imediato', N'Paga'),     -- 2
    (N'FT2026/0003', 4, '2026-05-20', '2026-06-19', N'Imediato', N'Paga'),     -- 3  2 prestações
    (N'FT2026/0004', 1, '2026-01-12', '2026-01-12', N'Imediato', N'Paga'),     -- 4
    (N'FT2026/0005', 3, '2026-01-25', '2026-01-25', N'Imediato', N'Paga'),     -- 5
    (N'FT2026/0006', 2, '2026-02-03', '2026-02-03', N'Imediato', N'Paga'),     -- 6
    (N'FT2026/0007', 4, '2026-02-18', '2026-02-18', N'Imediato', N'Paga'),     -- 7
    (N'FT2026/0008', 1, '2026-03-02', '2026-03-02', N'Imediato', N'Paga'),     -- 8
    (N'FT2026/0009', 3, '2026-03-27', '2026-03-27', N'Imediato', N'Paga'),     -- 9
    (N'FT2026/0010', 4, '2026-04-08', '2026-04-08', N'Imediato', N'Paga'),     -- 10
    (N'FT2026/0011', 2, '2026-04-19', '2026-04-19', N'Imediato', N'Paga'),     -- 11
    (N'FT2026/0012', 1, '2026-05-28', '2026-05-28', N'Imediato', N'Paga'),     -- 12
    (N'FT2026/0013', 9, '2026-06-11', '2026-06-26', N'Imediato', N'Emitida'),  -- 13 EM DÍVIDA
    (N'FT2026/0014', 3, '2026-07-02', '2026-07-17', N'Imediato', N'Emitida'),  -- 14 EM DÍVIDA
    (N'FT2026/0015', 7, '2026-07-13', '2026-07-13', N'Imediato', N'Paga'),     -- 15
    (N'FT2026/0016', 5, '2026-03-31', '2026-04-30', N'Mensal',   N'Paga'),     -- 16
    (N'FT2026/0017', 6, '2026-05-31', '2026-06-30', N'Mensal',   N'Paga'),     -- 17
    (N'FT2026/0018', 5, '2026-06-30', '2026-07-30', N'Mensal',   N'Paga'),     -- 18
    (N'FT2026/0019', 5, '2026-07-31', '2026-08-30', N'Mensal',   N'Emitida'),  -- 19 2 carregamentos, paga em parte
    (N'FT2026/0020', 6, '2026-08-31', '2026-09-30', N'Mensal',   N'Emitida');  -- 20 sem pagamento nenhum
GO


/* ############################################################################
   CARREGAMENTOS
   ############################################################################
   35 registos, quatro estados, vários meses.

   A tomada é procurada pelo par (posto, conector) em vez de se escrever o ID
   à mão: assim os INSERT continuam corretos mesmo que a numeração mude.

   CustoTotal calculado com o preço em vigor NA DATA da sessão:
     Normal 0.25 até 30-06 e 0.28 depois | Verde 0.22 + 0.50
     Empresarial 0.20 | Rápido 0.35 + 1.00 (só até 31-05)

   Nenhum usa as tomadas 5 (posto 4) nem 10 (CHAdeMO) — são os órfãos.
   ############################################################################ */

INSERT INTO Carregamento
      (IDPostoConector, IDClienteCondutor, IDVeiculo, IDTarifario, IDReserva, IDFatura,
       DataHoraInicio, DataHoraFim, EnergiaKwh, CustoTotal, Estado)
SELECT pc.IDPostoConector, v.Condutor, v.Veiculo, v.Tarifario, v.Reserva, v.Fatura,
       v.Inicio, v.Fim, v.Energia, v.Custo, v.Estado
FROM (VALUES
    /*  seq posto conector condutor veic tarif reserva fatura  inicio                fim                  energia   custo  estado */
    (1,  1, 1, 1, 1, 1,    1,    1, CONVERT(DATETIME2(0),'2026-02-10 09:05'), CONVERT(DATETIME2(0),'2026-02-10 10:50'), 38.400,  9.60, N'Faturado'),  -- 1
    (2,  6, 2, 2, 3, 1,    2,    2, '2026-03-05 14:10', '2026-03-05 15:25', 52.000, 13.00, N'Faturado'),  -- 2
    (3, 10, 2, 4, 5, 1,    4,    3, '2026-05-20 17:05', '2026-05-20 18:20', 61.200, 15.30, N'Faturado'),  -- 3
    (4,  7, 2, 5, 6, 3,    6,   19, '2026-07-08 06:10', '2026-07-08 07:55', 70.000, 14.00, N'Faturado'),  -- 4  mensal TransNorte
    (5, 13, 2, 6, 8, 3,    7,   20, '2026-08-01 13:05', '2026-08-01 13:50', 33.500,  6.70, N'Faturado'),  -- 5  fatura sem pagamento
    (6,  1, 2, 1, 1, 1, NULL,    4, '2026-01-12 08:30', '2026-01-12 09:40', 25.000,  6.25, N'Faturado'),  -- 6
    (7,  2, 2, 3, 4, 2, NULL,    5, '2026-01-25 18:00', '2026-01-25 19:10', 30.000,  7.10, N'Faturado'),  -- 7
    (8,  5, 1, 2, 3, 1, NULL,    6, '2026-02-03 11:20', '2026-02-03 12:50', 19.800,  4.95, N'Faturado'),  -- 8
    (9,  3, 2, 4, 5, 4, NULL,    7, '2026-02-18 15:00', '2026-02-18 15:35', 45.000, 16.75, N'Faturado'),  -- 9  tarifário Rápido
    (10,  8, 1, 1, 2, 1, NULL,    8, '2026-03-02 07:45', '2026-03-02 10:15', 18.000,  4.50, N'Faturado'),  -- 10 posto hoje desativado
    (11,  6, 2, 5, 7, 3, NULL,   16, '2026-03-14 09:00', '2026-03-14 10:05', 48.600,  9.72, N'Faturado'),  -- 11
    (12,  9, 2, 3, 4, 2, NULL,    9, '2026-03-27 13:30', '2026-03-27 14:40', 41.000,  9.52, N'Faturado'),  -- 12
    (13, 12, 1, 4, 5, 1, NULL,   10, '2026-04-08 10:00', '2026-04-08 12:00', 21.500,  5.38, N'Faturado'),  -- 13
    (14,  3, 2, 2, 3, 4, NULL,   11, '2026-04-19 16:20', '2026-04-19 16:55', 55.000, 20.25, N'Faturado'),  -- 14
    (15,  5, 2, 6, 8, 3, NULL,   17, '2026-05-06 08:15', '2026-05-06 10:15', 36.000,  7.20, N'Faturado'),  -- 15
    (16, 10, 2, 1, 2, 1, NULL,   12, '2026-05-28 19:00', '2026-05-28 19:45', 50.400, 12.60, N'Faturado'),  -- 16
    (17,  2, 2, 9,11, 2, NULL,   13, '2026-06-11 12:10', '2026-06-11 13:20', 28.000,  6.66, N'Faturado'),  -- 17 em dívida
    (18,  7, 2, 2, 6, 3, NULL,   18, '2026-06-24 06:30', '2026-06-24 07:40', 65.000, 13.00, N'Faturado'),  -- 18 Bruno na carrinha da TransNorte
    (19, 11, 1, 3, 4, 1, NULL,   14, '2026-07-02 14:00', '2026-07-02 16:30', 22.000,  6.16, N'Faturado'),  -- 19 em dívida
    (20,  1, 1, 7, 9, 2, NULL,   15, '2026-07-13 10:30', '2026-07-13 12:00', 24.000,  5.78, N'Faturado'),  -- 20 único da Elsa
    (21,  6, 2, 2, 6, 3, NULL,   19, '2026-07-21 08:00', '2026-07-21 09:10', 58.000, 11.60, N'Faturado'),  -- 21 mesma fatura do 4

    -- terminados: medidos, ainda não faturados (IDFatura tem de ser NULL)
    (22,  1, 2, 1, 2, 1, NULL, NULL, '2026-08-03 09:00', '2026-08-03 10:20', 27.500,  7.70, N'Terminado'), -- 22
    (23,  3, 2, 4, 5, 1, NULL, NULL, '2026-08-07 17:40', '2026-08-07 18:15', 62.000, 17.36, N'Terminado'), -- 23
    (24,  5, 1, 3, 4, 2, NULL, NULL, '2026-08-10 11:00', '2026-08-10 13:00', 20.000,  4.90, N'Terminado'), -- 24
    (25,  9, 2, 6, 8, 3, NULL, NULL, '2026-08-12 07:30', '2026-08-12 08:35', 44.000,  8.80, N'Terminado'), -- 25
    (26, 10, 2, 2, 3, 1, NULL, NULL, '2026-08-15 20:00', '2026-08-15 20:50', 53.000, 14.84, N'Terminado'), -- 26
    (27, 12, 1, 4, 5, 1, NULL, NULL, '2026-08-18 13:15', '2026-08-18 15:00', 19.000,  5.32, N'Terminado'), -- 27
    (28,  6, 2, 5, 7, 3, NULL, NULL, '2026-08-20 06:45', '2026-08-20 07:55', 47.000,  9.40, N'Terminado'), -- 28
    (29,  2, 2, 1, 2, 1, NULL, NULL, '2026-08-22 15:30', '2026-08-22 16:30', 31.000,  8.68, N'Terminado'), -- 29
    (30, 13, 2, 3, 4, 2, NULL, NULL, '2026-08-24 09:20', '2026-08-24 10:15', 35.000,  8.20, N'Terminado'), -- 30
    (31,  7, 2, 6, 8, 3, NULL, NULL, '2026-08-26 12:00', '2026-08-26 13:10', 68.000, 13.60, N'Terminado'), -- 31

    -- em curso: sem fim, sem energia, sem custo
    (32,  1, 1, 1, 1, 1, NULL, NULL, '2026-08-29 08:30', NULL, NULL, NULL, N'EmCurso'),                    -- 32
    (33, 10, 2, 2, 3, 1, NULL, NULL, '2026-08-29 09:15', NULL, NULL, NULL, N'EmCurso'),                    -- 33

    -- anulados
    (34,  5, 2, 3, 4, 2, NULL, NULL, '2026-04-30 10:00', '2026-04-30 10:04',  0.200,  0.54, N'Anulado'),   -- 34
    (35, 11, 1, 4, 5, 1, NULL, NULL, '2026-06-05 16:00', '2026-06-05 16:03',  0.100,  0.03, N'Anulado'),   -- 35

    /* Dois registos fisicamente impossíveis, deixados de propósito.
       Passam por TODAS as restrições do modelo — datas coerentes, energia
       positiva, tomada válida — e mesmo assim estão errados: nenhum posto
       destes consegue debitar esta energia neste tempo.
       São eles que a Parte E (Alerta) vai apanhar. */
    (36,  1, 1, 3, 4, 1, NULL, NULL, '2026-08-27 09:00', '2026-08-27 10:00', 45.000, 12.60, N'Terminado'), -- 36  posto de 22 kW, 45 kWh numa hora
    (37, 12, 1, 4, 5, 1, NULL, NULL, '2026-08-28 14:00', '2026-08-28 14:30', 30.000,  8.40, N'Terminado')  -- 37  posto de 22 kW, 30 kWh em meia hora
) AS v(Seq, Posto, Conector, Condutor, Veiculo, Tarifario, Reserva, Fatura,
       Inicio, Fim, Energia, Custo, Estado)
JOIN PostoConector pc
  ON pc.IDPosto = v.Posto AND pc.IDTipoConector = v.Conector
/* ORDER BY obrigatorio: sem ele o JOIN reordena as linhas e os IDENTITY
   deixam de corresponder aos numeros dos comentarios acima. */
ORDER BY v.Seq;
GO


/* ############################################################################
   PAGAMENTOS
   ############################################################################
   Só existem linhas para dinheiro EFETIVAMENTE recebido. O "por pagar" não é
   uma linha vazia — é a ausência de linhas para aquela fatura.

   A fatura 3 tem duas: é o pagamento em prestações da regra 3.6.
   A fatura 19 tem uma parcial (10,00 de 25,60): fica em dívida pelo resto.
   As faturas 13, 14 e 20 não têm nenhuma.
   ############################################################################ */

INSERT INTO Pagamento (IDFatura, Valor, DataPagamento, MeioPagamento)
SELECT f.IDFatura, v.Valor, v.Data, v.Meio
FROM (VALUES
    (N'FT2026/0001',  9.60, CONVERT(DATE,'2026-02-10'), N'Cartão'),
    (N'FT2026/0002', 13.00, '2026-03-05', N'MB Way'),
    (N'FT2026/0003',  7.65, '2026-05-20', N'Cartão'),      -- 1.ª prestação
    (N'FT2026/0003',  7.65, '2026-06-18', N'Transferência'),-- 2.ª prestação
    (N'FT2026/0004',  6.25, '2026-01-12', N'Cartão'),
    (N'FT2026/0005',  7.10, '2026-01-25', N'MB Way'),
    (N'FT2026/0006',  4.95, '2026-02-03', N'Cartão'),
    (N'FT2026/0007', 16.75, '2026-02-18', N'Cartão'),
    (N'FT2026/0008',  4.50, '2026-03-02', N'MB Way'),
    (N'FT2026/0009',  9.52, '2026-03-27', N'Cartão'),
    (N'FT2026/0010',  5.38, '2026-04-08', N'MB Way'),
    (N'FT2026/0011', 20.25, '2026-04-19', N'Cartão'),
    (N'FT2026/0012', 12.60, '2026-05-28', N'Cartão'),
    (N'FT2026/0015',  5.78, '2026-07-13', N'MB Way'),
    (N'FT2026/0016',  9.72, '2026-04-12', N'Transferência'),
    (N'FT2026/0017',  7.20, '2026-06-09', N'Transferência'),
    (N'FT2026/0018', 13.00, '2026-07-15', N'Transferência'),
    (N'FT2026/0019', 10.00, '2026-08-20', N'Transferência') -- parcial: faltam 15,60
) AS v(Numero, Valor, Data, Meio)
JOIN Fatura f ON f.Numero = v.Numero;
GO


/* ############################################################################
   HISTÓRICO
   ############################################################################
   Preenchido à mão aqui porque os triggers só nascem no script 07. A partir
   daí passa a ser automático — e é essa a diferença que o 07 demonstra.
   ############################################################################ */

INSERT INTO CarregamentoHistorico (IDCarregamento, DataHora, EstadoAnterior, EstadoNovo, Observacao) VALUES
    ( 1, '2026-02-10 09:05', NULL,         N'EmCurso',   N'Sessão iniciada a partir de reserva'),
    ( 1, '2026-02-10 10:50', N'EmCurso',   N'Terminado', N'Carro desligado pelo cliente'),
    ( 1, '2026-02-10 11:02', N'Terminado', N'Faturado',  N'Fatura FT2026/0001 emitida'),
    (22, '2026-08-03 09:00', NULL,         N'EmCurso',   NULL),
    (22, '2026-08-03 10:20', N'EmCurso',   N'Terminado', N'Fim normal da sessão'),
    (32, '2026-08-29 08:30', NULL,         N'EmCurso',   N'Sessão a decorrer'),
    (34, '2026-04-30 10:00', NULL,         N'EmCurso',   NULL),
    (34, '2026-04-30 10:04', N'EmCurso',   N'Anulado',   N'Falha de comunicação');

INSERT INTO OcorrenciaHistorico (IDOcorrencia, DataHora, EstadoAnterior, EstadoNovo, Observacao) VALUES
    ( 1, '2026-01-15 08:30', NULL,           N'Aberta',      N'Reportado por cliente'),
    ( 1, '2026-01-15 14:00', N'Aberta',      N'EmResolucao', N'Técnico deslocado'),
    ( 1, '2026-01-16 10:20', N'EmResolucao', N'Resolvida',   N'Conector substituído'),
    ( 5, '2026-08-11 07:20', NULL,           N'Aberta',      N'Detetado em inspeção'),
    ( 5, '2026-08-12 09:00', N'Aberta',      N'EmResolucao', N'Limpeza agendada'),
    ( 9, '2026-08-20 22:40', NULL,           N'Aberta',      N'Alarme noturno'),
    (18, '2026-02-25 06:50', NULL,           N'Aberta',      NULL),
    (18, '2026-02-26 08:00', N'Aberta',      N'EmResolucao', N'Peça encomendada'),
    (18, '2026-03-04 15:30', N'EmResolucao', N'Resolvida',   N'Módulo substituído');
GO


/* ============================================================================
   CONFERIR
   ============================================================================ */
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
UNION ALL SELECT 'OcorrenciaHistorico',   COUNT(*) FROM OcorrenciaHistorico
UNION ALL SELECT 'Alerta',                COUNT(*) FROM Alerta;
GO
