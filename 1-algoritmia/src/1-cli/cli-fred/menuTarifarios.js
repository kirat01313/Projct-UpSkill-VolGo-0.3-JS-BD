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

import readlineSync from 'readline-sync';
import {
  listarTarifarios,
  inserirTarifario,
  atualizarTarifario,
  removerTarifario,
} from '../../2-repositories/tarifarioRepository.js';

export function menuTarifarios() {
  let opcao = '';

  while (opcao !== '0') {
    console.log('\n--- Tarifários ---');
    console.log('1. Inserir  2. Listar  3. Atualizar  4. Remover  0. Voltar');
    opcao = readlineSync.question('Opção: ');

    if (opcao === '1') {
      const nome = readlineSync.question('Nome: ');
      const precoPorKwh = Number(readlineSync.question('Preço por kWh (EUR): '));
      const taxaAtivacao = Number(readlineSync.question('Taxa de ativação (EUR, 0 se não houver): '));

      const resultado = inserirTarifario({ nome, precoPorKwh, taxaAtivacao });
      if (resultado === null) {
        console.log('Não foi possível inserir — nome vazio, preço inválido ou já existe.');
      } else {
        console.log('Tarifário inserido:', resultado);
      }
    } else if (opcao === '2') {
      console.log(listarTarifarios());
    } else if (opcao === '3') {
      const nome = readlineSync.question('Nome do tarifário a atualizar: ');
      const precoPorKwh = Number(readlineSync.question('Novo preço por kWh (EUR): '));

      const resultado = atualizarTarifario(nome, { precoPorKwh });
      if (resultado === null) {
        console.log('Tarifário não encontrado.');
      } else {
        console.log('Tarifário atualizado:', resultado);
      }
    } else if (opcao === '4') {
      const nome = readlineSync.question('Nome do tarifário a remover: ');

      const removido = removerTarifario(nome);
      console.log(removido ? 'Tarifário removido.' : 'Tarifário não encontrado.');
    } else if (opcao !== '0') {
      console.log('Opção inválida.');
    }
  }
}

