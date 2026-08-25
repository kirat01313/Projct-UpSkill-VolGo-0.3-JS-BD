/*
  REPOSITÓRIO DE TARIFÁRIOS  (Fred)
  =================================

  Sugestão: o primeiro do Fred. É a entidade mais simples (3 campos),
  por isso é onde se aprende o padrão com menos ruído.

  ------------------------------------------------------------
  CAMPOS
  ------------------------------------------------------------
     nome           <- chave única
     precoPorKwh    <- número positivo
     taxaAtivacao   <- número (pode ser 0)

  ------------------------------------------------------------
  AS 4 FUNÇÕES
  ------------------------------------------------------------
     listarTarifarios()
     inserirTarifario(tarifario)       <- validar nome duplicado
     atualizarTarifario(nome, dados)
     removerTarifario(nome)            <- INTEGRIDADE: não remover
                                          se algum carregamento o usar

  ------------------------------------------------------------
  FICHEIRO DE DADOS
  ------------------------------------------------------------
     data/tarifarios.json

  Dica: criar pelo menos 2 tarifários com preços diferentes.
  O dashboard calcula a receita média POR tarifário — com um só,
  não se percebe se o cálculo está certo.
*/

import { campoObrigatorio, valorPositivo } from '../utils/validacao.js';

// TODO: trocar por leitura/escrita em data/tarifarios.json quando o CRUD estiver testado
let tarifarios = [
  { nome: 'Normal', precoPorKwh: 0.30, taxaAtivacao: 0 },
  { nome: 'Verde', precoPorKwh: 0.25, taxaAtivacao: 0.50 },
];

export function listarTarifarios() {
  return tarifarios;
}

export function inserirTarifario(novoTarifario) { 
  if (!campoObrigatorio(novoTarifario.nome)) {
    return null; // nome vazio, recusa
  }
  if (!valorPositivo(novoTarifario.precoPorKwh)) {
    return null; // preço inválido, recusa
  }
  if (tarifarios.some(t => t.nome === novoTarifario.nome)) {
    return null; // já existe
  }

  tarifarios.push(novoTarifario);
  return novoTarifario;
}

export function atualizarTarifario(nome, dados) {
   const tarifarios = listarTarifarios();
   const index = tarifarios.findIndex(t => t.nome === nome); // devolve o índice do tarifário com o nome fornecido, ou -1 se não encontrado
   if (index === -1) return null; // não encontrado
   tarifarios[index] = { ...tarifarios[index], ...dados }; 
   return tarifarios[index];
}

export function removerTarifario(nome) {
   const index = tarifarios.findIndex(t => t.nome === nome);
   if (index === -1) return false;
   tarifarios.splice(index, 1);
   return true;
}
