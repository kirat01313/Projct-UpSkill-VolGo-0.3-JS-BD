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

import path from 'node:path';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { campoObrigatorio, dataHoraValida } from '../utils/validacao.js';
import { listarPostos } from './postoRepository.js';
import { listarTarifarios } from './tarifarioRepository.js';
import { listarClientes } from './clienteRepository.js';

const caminhoCarregamentos = path.join(import.meta.dirname, '../../data/carregamentos.json');   //define o caminho do arquivo JSON que armazenará os dados dos carregamentos

export function listarCarregamentos() {                                                         // lista todos os carregamentos do repositório
  if (!existsSync(caminhoCarregamentos)) return [];                                             //verifica se o arquivo de carregamentos existe; se não existir, retorna um array vazio
  const conteudo = readFileSync(caminhoCarregamentos, 'utf-8');                                 //verifica se o arquivo de carregamentos existe; se não existir, retorna um array vazio
  if (conteudo.trim() === '') return [];                                                        //verifica se o conteúdo do arquivo está vazio; se estiver, retorna um array vazio
  return JSON.parse(conteudo);                                                                  //converte a string JSON em um array de objetos e retorna esse array
}

function gravarCarregamentos(carregamentos) {                                                   //converte o array de objetos em uma string JSON formatada e grava no arquivo de carregamentos
  writeFileSync(caminhoCarregamentos, JSON.stringify(carregamentos, null, 2), 'utf-8');         //converte o array de objetos em uma string JSON formatada e grava no arquivo de carregamentos
}

export function inserirCarregamento(novoCarregamento) {
  if (!campoObrigatorio(novoCarregamento.posto)) {
    return null; // posto vazio, recusa
  }
  if (!campoObrigatorio(novoCarregamento.cliente)) {
    return null; // cliente vazio, recusa
  }
  if (!campoObrigatorio(novoCarregamento.tarifario)) {
    return null; // tarifário vazio, recusa
  }
  if (!campoObrigatorio(novoCarregamento.dataHoraInicio)) {
    return null; // data de início vazia, recusa
  }
  if (!dataHoraValida(novoCarregamento.dataHoraInicio)) {                                 // verifica se o texto tem data E hora completas no formato AAAA-MM-DD HH:mm
    return null; // data/hora de início inválida ou incompleta, recusa
  }

  // Integridade referencial "na entrada": posto e tarifário precisam existir de facto
  const postos = listarPostos();                                                          // busca todos os postos já cadastrados
  let postoEncontrado = null;                                                              // guarda o posto encontrado (não só um booleano, porque também precisamos do estado dele)
  for (let i = 0; i < postos.length; i++) {                                                // percorre todos os postos existentes
    if (postos[i].codigo.toLowerCase() === novoCarregamento.posto.toLowerCase()) {         // compara o código do posto com o que veio no carregamento, ignorando maiúsculas/minúsculas
      postoEncontrado = postos[i];                                                         // achou, guarda o posto inteiro
    }
  }
  if (postoEncontrado === null) {
    return null; // posto não existe, recusa
  }
  if (postoEncontrado.estado !== 'ativo') {
    return null; // posto existe mas está em manutenção (ou outro estado que não seja ativo), recusa
  }

  const tarifarios = listarTarifarios();                                                   // busca todos os tarifários já cadastrados
  let tarifarioExiste = false;                                                             // mesma lógica de bandeira, agora para o tarifário
  for (let i = 0; i < tarifarios.length; i++) {                                            // percorre todos os tarifários existentes
    if (tarifarios[i].nome.toLowerCase() === novoCarregamento.tarifario.toLowerCase()) {   // compara o nome do tarifário, ignorando maiúsculas/minúsculas
      tarifarioExiste = true;                                                              // achou, levanta a bandeira
    }
  }
  if (!tarifarioExiste) {
    return null; // tarifário não existe, recusa
  }

  const clientes = listarClientes();                                                      // busca todos os clientes já cadastrados
  let clienteExiste = false;                                                               // mesma lógica de bandeira, agora para o cliente
  for (let i = 0; i < clientes.length; i++) {                                              // percorre todos os clientes existentes
    if (clientes[i].nif === novoCarregamento.cliente) {                                    // compara o NIF do cliente (não usa toLowerCase(), NIF é só número)
      clienteExiste = true;                                                                // achou, levanta a bandeira
    }
  }
  if (!clienteExiste) {
    return null; // cliente não existe, recusa
  }

  const carregamentos = listarCarregamentos();                                           // lista todos os carregamentos do repositório

  let novoId = 1;                                                                        // começa com 1, mas vai aumentando se já houver carregamentos
  for (let i = 0; i < carregamentos.length; i++) {                                       // percorre todos os carregamentos para encontrar o maior id existente e definir o próximo id disponível
    if (carregamentos[i].id >= novoId) {                                                 // se o id do carregamento atual for maior ou igual ao novoId, atualiza o novoId para ser um a mais que o id atual
      novoId = carregamentos[i].id + 1;                                                  // define o próximo id disponível como um a mais que o maior id existente
    }
  }

  const carregamentoCompleto = {                                                         // cria um objeto completo do carregamento com todos os campos necessários, preenchendo os valores padrão para dataHoraFim, energiaKwh, custo e estado se não forem fornecidos
    id: novoId,
    posto: novoCarregamento.posto,
    cliente: novoCarregamento.cliente,
    tarifario: novoCarregamento.tarifario,
    dataHoraInicio: novoCarregamento.dataHoraInicio,
    dataHoraFim: novoCarregamento.dataHoraFim ?? null, //?? operador de coalescência nula: se dataHoraFim for undefined ou null, atribui null
    energiaKwh: novoCarregamento.energiaKwh ?? 0, // se energiaKwh não for fornecido, atribui 0
    custo: novoCarregamento.custo ?? 0, // se custo não for fornecido, atribui 0
    estado: novoCarregamento.estado ?? 'em curso', // se estado não for fornecido, atribui 'em curso'
  };

  carregamentos.push(carregamentoCompleto);
  gravarCarregamentos(carregamentos);
  return carregamentoCompleto;
}

