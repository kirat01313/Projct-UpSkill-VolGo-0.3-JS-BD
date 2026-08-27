import readlineSync from 'readline-sync';                                    // biblioteca de leitura síncrona do terminal
import {
  relatorioCarregamentosPorPosto,
  relatorioCarregamentosPorCliente,
} from '../3-services/relatorioService.js';                                  // as duas funções do relatório 4.1, já prontas e testadas
import { relatorioClientes } from '../3-services/relatorioService.js';       // a função do relatório 4.2, ainda por fazer

export function menuRelatorios() { // função que mostra o submenu de Relatórios e trata cada opção escolhida
  let opcao = ''; // começa vazia, só pra garantir que o while entra pelo menos uma vez

  while (opcao !== '0') { // repete o submenu até o utilizador escolher voltar
    console.log('\n--- Relatórios ---');
    console.log('1. Carregamentos e custos por posto');
    console.log('2. Carregamentos e custos por cliente');
    console.log('3. Clientes com carregamentos');
    console.log('0. Voltar');
    opcao = readlineSync.question('Opção: '); // lê a opção escolhida (sempre como texto)

    if (opcao === '1') {
      const relatorio = relatorioCarregamentosPorPosto();                              // pede ao service os dados já filtrados e somados
      console.log(relatorio.linhas);                                                   // mostra cada carregamento (posto, energia, custo)
      console.log(`Total energia: ${relatorio.totalEnergia} kWh | Total custo: ${relatorio.totalCusto} EUR`); // mostra o somatório pedido pelo enunciado
    } else if (opcao === '2') {
      const relatorio = relatorioCarregamentosPorCliente();                            // mesma lógica, agora agrupado por cliente
      console.log(relatorio.linhas);
      console.log(`Total energia: ${relatorio.totalEnergia} kWh | Total custo: ${relatorio.totalCusto} EUR`);
    } else if (opcao === '3') {
      const linhas = relatorioClientes();
      for (let i = 0; i < linhas.length; i++) {
        const c = linhas[i];
        console.log(`${c.nome} | ${c.idade} anos | ${c.contacto} | ${c.matricula} | ${c.quantidade} carregamentos | ${c.energiaTotal} kWh`);
      }
    } else if (opcao !== '0') { // qualquer opção que não seja 1-3 nem 0
      console.log('Opção inválida.');
    }
  }
}
