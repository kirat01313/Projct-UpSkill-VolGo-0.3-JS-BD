/* ============================================================
   VoltGo — 02 — Dados de teste
   ============================================================
   Correr depois do 01. Ordem dos INSERT = ordem das dependências.
   As PK são IDENTITY: a numeração segue a ordem de inserção,
   por isso os IDs usados nas FK dependem dela. Os comentários à
   direita indicam o ID de cada linha.

   Casos órfãos criados de propósito (sem eles não se demonstram
   os LEFT JOIN dos relatórios):
     Type 1 / CHAdeMO sem carregamentos ....... rel. 1
     Braga - Parque da Ponte sem carregamentos  rel. 2
     Filipe Nunes sem carregamentos ........... rel. 4
     Elsa Rocha com exatamente um ............. rel. 4 (HAVING > 1)
     Carregamento 5 faturado sem pagamento .... rel. 5
     Coimbra sem postos ....................... rel. 6
     4 postos sem ocorrências ................. rel. 7
     13 postos (mais de 10) ................... rel. 7 (TOP 10)
   ============================================================ */

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
USE VoltGo;
GO


/* ---------------- CATÁLOGOS ---------------- */

INSERT INTO Concelho (Nome) VALUES
    (N'Braga'),      -- 1
    (N'Porto'),      -- 2
    (N'Lisboa'),     -- 3
    (N'Guimarães'),  -- 4
    (N'Coimbra');    -- 5  sem postos

INSERT INTO TipoConector (Designacao) VALUES
    (N'Type 2'),     -- 1
    (N'CCS2'),       -- 2
    (N'CHAdeMO'),    -- 3  existe num posto, nunca usado
    (N'Type 1');     -- 4  não existe em posto nenhum

INSERT INTO TipoAvaria (Designacao) VALUES
    (N'Falha no conector'),      -- 1
    (N'Falha de comunicação'),   -- 2
    (N'Vandalismo'),             -- 3
    (N'Falha elétrica');         -- 4
GO


/* ---------------- ENTIDADES BASE ---------------- */

INSERT INTO Posto (IDConcelho, Designacao, PotenciaKw, DataInstalacao, Ativo, DataDesativacao) VALUES
    (1, N'Braga - Av. Central',        22.00, '2024-03-15', 1, NULL),         -- 1
    (1, N'Braga - Norte Shopping',     50.00, '2024-05-20', 1, NULL),         -- 2
    (1, N'Braga - Nó A3',             150.00, '2024-09-01', 1, NULL),         -- 3
    (1, N'Braga - Parque da Ponte',    22.00, '2026-07-10', 1, NULL),         -- 4  sem carregamentos nem ocorrências
    (2, N'Porto - Baixa',              22.00, '2024-02-10', 1, NULL),         -- 5
    (2, N'Porto - Boavista',           50.00, '2024-06-05', 1, NULL),         -- 6
    (2, N'Porto - Campanhã',          150.00, '2025-01-20', 1, NULL),         -- 7  único com CHAdeMO
    (2, N'Porto - Matosinhos',          7.40, '2023-11-01', 0, '2026-04-30'), -- 8  desativado, guarda histórico
    (3, N'Lisboa - Parque das Nações', 50.00, '2024-04-12', 1, NULL),         -- 9
    (3, N'Lisboa - Oriente',          150.00, '2024-08-30', 1, NULL),         -- 10
    (3, N'Lisboa - Belém',             22.00, '2025-03-18', 1, NULL),         -- 11
    (4, N'Guimarães - Centro',         22.00, '2024-07-22', 1, NULL),         -- 12
    (4, N'Guimarães - Norte',          50.00, '2025-05-14', 1, NULL);         -- 13

