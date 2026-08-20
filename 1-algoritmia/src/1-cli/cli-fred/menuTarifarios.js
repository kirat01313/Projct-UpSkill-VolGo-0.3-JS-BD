/*
  SUBMENU DE TARIFARIOS  (Fred)
  =============================

  Sugestao: comecar por este. E a entidade mais simples do projeto
  (so 3 campos), por isso e onde se aprende o padrao com menos ruido.

  ------------------------------------------------------------
  CAMPOS A PEDIR:
  ------------------------------------------------------------
     nome           <- chave unica (nao pode repetir)
     precoPorKwh    <- NUMERO, tem de ser positivo
     taxaAtivacao   <- NUMERO, pode ser 0

  ------------------------------------------------------------
  ESTRUTURA (igual a de todos os submenus):
  ------------------------------------------------------------
     1. Inserir  2. Listar  3. Atualizar  4. Remover  0. Voltar

  Fazer o LISTAR primeiro — e assim que se verifica tudo o resto.

  ------------------------------------------------------------
  NAO ESQUECER:
  ------------------------------------------------------------
  - precos sao NUMEROS -> Number() e validar que sao positivos
  - no REMOVER: integridade referencial
    (nao remover um tarifario que esteja a ser usado por algum carregamento)
*/
