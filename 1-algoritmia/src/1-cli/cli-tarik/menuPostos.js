/*
  SUBMENU DE POSTOS  (Tarik)  —  PASSO 3
  ======================================

  Este e o PRIMEIRO submenu a fazer.
  Quando este funcionar, os outros tres sao copia com nomes trocados.

  ------------------------------------------------------------
  AS OPCOES:
  ------------------------------------------------------------
     1. Inserir posto
     2. Listar postos
     3. Atualizar posto
     4. Remover posto
     0. Voltar

  ------------------------------------------------------------
  ORDEM DE CONSTRUCAO (uma de cada vez, testando entre cada):
  ------------------------------------------------------------

  1o) LISTAR   <- comecar SEMPRE por aqui

      Porque? Porque e assim que verificas todo o resto.
      Sem o listar feito, nao sabes se o inserir funcionou.

      - pedir os postos ao repositorio
      - percorrer com um ciclo
      - mostrar cada um com console.log
      - se a lista estiver vazia, dizer "nao ha postos registados"
        (nao deixar o ecra em branco)

  2o) INSERIR

      - perguntar cada campo com prompt:
          codigo, concelho, potenciaKw, tipoConector, estado
      - a potencia e NUMERO -> envolver em Number()
      - campos com valores restritos (estado: ativo / manutencao)
        -> usar do...while, repetindo ate o valor ser valido
      - montar o objeto
      - chamar inserirPosto(objeto)
      - VERIFICAR O RETORNO: se devolver null foi recusado
        (codigo duplicado) -> mostrar mensagem de erro

  3o) ATUALIZAR

      - perguntar o codigo do posto a alterar
      - perguntar os campos novos
      - se a funcao devolver null, o posto nao existe -> avisar

  4o) REMOVER

      - perguntar o codigo
      - se devolver false ou null: ou nao existe, ou tem carregamentos
        associados (integridade referencial) -> avisar com clareza

  ------------------------------------------------------------
  ONDE SE VALIDA O QUE:
  ------------------------------------------------------------
    AQUI (no menu)   -> formato: e numero? esta na lista de valores?
    NO REPOSITORIO   -> duplicados e integridade
                        (so ele conhece todos os postos)

  ------------------------------------------------------------
  NAO ESQUECER:
  ------------------------------------------------------------
  - capturar SEMPRE o retorno das funcoes com =
  - o submenu tambem repete num ciclo; so sai no "0"
*/
