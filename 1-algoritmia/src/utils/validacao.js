/*
  UTILS / VALIDAÇÃO
  =================

  Ferramentas GENÉRICAS, usadas por todos.
  Vai-se acrescentando conforme a necessidade aparece — não escrever
  tudo de uma vez.

  ------------------------------------------------------------
  O QUE VAI AQUI vs. O QUE NÃO VAI
  ------------------------------------------------------------

  VAI:    funções que serviriam em QUALQUER projeto
          (validar campo vazio, validar data, validar número positivo)

  NÃO VAI: funções específicas de uma entidade
          (criarCliente, listarPostos — essas ficam no repositório dela)

  A regra: código que só serve uma entidade fica COM essa entidade.

  ------------------------------------------------------------
  FUNÇÕES QUE VÃO SER PRECISAS
  ------------------------------------------------------------

  campoObrigatorio(valor)
      -> true se tem conteúdo, false se está vazio ou só espaços
      USADA EM: todos os "inserir", antes de gravar

  valorPositivo(valor)
      -> true se é número maior que 0
      USADA EM: potenciaKw (postos), precoPorKwh (tarifários),
                energiaKwh e custo (carregamentos)

  dataValida(valor)
      -> true se é uma data que existe
      USADA EM: dataNascimento (clientes),
                dataHoraInicio / dataHoraFim (carregamentos)

  nifValido(nif)
      -> true se tem 9 dígitos
      USADA EM: inserirCliente

  ------------------------------------------------------------
  SUGESTÃO: uma função de leitura validada
  ------------------------------------------------------------
  Se derem por vocês a repetir o mesmo do...while em todos os menus
  ("repete até o valor estar na lista"), vale a pena extrair para aqui
  uma função tipo:

      lerOpcaoValida(mensagem, listaDeValoresValidos)

  MAS: só fazer isso DEPOIS de sentirem a repetição.
  Escrever a abstração antes do problema aparecer só complica.

  ------------------------------------------------------------
  ONDE SE VALIDA O QUÊ (importante)
  ------------------------------------------------------------
     NO MENU          -> formato (é número? está na lista?)
     NO REPOSITÓRIO   -> duplicados e integridade
                         (só ele conhece todos os registos)
*/
