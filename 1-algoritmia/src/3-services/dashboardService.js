/*
  DASHBOARD  —  PASSO 5  (em conjunto)
  ====================================

  Vale 10% da nota. É mostrado ao ARRANCAR a aplicação, por cima do menu.

  ------------------------------------------------------------
  OS 3 INDICADORES (secção 3 do enunciado)
  ------------------------------------------------------------

  1) Quantidade de carregamentos EM CURSO e TERMINADOS
     -> dois contadores simples

  2) Quantidade + ENERGIA MÉDIA (kWh) por POSTO
     -> ATENÇÃO: só conta os de estado "terminado"

  3) Quantidade + RECEITA MÉDIA por TARIFÁRIO
     -> ATENÇÃO: só conta os de estado "faturado"

  ------------------------------------------------------------
  O ERRO MAIS FÁCIL DE COMETER AQUI
  ------------------------------------------------------------
  Cada indicador tem um FILTRO DE ESTADO DIFERENTE.

  O indicador 2 ignora os faturados.
  O indicador 3 ignora os terminados.

  Ler mal isto é o erro mais provável nesta parte.

  ------------------------------------------------------------
  COMO SE CALCULA CADA UM
  ------------------------------------------------------------

  Indicador 1:
     percorrer os carregamentos, contar quantos têm cada estado

  Indicador 2:
     para cada posto:
        percorrer os carregamentos TERMINADOS desse posto
        contar quantos e somar a energia
        média = somaEnergia / quantidade

  Indicador 3:
     igual, mas por tarifário, filtrando FATURADO,
     e somando o CUSTO em vez da energia

  É o padrão do acumulador (soma + contador -> dividir no fim),
  aplicado três vezes com filtros diferentes.

  ------------------------------------------------------------
  NÃO ESQUECER
  ------------------------------------------------------------
  Guarda de divisão por zero: se um posto não tiver carregamentos
  terminados, 0/0 dá NaN. Verificar a quantidade antes de dividir.

  ------------------------------------------------------------
  SUGESTÃO DE DIVISÃO
  ------------------------------------------------------------
     Indicador 2 (por posto)      -> Tarik   (os postos são dele)
     Indicador 3 (por tarifário)  -> Fred    (os tarifários são dele)
     Indicador 1                  -> quem chegar primeiro

  ------------------------------------------------------------
  O QUE DEVOLVER
  ------------------------------------------------------------
  Uma função só pode devolver UMA coisa. Para devolver vários valores,
  embrulham-se num objeto:

     { emCurso, terminados, porPosto, porTarifario }

  O menu recebe esse objeto e imprime cada parte.
*/
