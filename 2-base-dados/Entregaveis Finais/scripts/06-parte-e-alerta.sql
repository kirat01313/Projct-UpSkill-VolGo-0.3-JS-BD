/* ============================================================================
   VoltGo — 06 — Nova funcionalidade: ALERTA                         PARTE E
   ============================================================================
   Correr depois do 01 e do 02.

   O enunciado pede quatro coisas para esta parte: descrição funcional, regras
   de negócio, impacto esperado e alterações ao modelo. Estão as quatro aqui em
   baixo, e a seguir a implementação.

   ============================================================================
   1. DESCRIÇÃO FUNCIONAL
   ============================================================================
   O sistema passa a detetar carregamentos cuja energia registada é impossível
   para o posto onde foram feitos — mais energia do que o equipamento consegue
   debitar no tempo que a sessão durou.

   Cada deteção fica guardada como um ALERTA, com um estado próprio: alguém o
   analisa e classifica-o como justificado (erro de medição conhecido) ou
   confirmado (problema real no posto ou no registo).

   ============================================================================
   2. REGRAS DE NEGÓCIO
   ============================================================================
   1. Um carregamento é suspeito se:   EnergiaKwh > PotenciaKw x horas
   2. Só se avaliam sessões terminadas: uma sessão em curso ainda não tem
      energia final.
   3. O alerta NÃO impede o registo. A energia foi entregue a alguém; recusar
      o carregamento fazia o problema desaparecer, que é o contrário do que se
      quer. Regista-se e sinaliza-se.
   4. Cada alerta tem um ciclo de vida: Aberto -> Justificado ou Confirmado.

   ============================================================================
   3. IMPACTO ESPERADO
   ============================================================================
   · Um posto com alertas repetidos passa a ser candidato a inspeção antes de
     avariar. Hoje só se sabe que um posto tem problema quando alguém abre uma
     ocorrência — ou seja, quando já avariou.
   · Impede que se fature energia que não foi entregue.
   · Dá à operação uma fila de trabalho concreta, em vez de um relatório que
     alguém tem de se lembrar de correr.

   ============================================================================
   4. ALTERAÇÕES AO MODELO RELACIONAL
   ============================================================================
   Uma tabela nova: Alerta (criada no script 01).

       IDAlerta          identificador
       IDCarregamento    o carregamento suspeito
       DataDetecao       quando foi detetado
       EnergiaRegistada  o que o carregamento diz ter entregue
       EnergiaMaxima     o que o posto conseguiria entregar
       Estado            Aberto / Justificado / Confirmado

   Nenhuma tabela existente muda. Nenhum dos sete relatórios obrigatórios muda
   de resultado. A funcionalidade acrescenta, não interfere.

   PORQUE OS DOIS VALORES FICAM GUARDADOS
   A EnergiaRegistada e a EnergiaMaxima são congeladas no momento da deteção.
   Se amanhã alguém corrigir a potência do posto, o alerta antigo continua a
   poder ser explicado — caso contrário passaria a parecer um erro do sistema.

   PORQUE É UMA TABELA E NÃO SÓ UMA CONSULTA
   Uma consulta devolve sempre o mesmo e não guarda nada. O alerta precisa de
   memória: quem o viu e o que decidiu. Sem tabela, a mesma anomalia voltava a
   aparecer todos os dias, já analisada, e ninguém sabia disso.

   ============================================================================
   CONTINUIDADE COM A FASE 1
   ============================================================================
   Evolui a rotina de auditoria da aplicação de consola (analiseService.js),
   que percorria os carregamentos à procura de registos incoerentes.

     Fase 1   um ciclo em JavaScript, corrido a pedido, sem memória.
     Fase 2   a mesma verificação em SQL, e o resultado da análise humana fica
              guardado na base de dados.
   ============================================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE VoltGo;
GO

-- PASSO 1 — VER OS CARREGAMENTOS IMPOSSÍVEIS

SELECT   c.IDCarregamento,
         p.Codigo                                    AS Posto,
         p.PotenciaKw,
         c.DataHoraInicio,
         c.DataHoraFim,
         c.EnergiaKwh                                AS EnergiaRegistada,
         CAST(p.PotenciaKw * (DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim) / 60.0)
              AS DECIMAL(8,3))                       AS EnergiaMaxima
FROM     Carregamento c
         INNER JOIN PostoConector pc ON pc.IDPostoConector = c.IDPostoConector
         INNER JOIN Posto         p  ON p.IDPosto          = pc.IDPosto
WHERE    c.DataHoraFim IS NOT NULL                   -- regra 2: só as terminadas
  AND    c.EnergiaKwh > p.PotenciaKw * (DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim) / 60.0)
ORDER BY c.IDCarregamento;
GO

-- PASSO 2 — REGISTAR OS ALERTAS

INSERT INTO Alerta (IDCarregamento, EnergiaRegistada, EnergiaMaxima)
SELECT   c.IDCarregamento,
         c.EnergiaKwh,
         CAST(p.PotenciaKw * (DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim) / 60.0)
              AS DECIMAL(8,3))
FROM     Carregamento c
         INNER JOIN PostoConector pc ON pc.IDPostoConector = c.IDPostoConector
         INNER JOIN Posto         p  ON p.IDPosto          = pc.IDPosto
WHERE    c.DataHoraFim IS NOT NULL
  AND    c.EnergiaKwh > p.PotenciaKw * (DATEDIFF(MINUTE, c.DataHoraInicio, c.DataHoraFim) / 60.0)

  AND    c.IDCarregamento NOT IN (SELECT IDCarregamento FROM Alerta);
GO

-- PASSO 3 — A FILA DE TRABALHO

SELECT   a.IDAlerta,
         a.IDCarregamento,
         p.Codigo                                AS Posto,
         p.PotenciaKw,
         a.EnergiaRegistada,
         a.EnergiaMaxima,
         a.EnergiaRegistada - a.EnergiaMaxima    AS Excesso,
         a.Estado
FROM     Alerta a
         INNER JOIN Carregamento  c  ON c.IDCarregamento    = a.IDCarregamento
         INNER JOIN PostoConector pc ON pc.IDPostoConector  = c.IDPostoConector
         INNER JOIN Posto         p  ON p.IDPosto           = pc.IDPosto
ORDER BY Excesso DESC;
GO

-- PASSO 4 — O CICLO DE VIDA

UPDATE Alerta
SET    Estado = N'Justificado'
WHERE  IDAlerta = (SELECT MIN(IDAlerta) FROM Alerta);

UPDATE Alerta
SET    Estado = N'Confirmado'
WHERE  IDAlerta = (SELECT MAX(IDAlerta) FROM Alerta);
GO

SELECT   Estado, COUNT(*) AS Quantos
FROM     Alerta
GROUP BY Estado
ORDER BY Estado;
GO

-- PASSO 5 — POSTOS COM MAIS ALERTAS

SELECT   p.Codigo                  AS Posto,
         p.NomePosto,
         p.PotenciaKw,
         COUNT(a.IDAlerta)         AS Alertas
FROM     Posto p
         INNER JOIN PostoConector pc ON pc.IDPosto          = p.IDPosto
         INNER JOIN Carregamento  c  ON c.IDPostoConector   = pc.IDPostoConector
         INNER JOIN Alerta        a  ON a.IDCarregamento    = c.IDCarregamento
GROUP BY p.Codigo, p.NomePosto, p.PotenciaKw
ORDER BY Alertas DESC;
GO
