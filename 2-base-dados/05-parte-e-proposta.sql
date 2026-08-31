/* ============================================================
   VoltGo — 05 — Parte E: nova funcionalidade proposta
   ============================================================
   PROPOSTA. Não faz parte do modelo entregue.

   Este ficheiro é uma demonstração: aplica as alterações ao
   modelo, mostra a funcionalidade a funcionar sobre os dados de
   teste, e no fim tem o bloco para as reverter.

   Funcionalidade: ESTIMATIVA DO TEMPO DE CARREGAMENTO.
   Evolui o requisito diferenciador da Fase 1 (análise de desvios
   previsto/real), que media um erro que não conseguia corrigir
   por lhe faltarem dados do veículo.

   Correr depois do 01 e do 02.
   ============================================================ */

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
USE VoltGo;
GO


/* ============================================================
   1. ALTERAÇÕES AO MODELO
   ============================================================
   Cinco colunas, todas NULL. É deliberado: os veículos e os
   carregamentos que já existem continuam válidos, e os sete
   relatórios obrigatórios não mudam de resultado.
   ------------------------------------------------------------ */

/* No veículo: o que o carro é capaz de fazer. */
ALTER TABLE Veiculo ADD
    CapacidadeBateriaKwh  DECIMAL(6,2)  NULL,   -- para converter percentagem em kWh
    PotenciaMaxKw         DECIMAL(6,2)  NULL;   -- o carro também limita a velocidade
GO

ALTER TABLE Veiculo ADD
    CONSTRAINT CHK_Veiculo_Bateria CHECK (CapacidadeBateriaKwh IS NULL OR CapacidadeBateriaKwh > 0),
    CONSTRAINT CHK_Veiculo_PotMax  CHECK (PotenciaMaxKw        IS NULL OR PotenciaMaxKw        > 0);
GO

/* No carregamento: o que se pediu e o que se previu.
   O TempoEstimadoMin é gravado, não recalculado — pela mesma razão
   do CustoTotal, mas com outro argumento: para medir a qualidade de
   uma PREVISÃO é preciso guardar o que foi previsto na altura.
   Recalcular a posteriori, já com a energia real conhecida, mediria
   outra coisa qualquer. */
ALTER TABLE Carregamento ADD
    PercentagemInicial  TINYINT  NULL,
    PercentagemAlvo     TINYINT  NULL,
    TempoEstimadoMin    INT      NULL;
GO

ALTER TABLE Carregamento ADD
    CONSTRAINT CHK_Carreg_Percentagens
        CHECK ((PercentagemInicial IS NULL AND PercentagemAlvo IS NULL)
            OR (PercentagemInicial >= 0 AND PercentagemAlvo <= 100
                AND PercentagemAlvo > PercentagemInicial));
GO


/* ============================================================
   2. DADOS PARA A DEMONSTRAÇÃO
   ============================================================ */

/* Cinco veículos ficam com ficha técnica; os outros seis não.
   É o caso que prova a degradação suave: um carro sem estes dados
   continua a carregar, apenas sem estimativa. */
UPDATE Veiculo SET CapacidadeBateriaKwh = 52.00, PotenciaMaxKw =  22.00 WHERE IDVeiculo = 1;  -- Renault Zoe, só AC
UPDATE Veiculo SET CapacidadeBateriaKwh = 75.00, PotenciaMaxKw = 170.00 WHERE IDVeiculo = 3;  -- Tesla Model 3
UPDATE Veiculo SET CapacidadeBateriaKwh = 77.00, PotenciaMaxKw = 120.00 WHERE IDVeiculo = 5;  -- VW ID.3
UPDATE Veiculo SET CapacidadeBateriaKwh = 90.00, PotenciaMaxKw =  80.00 WHERE IDVeiculo = 6;  -- Mercedes eVito
UPDATE Veiculo SET CapacidadeBateriaKwh = 113.00, PotenciaMaxKw = 115.00 WHERE IDVeiculo = 8;  -- Mercedes eSprinter
GO

/* Sete carregamentos com estimativa registada no início.
   Escolhidos de propósito a cobrir potências muito diferentes. */
UPDATE Carregamento SET PercentagemInicial = 20, PercentagemAlvo = 94, TempoEstimadoMin = 105 WHERE IDCarregamento =  1;
UPDATE Carregamento SET PercentagemInicial = 45, PercentagemAlvo = 93, TempoEstimadoMin =  68 WHERE IDCarregamento =  6;
UPDATE Carregamento SET PercentagemInicial = 15, PercentagemAlvo = 84, TempoEstimadoMin =  62 WHERE IDCarregamento =  2;
UPDATE Carregamento SET PercentagemInicial = 20, PercentagemAlvo = 52, TempoEstimadoMin =  99 WHERE IDCarregamento = 15;
UPDATE Carregamento SET PercentagemInicial = 20, PercentagemAlvo = 90, TempoEstimadoMin =  21 WHERE IDCarregamento = 26;
UPDATE Carregamento SET PercentagemInicial = 15, PercentagemAlvo = 94, TempoEstimadoMin =  30 WHERE IDCarregamento =  3;
UPDATE Carregamento SET PercentagemInicial = 20, PercentagemAlvo = 98, TempoEstimadoMin =  53 WHERE IDCarregamento =  4;
GO


