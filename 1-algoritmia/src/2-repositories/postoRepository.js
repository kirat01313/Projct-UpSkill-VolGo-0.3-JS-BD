/*
  REPOSITÓRIO DE POSTOS  (Tarik)  —  PASSO 3
  ==========================================

  É o PRIMEIRO repositório a fazer. Quando este funcionar,
  os outros três seguem o mesmo molde.

  ------------------------------------------------------------
  CAMPOS DE UM POSTO
  ------------------------------------------------------------
     codigo         <- chave única (não pode repetir)
     concelho
     potenciaKw     <- número
     tipoConector
     estado         <- ativo | manutencao

  ------------------------------------------------------------
  AS 4 FUNÇÕES A ESCREVER
  ------------------------------------------------------------

  listarPostos()
      - ler o ficheiro data/postos.json
      - devolver os postos
      - se o ficheiro ainda não existir, devolver array vazio
        (não pode rebentar na primeira execução)

  inserirPosto(posto)
      - ler os postos que já existem
      - VALIDAR: campos obrigatórios preenchidos
      - VALIDAR: o código ainda não existe -> se existir, devolver null
      - acrescentar ao array
      - gravar o array de volta no ficheiro
      - devolver o posto inserido

  atualizarPosto(codigo, dadosNovos)
      - ler os postos
      - encontrar o que tem aquele código
      - se não existir -> devolver null
      - alterar os campos
      - gravar
      - devolver o posto atualizado

  removerPosto(codigo)
      - INTEGRIDADE REFERENCIAL: verificar PRIMEIRO se existem
        carregamentos associados a este posto.
        Se existirem -> NÃO remover, devolver false
      - senão: tirar do array, gravar, devolver true

  ------------------------------------------------------------
  O PADRÃO DE GRAVAÇÃO (é sempre o mesmo)
  ------------------------------------------------------------
      1. LER tudo do ficheiro
      2. ALTERAR o array em memória
      3. ESCREVER tudo de volta

  Não existe "acrescentar ao ficheiro" — reescreve-se sempre inteiro.

  ------------------------------------------------------------
  ATENÇÃO NA REMOÇÃO
  ------------------------------------------------------------
  A integridade referencial precisa dos CARREGAMENTOS, que são do Fred.
  Enquanto ele não tiver o dele pronto, criar um data/carregamentos.json
  à mão só para poder testar.
*/
