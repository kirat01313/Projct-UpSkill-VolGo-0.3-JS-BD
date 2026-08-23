import path from 'node:path'; //biblioteca do proprio node para definir caminhos de ficheiros
import { readFileSync, writeFileSync, existsSync } from 'node:fs'; //ler ficheiro, escrever ficheiro, verificar se existe ficheiro

const caminhoPostos = path.join(import.meta.dirname, '../../data/postos.json'); //define o endereço do ficheiro e o nome do 
                                                                                //ficheiro em uma constante

export function listarPostos() {
  if (!existsSync(caminhoPostos))                        //verifica se existe ficheiro naquele endereço/nome que indicamos 
    return [];                                           // se não existir retorna um array vazio e já sai da função, a linha a seguir nem chega a rodar
  const conteudo = readFileSync(caminhoPostos, 'utf-8'); //Caso exista já o ficheiro ele lê o conteudo 'utf-8' converte os dados para string
  if (conteudo.trim() === "")                            //se existir um ficheiro mas estiver vazio, faz o mesmo que antes, 
    return [];                                           //retorna um array vazio e já sai da função, a linha a seguir nem chega a rodar 
  return JSON.parse(conteudo);                           //Caso tenha algo, reconverte o texto para um array e retorna esse array
}






function gravarPostos(postos) {                                           //sem export. só usada aqui dentro pois reescreve nos dados o que foi alterado
  writeFileSync(caminhoPostos, JSON.stringify(postos, null, 2), 'utf-8'); //Função utilizada por outras funções
}





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