INSERT INTO Cliente (Nome, NIF, TipoCliente, DataNascimento, Email, Ativo) VALUES
    (N'Ana Silva',      '210345678', N'Particular',  '1985-03-12', N'ana.silva@mail.pt',    1),  -- 1
    (N'Bruno Costa',    '215678901', N'Particular',  '1992-07-25', N'bruno.costa@mail.pt',  1),  -- 2
    (N'Carla Mendes',   '218901234', N'Particular',  '1978-11-03', N'carla.mendes@mail.pt', 1),  -- 3
    (N'Diogo Ferreira', '221234567', N'Particular',  '2000-02-29', N'diogo.f@mail.pt',      1),  -- 4  data bissexta
    (N'TransNorte Lda', '501234567', N'Empresarial', NULL,         N'geral@transnorte.pt',  1),  -- 5  paga por outros
    (N'EcoFrota SA',    '502345678', N'Empresarial', NULL,         N'frota@ecofrota.pt',    1),  -- 6
    (N'Elsa Rocha',     '224567890', N'Particular',  '1995-06-18', N'elsa.rocha@mail.pt',   1),  -- 7  exatamente 1 carregamento
    (N'Filipe Nunes',   '227890123', N'Particular',  '1988-09-30', N'filipe.nunes@mail.pt', 1),  -- 8  zero carregamentos
    (N'Gabriela Pinto', '230123456', N'Particular',  '1999-12-05', N'gabriela.p@mail.pt',   0);  -- 9  cessou atividade

INSERT INTO Tarifario (Nome, Comercializado) VALUES
    (N'Normal',      1),   -- 1
    (N'Verde',       1),   -- 2
    (N'Empresarial', 1),   -- 3
    (N'Rápido',      0);   -- 4  descontinuado
GO


/* ---------------- DEPENDENTES ---------------- */

/* O Type 1 (id 4) não aparece: é um tipo do catálogo que a rede não tem. */
INSERT INTO PostoConector (IDPosto, IDTipoConector) VALUES
    (1,1),(1,2), (2,2), (3,2), (4,1),
    (5,1),(5,2), (6,2), (7,2),(7,3), (8,1),
    (9,2), (10,2), (11,1), (12,1), (13,2);

INSERT INTO Veiculo (IDCliente, Matricula, Marca, Modelo, Ativo) VALUES
    (1, N'AA-01-BB', N'Renault',  N'Zoe',     1),  -- 1
    (1, N'AA-02-CC', N'Nissan',   N'Leaf',    1),  -- 2
    (2, N'BB-11-CD', N'Tesla',    N'Model 3', 1),  -- 3
    (3, N'CC-22-DE', N'Peugeot',  N'e-208',   1),  -- 4
    (4, N'DD-33-EF', N'VW',       N'ID.3',    1),  -- 5
    (5, N'EE-44-FG', N'Mercedes', N'eVito',   1),  -- 6  carrinha da TransNorte
    (5, N'EE-45-FH', N'Mercedes', N'eVito',   1),  -- 7
    (6, N'FF-55-GH', N'Mercedes', N'eSprinter',1), -- 8
    (7, N'GG-66-HI', N'Opel',     N'Corsa-e', 1),  -- 9
    (8, N'HH-77-IJ', N'Hyundai',  N'Kona',    1),  -- 10 tem carro, nunca carregou
    (9, N'II-88-JK', N'BMW',      N'i3',      0);  -- 11

/* O Normal tem duas vigências, uma já fechada: é o que justifica esta tabela. */
INSERT INTO TarifarioPreco (IDTarifario, DataInicio, DataFim, PrecoKwh, TaxaAtivacao) VALUES
    (1, '2026-01-01', '2026-06-30', 0.2500, 0.00),
    (1, '2026-07-01', NULL,         0.2800, 0.00),   -- em vigor
    (2, '2026-01-01', NULL,         0.2200, 0.50),
    (3, '2026-01-01', NULL,         0.2000, 0.00),
    (4, '2026-01-01', '2026-05-31', 0.3500, 1.00);