/* ============================================================
   3. A ESTIMATIVA
   ============================================================
       energia    = capacidade x (alvo - atual) / 100
       potencia   = a MENOR entre a do posto e a do carro
       tempo(min) = energia / potencia x 60

   A potência efetiva é o ponto central: hoje o modelo só conhece a
   do posto, e por isso não consegue prever nada para um carro que
   aceite menos do que ele. O Renault Zoe num posto de 150 kW carrega
   à mesma velocidade que num de 22.

   Em SQL Server o MIN() é de agregação, não compara duas colunas na
   mesma linha — daí o CASE.
   ------------------------------------------------------------ */

SELECT   c.IDCarregamento                                  AS id,
         v.Marca + ' ' + v.Modelo                          AS veiculo,
         p.Designacao                                      AS posto,
         p.PotenciaKw                                      AS kW_posto,
         v.PotenciaMaxKw                                   AS kW_carro,
         CASE WHEN p.PotenciaKw < v.PotenciaMaxKw
              THEN p.PotenciaKw ELSE v.PotenciaMaxKw END   AS kW_efetivo,
         CAST(v.CapacidadeBateriaKwh
              * (c.PercentagemAlvo - c.PercentagemInicial) / 100.0
              AS DECIMAL(6,2))                             AS energia_prevista,
         CAST(v.CapacidadeBateriaKwh
              * (c.PercentagemAlvo - c.PercentagemInicial) / 100.0
              / CASE WHEN p.PotenciaKw < v.PotenciaMaxKw
                     THEN p.PotenciaKw ELSE v.PotenciaMaxKw END
              * 60 AS INT)                                 AS minutos_calculados,
         c.TempoEstimadoMin                                AS minutos_gravados
FROM     Carregamento c
         INNER JOIN Veiculo v ON v.IDVeiculo = c.IDVeiculo
         INNER JOIN Posto   p ON p.IDPosto   = c.IDPosto
WHERE    c.PercentagemInicial IS NOT NULL
  AND    v.CapacidadeBateriaKwh IS NOT NULL
ORDER BY c.IDCarregamento;
GO


/* ============================================================
   4. DESVIO: PREVISTO CONTRA REAL
   ============================================================
   É o relatório da Fase 1, agora com uma previsão que conhece o
   carro — e comparado contra o que foi previsto NA ALTURA, não
   contra um número recalculado com o resultado já conhecido.
   ------------------------------------------------------------ */

SELECT   c.IDCarregamento                                                AS id,
         v.Marca + ' ' + v.Modelo                                        AS veiculo,
         p.PotenciaKw                                                    AS kW_posto,
         c.TempoEstimadoMin                                              AS previsto_min,
         DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim)               AS real_min,
         DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim)
             - c.TempoEstimadoMin                                        AS desvio_min
FROM     Carregamento c
         INNER JOIN Veiculo v ON v.IDVeiculo = c.IDVeiculo
         INNER JOIN Posto   p ON p.IDPosto   = c.IDPosto
WHERE    c.TempoEstimadoMin IS NOT NULL
  AND    c.DataHoraFim IS NOT NULL
ORDER BY desvio_min DESC;
GO


/* ============================================================
   5. O QUE ISTO REVELA
   ============================================================
   Agrupar os desvios por potência do posto mostra um padrão que a
   versão da Fase 1 não conseguia ver: quanto mais rápido é o posto,
   pior é a previsão.

   A razão é física — acima dos ~80% de bateria o carro corta a
   potência para se proteger. Num posto de 22 kW isso quase não se
   nota; num de 150 kW, a diferença entre a velocidade teórica e a
   real é enorme.

   Para a operadora isto tem duas consequências práticas:
     - a estimativa a mostrar ao cliente tem de ser corrigida por um
       fator que depende da potência, e não uma divisão simples
     - um posto cujo desvio médio se afaste muito dos outros da mesma
       potência é candidato a inspeção, mesmo sem ocorrência aberta
   ------------------------------------------------------------ */

