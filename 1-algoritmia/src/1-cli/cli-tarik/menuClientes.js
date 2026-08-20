/*
  SUBMENU DE CLIENTES  (Tarik)  —  PASSO 4
  ========================================

  So fazer DEPOIS do menuPostos.js estar a funcionar.
  E a mesma estrutura; o que muda sao os campos e as validacoes.

  ------------------------------------------------------------
  CAMPOS A PEDIR:
  ------------------------------------------------------------
     nome
     nif              <- chave unica (nao pode repetir)
     dataNascimento   <- necessaria para calcular a IDADE no relatorio 4.2
     contacto
     matricula

  ------------------------------------------------------------
  VALIDACOES ESPECIFICAS:
  ------------------------------------------------------------
  - NIF: 9 digitos
  - dataNascimento: tem de ser uma data valida

  ATENCAO ao campo dataNascimento: sem ele nao ha relatorio 4.2.

  ------------------------------------------------------------
  NOTA SOBRE O NIF:
  ------------------------------------------------------------
  O NIF fica guardado como TEXTO, nao como numero.
  Razao: nao se fazem contas com NIFs, e assim nao se perdem
  eventuais zeros a esquerda.
*/