INSERT INTO Reserva (IDCliente, IDPosto, DataHoraInicio, DataHoraFim, Estado, DataCriacao) VALUES
    (1, 1, '2026-02-10 09:00', '2026-02-10 11:00', N'Concretizada', '2026-02-08 18:22'),  -- 1
    (2, 6, '2026-03-05 14:00', '2026-03-05 15:30', N'Concretizada', '2026-03-04 10:15'),  -- 2
    (3, 9, '2026-04-12 08:00', '2026-04-12 09:00', N'Cancelada',    '2026-04-10 21:40'),  -- 3
    (4, 10,'2026-05-20 17:00', '2026-05-20 18:30', N'Concretizada', '2026-05-19 12:05'),  -- 4
    (1, 2, '2026-06-15 10:00', '2026-06-15 11:00', N'Expirada',     '2026-06-14 09:30'),  -- 5
    (5, 7, '2026-07-08 06:00', '2026-07-08 08:00', N'Concretizada', '2026-07-07 16:50'),  -- 6
    (6, 13,'2026-08-01 13:00', '2026-08-01 14:00', N'Concretizada', '2026-07-31 11:11'),  -- 7
    (3, 5, '2026-09-15 09:00', '2026-09-15 10:00', N'Ativa',        '2026-08-25 14:00');  -- 8

/* Distribuição desigual de propósito, para o TOP 10 do rel. 7 ter o que ordenar.
   Os postos 4, 9, 11 e 13 ficam com zero. */
INSERT INTO Ocorrencia (IDPosto, IDTipoAvaria, DataAbertura, Descricao, CustoIntervencao, Estado) VALUES
    (3, 1, '2026-01-15 08:30', N'Conector CCS2 não engata',            120.00, N'Resolvida'),
    (3, 2, '2026-02-02 14:10', N'Posto sem comunicação com a central',  80.00, N'Resolvida'),
    (3, 4, '2026-03-18 09:45', N'Disjuntor a disparar com carga alta', 340.00, N'Resolvida'),
    (3, 1, '2026-05-22 16:00', N'Cabo danificado',                     210.00, N'Resolvida'),
    (3, 3, '2026-08-11 07:20', N'Grafitos no ecrã',                      NULL, N'EmResolucao'),
    (6, 2, '2026-01-28 11:00', N'Perda intermitente de rede',            75.00, N'Resolvida'),
    (6, 4, '2026-04-05 13:30', N'Sobreaquecimento do módulo',          450.00, N'Resolvida'),
    (6, 1, '2026-06-19 10:15', N'Conector preso',                       95.00, N'Resolvida'),
    (6, 3, '2026-08-20 22:40', N'Tentativa de furto de cabo',            NULL, N'Aberta'),
    (1, 1, '2026-02-14 09:00', N'Conector Type 2 com folga',            60.00, N'Resolvida'),
    (1, 2, '2026-05-30 15:20', N'Leitura de energia inconsistente',    130.00, N'Resolvida'),
    (1, 4, '2026-08-25 08:05', N'Corte de energia no quadro',            NULL, N'EmResolucao'),
    (10,1, '2026-03-09 12:00', N'Conector CCS2 sujo',                   40.00, N'Resolvida'),
    (10,2, '2026-06-27 18:45', N'Sem ligação ao servidor',              90.00, N'Resolvida'),
    (10,4, '2026-08-14 07:30', N'Falha de fase',                         NULL, N'Aberta'),
    (5, 3, '2026-04-21 23:10', N'Vandalismo no painel',                280.00, N'Resolvida'),
    (5, 1, '2026-07-16 11:35', N'Conector com desgaste',                70.00, N'Resolvida'),
    (8, 4, '2026-02-25 06:50', N'Avaria elétrica grave',               620.00, N'Resolvida'),
    (8, 4, '2026-04-28 09:15', N'Avaria elétrica recorrente',          580.00, N'Resolvida'),
    (2, 2, '2026-05-11 16:25', N'Comunicação instável',                 85.00, N'Resolvida'),
    (7, 1, '2026-07-03 10:40', N'Conector CHAdeMO bloqueado',          150.00, N'Resolvida'),
    (12,3, '2026-08-05 21:00', N'Autocolantes no leitor de cartões',    25.00, N'Resolvida');
GO


/* ---------------- CARREGAMENTOS ----------------
   35 registos, quatro estados, vários meses.
   CustoTotal calculado com o preço em vigor na data:
     Normal 0.25 até 30-06 e 0.28 depois | Verde 0.22 + 0.50
     Empresarial 0.20 | Rápido 0.35 + 1.00 (só até 31-05)
   Nenhum usa o conector 3 nem o 4 — é isso que dá o órfão do rel. 1.
   ------------------------------------------------------------ */