SELECT   CASE WHEN p.PotenciaKw <= 22  THEN N'1 - ate 22 kW (AC)'
              WHEN p.PotenciaKw <= 50  THEN N'2 - 23 a 50 kW'
              ELSE                           N'3 - mais de 50 kW'
         END                                                             AS escalao_potencia,
         COUNT(*)                                                        AS carregamentos,
         AVG(DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim)
             - c.TempoEstimadoMin)                                       AS desvio_medio_min
FROM     Carregamento c
         INNER JOIN Posto p ON p.IDPosto = c.IDPosto
WHERE    c.TempoEstimadoMin IS NOT NULL
  AND    c.DataHoraFim IS NOT NULL
GROUP BY CASE WHEN p.PotenciaKw <= 22  THEN N'1 - ate 22 kW (AC)'
              WHEN p.PotenciaKw <= 50  THEN N'2 - 23 a 50 kW'
              ELSE                           N'3 - mais de 50 kW'
         END
ORDER BY escalao_potencia;
GO


/* ============================================================
   6. DEGRADAÇÃO SUAVE
   ============================================================
   Os veículos sem ficha técnica continuam a carregar normalmente.
   A funcionalidade é opcional, não bloqueia nada — e é por isso que
   as cinco colunas admitem NULL.
   ------------------------------------------------------------ */

SELECT   v.Matricula,
         v.Marca + ' ' + v.Modelo                    AS veiculo,
         CASE WHEN v.CapacidadeBateriaKwh IS NULL
              THEN N'sem ficha - carrega sem estimativa'
              ELSE N'com ficha - estimativa disponivel'
         END                                         AS situacao,
         COUNT(c.IDCarregamento)                     AS carregamentos
FROM     Veiculo v
         LEFT JOIN Carregamento c ON c.IDVeiculo = v.IDVeiculo
GROUP BY v.Matricula, v.Marca, v.Modelo, v.CapacidadeBateriaKwh
ORDER BY situacao, v.Matricula;
GO


/* ============================================================
   7. AUDITORIA QUE SÓ ESTA PROPOSTA TORNA POSSÍVEL
   ============================================================
   Com a ficha técnica do veículo, passam a poder detetar-se erros
   de registo que o modelo entregue NÃO consegue ver, porque só
   conhece a potência do posto:

     - energia acima do que o CARRO aceita naquele tempo
       (um posto de 150 kW aceita 100 kWh numa hora; um Renault Zoe
        não, mesmo ligado a esse posto)
     - energia acima da CAPACIDADE da bateria
       (não se põem 68 kWh num carro de 42)

   Isto não é hipotético: ao preparar os dados de teste, estas duas
   verificações apanharam quatro registos incoerentes que tinham
   passado por todas as restrições do modelo. Foram corrigidos.

   Hoje devolvem zero — que é o resultado que se quer.
   ------------------------------------------------------------ */

SELECT   N'Energia acima do que o carro aceita' AS problema,
         c.IDCarregamento AS id, v.Marca + ' ' + v.Modelo AS veiculo,
         v.PotenciaMaxKw AS kW_carro, c.EnergiaKwh AS energia,
         CAST(c.EnergiaKwh / (DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim)/60.0) AS DECIMAL(6,2)) AS kW_medio
FROM     Carregamento c
         INNER JOIN Veiculo v ON v.IDVeiculo = c.IDVeiculo
WHERE    c.DataHoraFim IS NOT NULL AND c.EnergiaKwh > 0
  AND    v.PotenciaMaxKw IS NOT NULL
  AND    c.EnergiaKwh > v.PotenciaMaxKw * DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim)/60.0

UNION ALL

SELECT   N'Energia acima da capacidade da bateria',
         c.IDCarregamento, v.Marca + ' ' + v.Modelo,
         v.CapacidadeBateriaKwh, c.EnergiaKwh, NULL
FROM     Carregamento c
         INNER JOIN Veiculo v ON v.IDVeiculo = c.IDVeiculo
WHERE    c.EnergiaKwh IS NOT NULL
  AND    v.CapacidadeBateriaKwh IS NOT NULL
  AND    c.EnergiaKwh > v.CapacidadeBateriaKwh;
GO


/* ============================================================
   8. REVERTER
   ============================================================
   Repõe o modelo entregue. As restrições têm de sair antes das
   colunas: uma coluna não se apaga enquanto houver uma restrição
   a mencioná-la.
   ------------------------------------------------------------ */

-- ALTER TABLE Carregamento DROP CONSTRAINT CHK_Carreg_Percentagens;
-- ALTER TABLE Carregamento DROP COLUMN PercentagemInicial, PercentagemAlvo, TempoEstimadoMin;
-- ALTER TABLE Veiculo DROP CONSTRAINT CHK_Veiculo_Bateria, CHK_Veiculo_PotMax;
-- ALTER TABLE Veiculo DROP COLUMN CapacidadeBateriaKwh, PotenciaMaxKw;
-- GO
