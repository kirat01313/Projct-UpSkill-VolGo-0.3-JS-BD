import readlineSync from 'readline-sync';                                            // biblioteca de leitura síncrona do terminal (mesma dos exercícios das aulas)
import { lerTextoObrigatorio, lerNumeroPositivo, lerNumeroNaoNegativo } from '../../utils/validacao.js';   // funções do Tarik: leem e repetem até vir um valor válido
import {
  listarTarifarios,
  inserirTarifario,
  atualizarTarifario,
  removerTarifario,
} from '../../2-repositories/tarifarioRepository.js';                                // as 4 funções de CRUD do repositório de tarifários

export function menuTarifarios() { // função que mostra o submenu de Tarifários e trata cada opção escolhida
  let opcao = ''; // começa vazia, só pra garantir que o while entra pelo menos uma vez

  while (opcao !== '0') { // repete o submenu até o utilizador escolher voltar
    console.log('\n--- Tarifários ---');
    console.log('1. Inserir  2. Listar  3. Atualizar  4. Remover  0. Voltar');
    opcao = readlineSync.question('Opção: '); // lê a opção escolhida (sempre como texto)

    if (opcao === '1') {
      const nome = lerTextoObrigatorio('Nome: ');                                      // pergunta e repete até não vir vazio
      const precoPorKwh = lerNumeroPositivo('Preço por kWh (EUR): ');                  // pergunta e repete até vir um número > 0
      // taxaAtivacao pode ser 0, então não usa lerNumeroPositivo (que exige > 0)
      const taxaAtivacao = lerNumeroNaoNegativo('Taxa de ativação (EUR, 0 se não houver): '); // lê e converte pra número, aceitando 0

      const resultado = inserirTarifario({ nome, precoPorKwh, taxaAtivacao }); // chama o repositório com os 3 campos lidos
      if (resultado === null) { // null significa que foi recusado (nome vazio, preço inválido, ou já existe)
        console.log('Não foi possível inserir — nome vazio, preço inválido ou já existe.');
      } else {
        console.log('Tarifário inserido:', resultado); // mostra o objeto que ficou guardado
      }
    } else if (opcao === '2') {
      console.log(listarTarifarios()); // só busca e imprime, sem lógica nenhuma aqui
    } else if (opcao === '3') {
      const nome = lerTextoObrigatorio('Nome do tarifário a atualizar: ');                                  // lê o nome do tarifário a ser atualizado do usuário
      const precoPorKwh = lerNumeroPositivo('Novo preço por kWh (EUR): ');                                  // lê o novo preço por kWh do usuário
      // taxaAtivacao pode ser 0, então não usa lerNumeroPositivo (que exige > 0)
      const taxaAtivacao = lerNumeroNaoNegativo('Nova taxa de ativação (EUR, 0 se não houver): '); // lê a nova taxa de ativação do usuário

      const resultado = atualizarTarifario(nome, { precoPorKwh, taxaAtivacao }); // envia os dois campos que podem mudar (nome é a chave, não muda)
      if (resultado === null) { // null aqui significa "nome não encontrado"
        console.log('Tarifário não encontrado.');
      } else {
        console.log('Tarifário atualizado:', resultado);
      }
    } else if (opcao === '4') {
      const nome = lerTextoObrigatorio('Nome do tarifário a remover: '); // pergunta e repete até não vir vazio

      // o removerTarifario devolve false por DOIS motivos diferentes (não existe / está em uso),
      // por isso o menu verifica primeiro se o tarifário existe, para a mensagem de recusa não mentir
      const existe = listarTarifarios().findIndex(t => t.nome.toLowerCase() === nome.toLowerCase()) !== -1;
      if (!existe) {
        console.log('Tarifário não encontrado.');
      } else if (removerTarifario(nome)) {
        console.log('Tarifário removido.');
      } else { // existia e mesmo assim não saiu: foi a integridade referencial a recusar
        console.log('Não foi possível remover: tem carregamentos associados.');
      }
    } else if (opcao !== '0') { // qualquer opção que não seja 1-4 nem 0
      console.log('Opção inválida.');
    }
  }
}

