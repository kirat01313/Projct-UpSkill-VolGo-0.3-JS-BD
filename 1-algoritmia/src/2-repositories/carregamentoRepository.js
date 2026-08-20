/*
  REPOSITÓRIO DE CARREGAMENTOS  (Fred)
  ====================================

  É a ENTIDADE PRINCIPAL do trabalho. Aponta para as outras três.

  ------------------------------------------------------------
  CAMPOS
  ------------------------------------------------------------
     posto            <- o CÓDIGO de um posto
     cliente          <- o NIF de um cliente
     tarifario        <- o NOME de um tarifário
     dataHoraInicio
     dataHoraFim
     energiaKwh       <- número
     custo            <- número
     estado           <- em curso | terminado | faturado | anulado

  ------------------------------------------------------------
  AS 4 FUNÇÕES
  ------------------------------------------------------------
     listarCarregamentos()
     inserirCarregamento(carregamento)
     atualizarCarregamento(id, dados)
     removerCarregamento(id)

  NOTA: este NÃO precisa de integridade referencial na remoção.
  Porquê? Porque ninguém aponta para um carregamento — é ele que
  aponta para os outros. Só está protegido quem está na ponta da seta.

  ------------------------------------------------------------
  COMO IDENTIFICAR UM CARREGAMENTO?
  ------------------------------------------------------------
  As outras entidades têm chave natural (codigo, NIF, nome).
  Um carregamento não tem. É preciso decidir e combinar:

     - um campo "id" numérico que vai aumentando, ou
     - a combinação posto + cliente + dataHoraInicio

  Sugestão: um id simples. É preciso para o atualizar e o remover.

  ------------------------------------------------------------
  ESTE FICHEIRO É USADO PELO TARIK TAMBÉM
  ------------------------------------------------------------
  A integridade dos postos e clientes precisa de ler os carregamentos,
  e o relatório 4.2 também.

  Combinar bem os nomes dos campos — se um escrever energiaKwh e o
  outro ler energia, dá undefined e ninguém percebe porquê.
*/
