import path from 'node:path'; //biblioteca do proprio node para definir caminhos de ficheiros
import { readFileSync, writeFileSync, existsSync } from 'node:fs'; //ler ficheiro, escrever ficheiro, verificar se existe ficheiro
import { listarCarregamentos } from './carregamentoRepository.js'; //importa a função listarCarregamentos do repositório de carregamentos para verificar integridade referencial

const caminhoPostos = path.join(import.meta.dirname, '../../data/postos.json'); //define o endereço do ficheiro e o nome do ficheiro em uma constante


export function listarPostos() {
    if (!existsSync(caminhoPostos))                        //verifica se existe ficheiro naquele endereço/nome que indicamos 
        return [];                                           // se não existir retorna um array vazio e já sai da função, a linha a seguir nem chega a rodar
    const conteudo = readFileSync(caminhoPostos, 'utf-8'); //Caso exista já o ficheiro ele lê o conteudo 'utf-8' converte os dados para string
    if (conteudo.trim() === "")                            //se existir um ficheiro mas estiver vazio, faz o mesmo que antes, 
        return [];                                           //retorna um array vazio e já sai da função, a linha a seguir nem chega a rodar 
    return JSON.parse(conteudo);                           //Caso tenha algo, reconverte o texto para um array e retorna esse array
}

export function procurarPosto1(codigo) { //Função que procura um posto pelo código, devolvendo o objeto do posto se encontrado, ou null se não encontrado
    const postos = listarPostos();
    for (let i = 0; i < postos.length; i++) {
        if (postos[i].codigo === codigo) return postos[i];
    }
    return null;
}

export function inserirPosto1(posto) {
    if (procurarPosto1(posto.codigo) !== null) return null;   //se já existir um posto com o mesmo código, devolve null
    const postos = listarPostos(); //chama a função listarPostos() para pegar o array de postos já existentes
    postos.push(posto); //acrescenta o novo posto ao array de postos
    gravarPostos(postos); //chama a função gravarPostos() para gravar o array atualizado no ficheiro
    return posto; //devolve o posto inserido
}

export function alterarPosto1(codigo, dadosNovos) {
    const postos = listarPostos(); //chama a função listarPostos() para pegar o array de postos já existentes
    let postoIndex = -1;
    for (let i = 0; i < postos.length; i++) { //percorre o array de postos para encontrar o posto com o código fornecido
        if (postos[i].codigo === codigo) { //se encontrar, guarda o índice do posto no array
            postoIndex = i; //guarda o índice do posto no array
            break;
        }
    }
    if (postoIndex === -1) {//se não encontrar, devolve null (essa parte parece duplicada com a parte do menuPostos.js)
        return null;
    } else { //se encontrar, atualiza os campos do posto com os dados novos fornecidos mas não altera o código (que é a chave)
        postos[postoIndex].concelho = dadosNovos.concelho;
        postos[postoIndex].potenciaKw = dadosNovos.potenciaKw;
        postos[postoIndex].tipoConector = dadosNovos.tipoConector;
        postos[postoIndex].estado = dadosNovos.estado;
        gravarPostos(postos); //chama a função gravarPostos() para gravar o array atualizado no ficheiro
        return postos[postoIndex]; //devolve o posto atualizado
    }
}

export function excluirPosto1(codigo) {
    const carregamentos = listarCarregamentos(); //
    for (let i = 0; i < carregamentos.length; i++) { //
        if (carregamentos[i].posto.toLowerCase() === codigo.toLowerCase()) return false;
    }

    const postos = listarPostos(); //chama a função listarPostos() para pegar o array de postos já existentes
    const restantes = []; //cria um array vazio para guardar os postos que não serão excluídos
    for (let i = 0; i < postos.length; i++) {
        if (postos[i].codigo !== codigo) {     //se o código do posto atual não for igual ao código fornecido, adiciona o posto ao array de restantes
            restantes.push(postos[i]);
        }
    }
    if (restantes.length === postos.length) return false;   //se o array de restantes tiver o mesmo tamanho que o array original, significa que não encontrou o posto com o código fornecido, então devolve false
    gravarPostos(restantes); //chama a função gravarPostos() para gravar o array de restantes no ficheiro, sobrescrevendo o array original
    return true; //devolve true, indicando que o posto foi excluído com sucesso
}

function gravarPostos(postos) { //Função que grava/regrava o array de postos no ficheiro
    writeFileSync(caminhoPostos, JSON.stringify(postos, null, 2), 'utf-8'); //writeFileSync() cria o ficheiro se não existir, ou sobrescreve se já existir. JSON.stringify() converte 
    //o array de postos em string, com indentação de 2 espaços para melhor leitura
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