INSERT INTO Carregamento (IDPosto, IDTipoConector, IDCliente, IDVeiculo, IDTarifario, IDReserva, DataHoraInicio, DataHoraFim, EnergiaKwh, CustoTotal, Estado) VALUES
    -- com reserva (o posto tem de coincidir com o da reserva)
    ( 1, 1, 1, 1, 1,    1, '2026-02-10 09:05', '2026-02-10 10:50', 38.400,  9.60, N'Faturado'),  -- 1
    ( 6, 2, 2, 3, 1,    2, '2026-03-05 14:10', '2026-03-05 15:25', 52.000, 13.00, N'Faturado'),  -- 2
    (10, 2, 4, 5, 1,    4, '2026-05-20 17:05', '2026-05-20 18:20', 61.200, 15.30, N'Faturado'),  -- 3
    ( 7, 2, 5, 6, 3,    6, '2026-07-08 06:10', '2026-07-08 07:55', 70.000, 14.00, N'Faturado'),  -- 4
    (13, 2, 6, 8, 3,    7, '2026-08-01 13:05', '2026-08-01 13:50', 33.500,  6.70, N'Faturado'),  -- 5  sem pagamento (rel. 5)

    -- espontâneos, faturados
    ( 1, 2, 1, 1, 1, NULL, '2026-01-12 08:30', '2026-01-12 09:40', 25.000,  6.25, N'Faturado'),  -- 6
    ( 2, 2, 3, 4, 2, NULL, '2026-01-25 18:00', '2026-01-25 19:10', 30.000,  7.10, N'Faturado'),  -- 7
    ( 5, 1, 2, 3, 1, NULL, '2026-02-03 11:20', '2026-02-03 12:50', 19.800,  4.95, N'Faturado'),  -- 8
    ( 3, 2, 4, 5, 4, NULL, '2026-02-18 15:00', '2026-02-18 15:35', 45.000, 16.75, N'Faturado'),  -- 9  tarifário Rápido
    ( 8, 1, 1, 2, 1, NULL, '2026-03-02 07:45', '2026-03-02 10:15', 18.000,  4.50, N'Faturado'),  -- 10 posto hoje desativado
    ( 6, 2, 5, 7, 3, NULL, '2026-03-14 09:00', '2026-03-14 10:05', 48.600,  9.72, N'Faturado'),  -- 11
    ( 9, 2, 3, 4, 2, NULL, '2026-03-27 13:30', '2026-03-27 14:40', 41.000,  9.52, N'Faturado'),  -- 12
    (12, 1, 4, 5, 1, NULL, '2026-04-08 10:00', '2026-04-08 12:00', 21.500,  5.38, N'Faturado'),  -- 13
    ( 3, 2, 2, 3, 4, NULL, '2026-04-19 16:20', '2026-04-19 16:55', 55.000, 20.25, N'Faturado'),  -- 14
    ( 5, 2, 6, 8, 3, NULL, '2026-05-06 08:15', '2026-05-06 10:15', 36.000,  7.20, N'Faturado'),  -- 15
    (10, 2, 1, 2, 1, NULL, '2026-05-28 19:00', '2026-05-28 19:45', 50.400, 12.60, N'Faturado'),  -- 16
    ( 2, 2, 9, 11,2, NULL, '2026-06-11 12:10', '2026-06-11 13:20', 28.000,  6.66, N'Faturado'),  -- 17
    ( 7, 2, 2, 6, 3, NULL, '2026-06-24 06:30', '2026-06-24 07:40', 65.000, 13.00, N'Faturado'),  -- 18 Bruno na carrinha da TransNorte
    (11, 1, 3, 4, 1, NULL, '2026-07-02 14:00', '2026-07-02 16:30', 22.000,  6.16, N'Faturado'),  -- 19
    ( 1, 1, 7, 9, 2, NULL, '2026-07-13 10:30', '2026-07-13 12:00', 24.000,  5.78, N'Faturado'),  -- 20 único da Elsa
    ( 6, 2, 2, 6, 3, NULL, '2026-07-21 08:00', '2026-07-21 09:10', 58.000, 11.60, N'Faturado'),  -- 21 idem

    -- terminados (medidos, ainda não faturados)
    ( 1, 2, 1, 2, 1, NULL, '2026-08-03 09:00', '2026-08-03 10:20', 27.500,  7.70, N'Terminado'),  -- 22
    ( 3, 2, 4, 5, 1, NULL, '2026-08-07 17:40', '2026-08-07 18:15', 62.000, 17.36, N'Terminado'),  -- 23
    ( 5, 1, 3, 4, 2, NULL, '2026-08-10 11:00', '2026-08-10 13:00', 20.000,  4.90, N'Terminado'),  -- 24
    ( 9, 2, 6, 8, 3, NULL, '2026-08-12 07:30', '2026-08-12 08:35', 44.000,  8.80, N'Terminado'),  -- 25
    (10, 2, 2, 3, 1, NULL, '2026-08-15 20:00', '2026-08-15 20:50', 53.000, 14.84, N'Terminado'),  -- 26
    (12, 1, 4, 5, 1, NULL, '2026-08-18 13:15', '2026-08-18 15:00', 19.000,  5.32, N'Terminado'),  -- 27
    ( 6, 2, 5, 7, 3, NULL, '2026-08-20 06:45', '2026-08-20 07:55', 47.000,  9.40, N'Terminado'),  -- 28
    ( 2, 2, 1, 2, 1, NULL, '2026-08-22 15:30', '2026-08-22 16:30', 31.000,  8.68, N'Terminado'),  -- 29
    (13, 2, 3, 4, 2, NULL, '2026-08-24 09:20', '2026-08-24 10:15', 35.000,  8.20, N'Terminado'),  -- 30
    ( 7, 2, 6, 8, 3, NULL, '2026-08-26 12:00', '2026-08-26 13:10', 68.000, 13.60, N'Terminado'),  -- 31

    -- em curso
    ( 1, 1, 1, 1, 1, NULL, '2026-08-29 08:30', NULL, NULL, NULL, N'EmCurso'),  -- 32
    (10, 2, 2, 3, 1, NULL, '2026-08-29 09:15', NULL, NULL, NULL, N'EmCurso'),  -- 33

    -- anulados
    ( 5, 2, 3, 4, 2, NULL, '2026-04-30 10:00', '2026-04-30 10:04',  0.200,  0.54, N'Anulado'),  -- 34
    (11, 1, 4, 5, 1, NULL, '2026-06-05 16:00', '2026-06-05 16:03',  0.100,  0.03, N'Anulado');  -- 35