export function atualizarCarregamento(id, dados) {
  const carregamentos = listarCarregamentos();
  const index = carregamentos.findIndex(c => c.id === id); //c => c.id === id é uma função de callback que retorna true se o id do carregamento atual for igual ao id fornecido, e false caso contrário. O findIndex() retorna o índice do primeiro elemento que satisfaz a condição, ou -1 se nenhum elemento satisfizer.
  if (index === -1) return null; // não encontrado

  if (dados.energiaKwh !== undefined) {                                                  // só faz sentido validar a energia quando ela está a ser definida agora
    const carregamentoAtual = carregamentos[index];
    const dataFim = dados.dataHoraFim ?? carregamentoAtual.dataHoraFim;                   // usa a nova data de fim, se vier, senão a que já estava guardada

    if (!campoObrigatorio(dataFim) || !dataHoraValida(dataFim)) {
      return null;                                                                        // sem data/hora de fim válida não dá pra calcular a duração, recusa
    }

    const duracaoEmHoras = (new Date(dataFim) - new Date(carregamentoAtual.dataHoraInicio)) / (1000 * 60 * 60); // diferença em milissegundos, convertida para horas

    const postos = listarPostos();                                                        // busca todos os postos já cadastrados
    let potenciaPosto = null;                                                              // bandeira: fica null se não encontrar o posto deste carregamento
    for (let i = 0; i < postos.length; i++) {
      if (postos[i].codigo.toLowerCase() === carregamentoAtual.posto.toLowerCase()) {
        potenciaPosto = postos[i].potenciaKw;
      }
    }

    if (potenciaPosto !== null) {                                                          // se o posto não existir mais, não há teto pra comparar — deixa passar
      const energiaMaximaPossivel = potenciaPosto * duracaoEmHoras;                        // teto físico: potência do posto (kW) × horas = energia máxima (kWh)
      if (dados.energiaKwh > energiaMaximaPossivel) {
        return null;                                                                       // energia informada é fisicamente impossível para este posto e duração, recusa
      }
    }
  }

  carregamentos[index] = { ...carregamentos[index], ...dados };
  gravarCarregamentos(carregamentos);
  return carregamentos[index];
}

export function removerCarregamento(id) {
  // Sem integridade referencial aqui — nenhuma entidade aponta para um carregamento
  const carregamentos = listarCarregamentos();
  const index = carregamentos.findIndex(c => c.id === id); //c => c.id === id é uma função de callback que retorna true se o id do carregamento atual for igual ao id fornecido, e false caso contrário. O findIndex() retorna o índice do primeiro elemento que satisfaz a condição, ou -1 se nenhum elemento satisfizer.
  if (index === -1) return false;
  carregamentos.splice(index, 1);
  gravarCarregamentos(carregamentos);
  return true;
}
