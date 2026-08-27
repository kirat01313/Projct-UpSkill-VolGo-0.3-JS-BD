/*
  SUBMENU DAS FUNCIONALIDADES EXTRA  (Fred + Tarik)
  =================================================

  Fica direto em 1-cli/ (como o menuRelatorios.js) porque os dois
  vão acrescentar opções aqui:

     1. Receita por concelho              (Fred — feito)
     4. Estimativa de tempo de carregamento (Tarik)
*/

import readlineSync from 'readline-sync';                                    // biblioteca de leitura síncrona do terminal
import { receitaPorConcelho } from '../3-services/diferenciadorService.js';  // função que cruza carregamentos com postos e agrupa por concelho

export function menuDiferenciador() { // função que mostra o submenu das funcionalidades extra e trata cada opção
  let opcao = ''; // começa vazia, só pra garantir que o while entra pelo menos uma vez

  while (opcao !== '0') { // repete o submenu até o utilizador escolher voltar
    console.log('\n--- Funcionalidades extra ---');
    console.log('1. Receita por concelho');
    console.log('2. TARIK');
    console.log('3. TARIK')
    console.log('0. Voltar');
    opcao = readlineSync.question('Opção: '); // lê a opção escolhida (sempre como texto)

    if (opcao === '1') {
      const relatorio = receitaPorConcelho();                                        // pede ao service os dados já cruzados e somados

      console.log('\nReceita por concelho (só carregamentos faturados):');
      for (const concelho in relatorio.porConcelho) {                                // percorre as chaves (nomes dos concelhos) do objeto
        const info = relatorio.porConcelho[concelho];                                // pega o { quantidade, receita } daquele concelho
        console.log(`  ${concelho} -> ${info.quantidade} carregamento(s), ${info.receita.toFixed(2)} EUR`); // arredonda a 2 casas para não aparecer 8.200000000001
      }
      console.log(`Receita total: ${relatorio.totalReceita.toFixed(2)} EUR`);        // mostra o somatório geral
    } else if (opcao === '2') {
      console.log('TODO: relatório "por cobrar" ainda não implementado.');           // fica à espera do relatorioPorCobrar()
    } else if (opcao === '3') {
      console.log('TODO: relatório "estimativa de tempo" ainda não implementado.');   // fica à espera do relatorioEstimativaTempo()
    }
    else if (opcao !== '0') { // qualquer opção que não seja 1-3 nem 0
      console.log('Opção inválida.');
    }
  }
}