GO


/* ---------------- FILHAS ---------------- */

/* O carregamento 5 fica sem pagamento (rel. 5).
   Os pagamentos do 18 e do 21 são da TransNorte, mas quem conduziu foi o
   Bruno: é a prova dos papéis.
   O carregamento 3 foi pago em duas prestações: prova o 1:N.
   Três ficam vencidos e por pagar; um fica por pagar mas dentro do prazo. */
INSERT INTO Pagamento (IDCarregamento, IDClientePagador, Valor, Metodo, DataEmissao, DataVencimento, DataPagamento) VALUES
    ( 1, 1,  9.60, N'Imediato', '2026-02-10', '2026-02-10', '2026-02-10'),
    ( 2, 2, 13.00, N'Imediato', '2026-03-05', '2026-03-05', '2026-03-05'),
    ( 3, 4, 15.30, N'Imediato', '2026-05-20', '2026-05-20', '2026-05-20'),
    ( 4, 5, 14.00, N'Mensal',   '2026-07-31', '2026-08-30', NULL),          -- por pagar, dentro do prazo
    ( 6, 1,  6.25, N'Imediato', '2026-01-12', '2026-01-12', '2026-01-12'),
    ( 7, 3,  7.10, N'Imediato', '2026-01-25', '2026-01-25', '2026-01-25'),
    ( 8, 2,  4.95, N'Imediato', '2026-02-03', '2026-02-03', '2026-02-03'),
    ( 9, 4, 16.75, N'Imediato', '2026-02-18', '2026-02-18', '2026-02-18'),
    (10, 1,  4.50, N'Imediato', '2026-03-02', '2026-03-02', '2026-03-02'),
    (11, 5,  9.72, N'Mensal',   '2026-03-31', '2026-04-30', '2026-04-12'),
    (12, 3,  9.52, N'Imediato', '2026-03-27', '2026-03-27', '2026-03-27'),
    (13, 4,  5.38, N'Imediato', '2026-04-08', '2026-04-08', '2026-04-08'),
    (14, 2, 20.25, N'Imediato', '2026-04-19', '2026-04-19', '2026-04-19'),
    (15, 6,  7.20, N'Mensal',   '2026-05-31', '2026-06-30', '2026-06-09'),
    (16, 1, 12.60, N'Imediato', '2026-05-28', '2026-05-28', '2026-05-28'),
    (20, 7,  5.78, N'Imediato', '2026-07-13', '2026-07-13', '2026-07-13'),
    (18, 5, 13.00, N'Mensal',   '2026-06-30', '2026-07-30', '2026-07-15'),  -- empresa paga por condutor
    ( 3, 4,  7.65, N'Imediato', '2026-05-20', '2026-05-20', '2026-05-20'),  -- 2.ª prestação
    (21, 5, 11.60, N'Mensal',   '2026-07-31', '2026-08-15', NULL),          -- em dívida
    (17, 9,  6.66, N'Imediato', '2026-06-11', '2026-06-26', NULL),          -- em dívida
    (19, 3,  6.16, N'Imediato', '2026-07-02', '2026-07-17', NULL);          -- em dívida

