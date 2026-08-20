/*
  SUBMENU DE CARREGAMENTOS  (Fred)
  ================================

  E a ENTIDADE PRINCIPAL do trabalho, e a mais trabalhosa.
  Deixar para depois dos tarifarios estarem a funcionar.

  ------------------------------------------------------------
  CAMPOS A PEDIR:
  ------------------------------------------------------------
     posto            <- o CODIGO de um posto que ja exista
     cliente          <- o NIF de um cliente que ja exista
     tarifario        <- o NOME de um tarifario que ja exista
     dataHoraInicio
     dataHoraFim
     energiaKwh       <- NUMERO
     custo            <- NUMERO
     estado           <- em curso | terminado | faturado | anulado

  ------------------------------------------------------------
  DUAS COISAS IMPORTANTES:
  ------------------------------------------------------------

  1) GUARDAR SO O IDENTIFICADOR, nunca o objeto inteiro.

     Certo:   posto: "P001"
     Errado:  posto: { codigo: "P001", concelho: "Braga", ... }

     Porque? Se o objeto inteiro for copiado para dentro do carregamento,
     e depois alguem alterar o posto, o carregamento fica com dados velhos.

  2) OS ESTADOS TEM DE SER ESCRITOS EXATAMENTE IGUAL em todo o lado.

     O dashboard e os relatorios filtram por estes valores.
     Se um escrever Terminado e outro terminado, nada bate certo.

     Sugestao: do...while com a lista dos 4 estados validos,
     e passar sempre por .trim().toLowerCase().

  ------------------------------------------------------------
  VALIDACAO EXTRA (especifica desta entidade):
  ------------------------------------------------------------
  Ao inserir, verificar se o posto / cliente / tarifario indicados
  EXISTEM mesmo. Senao cria-se um carregamento que aponta para o vazio —
  exatamente o problema que a integridade referencial evita.
*/
