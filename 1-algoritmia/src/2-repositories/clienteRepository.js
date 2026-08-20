/*
  REPOSITÓRIO DE CLIENTES  (Tarik)  —  PASSO 4
  ============================================

  Mesmo molde do postoRepository.js.
  Fazer só depois desse estar a funcionar.

  ------------------------------------------------------------
  CAMPOS DE UM CLIENTE
  ------------------------------------------------------------
     nome
     nif              <- chave única (não pode repetir)
     dataNascimento   <- necessária para a IDADE no relatório 4.2
     contacto
     matricula

  ------------------------------------------------------------
  AS 4 FUNÇÕES
  ------------------------------------------------------------
     listarClientes()
     inserirCliente(cliente)         <- validar NIF (9 dígitos) e duplicados
     atualizarCliente(nif, dados)
     removerCliente(nif)             <- integridade: não remover cliente
                                        com carregamentos associados

  ------------------------------------------------------------
  FICHEIRO DE DADOS
  ------------------------------------------------------------
     data/clientes.json   <- criar à mão, com 2-3 clientes de exemplo

  Dica: usar datas de nascimento variadas (alguém mais novo, alguém
  mais velho) para testar o cálculo da idade no relatório 4.2.

  ------------------------------------------------------------
  NOTA SOBRE O NIF
  ------------------------------------------------------------
  Guardar como TEXTO, não como número.
  Não se fazem contas com NIFs, e assim não se perdem zeros à esquerda.
*/