INSERT INTO CarregamentoHistorico (IDCarregamento, DataHora, EstadoAnterior, EstadoNovo, Observacao) VALUES
    ( 1, '2026-02-10 09:05', NULL,         N'EmCurso',   N'Sessão iniciada a partir de reserva'),
    ( 1, '2026-02-10 10:50', N'EmCurso',   N'Terminado', N'Carro desligado pelo cliente'),
    ( 1, '2026-02-10 11:02', N'Terminado', N'Faturado',  N'Fatura emitida'),
    (22, '2026-08-03 09:00', NULL,         N'EmCurso',   NULL),
    (22, '2026-08-03 10:20', N'EmCurso',   N'Terminado', N'Fim normal da sessão'),
    (32, '2026-08-29 08:30', NULL,         N'EmCurso',   N'Sessão a decorrer'),
    (34, '2026-04-30 10:00', NULL,         N'EmCurso',   NULL),
    (34, '2026-04-30 10:04', N'EmCurso',   N'Anulado',   N'Falha de comunicação');

INSERT INTO OcorrenciaHistorico (IDOcorrencia, DataHora, EstadoNovo, Observacao) VALUES
    ( 1, '2026-01-15 08:30', N'Aberta',      N'Reportado por cliente'),
    ( 1, '2026-01-15 14:00', N'EmResolucao', N'Técnico deslocado'),
    ( 1, '2026-01-16 10:20', N'Resolvida',   N'Conector substituído'),
    ( 5, '2026-08-11 07:20', N'Aberta',      N'Detetado em inspeção'),
    ( 5, '2026-08-12 09:00', N'EmResolucao', N'Limpeza agendada'),
    ( 9, '2026-08-20 22:40', N'Aberta',      N'Alarme noturno'),
    (18, '2026-02-25 06:50', N'Aberta',      NULL),
    (18, '2026-02-26 08:00', N'EmResolucao', N'Peça encomendada'),
    (18, '2026-03-04 15:30', N'Resolvida',   N'Módulo substituído');
GO


/* ------------------------------------------------------------
   Limpar só os dados (ordem inversa). O DELETE não repõe o
   IDENTITY — para isso, DBCC CHECKIDENT ou recriar a base.
   ------------------------------------------------------------ */

-- DELETE FROM OcorrenciaHistorico;   DELETE FROM CarregamentoHistorico;
-- DELETE FROM Pagamento;             DELETE FROM Carregamento;
-- DELETE FROM Ocorrencia;            DELETE FROM Reserva;
-- DELETE FROM TarifarioPreco;        DELETE FROM Veiculo;
-- DELETE FROM PostoConector;         DELETE FROM Tarifario;
-- DELETE FROM Cliente;               DELETE FROM Posto;
-- DELETE FROM TipoAvaria;            DELETE FROM TipoConector;
-- DELETE FROM Concelho;
