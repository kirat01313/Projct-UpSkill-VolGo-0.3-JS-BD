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

import { campoObrigatorio } from '../utils/validacao.js';

// TODO: trocar por leitura/escrita em data/carregamentos.json quando o CRUD estiver testado
// TODO: validar dataHoraInicio com dataValida() quando essa função existir em utils/validacao.js
// TODO: confirmar que posto/cliente/tarifario existem de facto (precisa dos repositórios deles prontos)
let carregamentos = [
  {
    id: 1,
    posto: 'P001',
    cliente: '123456789',
    tarifario: 'Normal',
    dataHoraInicio: '2026-08-20 09:00',
    dataHoraFim: '2026-08-20 10:00',
    energiaKwh: 12,
    custo: 3.6,
    estado: 'terminado',
  },
];

export function listarCarregamentos() {
  return carregamentos;
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

  let novoId = 1;
  for (let i = 0; i < carregamentos.length; i++) {
    if (carregamentos[i].id >= novoId) {
      novoId = carregamentos[i].id + 1;
    }
  }

  const carregamentoCompleto = {
    id: novoId,
    posto: novoCarregamento.posto,
    cliente: novoCarregamento.cliente,
    tarifario: novoCarregamento.tarifario,
    dataHoraInicio: novoCarregamento.dataHoraInicio,
    dataHoraFim: novoCarregamento.dataHoraFim ?? null,
    energiaKwh: novoCarregamento.energiaKwh ?? 0,
    custo: novoCarregamento.custo ?? 0,
    estado: novoCarregamento.estado ?? 'em curso',
  };

  carregamentos.push(carregamentoCompleto);
  return carregamentoCompleto;
}

export function atualizarCarregamento(id, dados) {
  const index = carregamentos.findIndex(c => c.id === id);
  if (index === -1) return null; // não encontrado
  carregamentos[index] = { ...carregamentos[index], ...dados };
  return carregamentos[index];
}

export function removerCarregamento(id) {
  // Sem integridade referencial aqui — nenhuma entidade aponta para um carregamento
  const index = carregamentos.findIndex(c => c.id === id);
  if (index === -1) return false;
  carregamentos.splice(index, 1);
  return true;
}
