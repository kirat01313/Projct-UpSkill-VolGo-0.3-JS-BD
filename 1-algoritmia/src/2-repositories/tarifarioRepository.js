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

import path from 'node:path';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { campoObrigatorio, valorPositivo } from '../utils/validacao.js';

const caminhoTarifarios = path.join(import.meta.dirname, '../../data/tarifarios.json');

export function listarTarifarios() {
  if (!existsSync(caminhoTarifarios)) return [];
  const conteudo = readFileSync(caminhoTarifarios, 'utf-8');
  if (conteudo.trim() === '') return [];
  return JSON.parse(conteudo);
}

function gravarTarifarios(tarifarios) {
  writeFileSync(caminhoTarifarios, JSON.stringify(tarifarios, null, 2), 'utf-8');
}

export function inserirTarifario(novoTarifario) {
  if (!campoObrigatorio(novoTarifario.nome)) {
    return null; // nome vazio, recusa
  }
  if (!valorPositivo(novoTarifario.precoPorKwh)) {
    return null; // preço inválido, recusa
  }

  const tarifarios = listarTarifarios();
  if (tarifarios.some(t => t.nome === novoTarifario.nome)) {
    return null; // já existe
  }

  tarifarios.push(novoTarifario);
  gravarTarifarios(tarifarios);
  return novoTarifario;
}

export function atualizarTarifario(nome, dados) { // nome é a chave, não se pode alterar
   const tarifarios = listarTarifarios();
   const index = tarifarios.findIndex(t => t.nome === nome);// procura pelo nome
   if (index === -1) return null; // não encontrado
   tarifarios[index] = { ...tarifarios[index], ...dados }; // atualiza os campos com os novos dados
   gravarTarifarios(tarifarios);
   return tarifarios[index];
}

export function removerTarifario(nome) {
   // TODO: integridade referencial ainda por fazer aqui — ver nota no topo do arquivo
   const tarifarios = listarTarifarios();
   const index = tarifarios.findIndex(t => t.nome === nome);
   if (index === -1) return false;
   tarifarios.splice(index, 1);
   gravarTarifarios(tarifarios);
   return true;
}
