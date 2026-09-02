import readlineSync from 'readline-sync';                                    // biblioteca de leitura síncrona do terminal
import {
  relatorioCarregamentosPorPosto,
  relatorioCarregamentosPorCliente,
} from '../3-services/relatorioService.js';                                  // as duas funções do relatório 4.1, já prontas e testadas
import { relatorioClientes } from '../3-services/relatorioService.js';       // a função do relatório 4.2
import { relatorioCarregamentosEntreDatas } from '../3-services/relatorioService.js'; // a função do relatório 4.3
import { lerData } from '../utils/validacao.js';                                 // função de validação de datas

//======================================================
//  1. IMPRESSÃO  (o service calcula; aqui só se imprime)
//======================================================

function imprimirRelatorioAgrupado(relatorio, rotulo) { // imprime um relatório 4.1: cada grupo com as suas linhas e subtotal, e o total geral no fim
  let temGrupos = false;                                             // bandeira: vira true se houver pelo menos um grupo (mesmo padrão do dashboard)
  for (const chave in relatorio.grupos) {                            // percorre as chaves (código do posto ou NIF do cliente)
    temGrupos = true;
    const grupo = relatorio.grupos[chave];
    console.log(`\n${rotulo} ${chave}:`);
    for (let i = 0; i < grupo.linhas.length; i++) {                  // as linhas deste grupo: um carregamento por linha, com energia e custo
      const linha = grupo.linhas[i];
      console.log(`  #${linha.id} | ${linha.energiaKwh} kWh | ${linha.custo.toFixed(2)} EUR`);
    }
    console.log(`  Subtotal: ${grupo.subtotalEnergia.toFixed(2)} kWh | ${grupo.subtotalCusto.toFixed(2)} EUR`);
  }
  if (!temGrupos) {
    console.log('Não há carregamentos terminados ou faturados para listar.');
  }
  // o somatório final pedido pelo enunciado; toFixed(2) evita restos de vírgula flutuante tipo 141.60000000000002
  console.log(`Total energia: ${relatorio.totalEnergia.toFixed(2)} kWh | Total custo: ${relatorio.totalCusto.toFixed(2)} EUR`);
}

//======================================================
//  2. MENU DE RELATÓRIOS
//======================================================

export function menuRelatorios() { // função que mostra o submenu de Relatórios e trata cada opção escolhida
  let opcao = ''; // começa vazia, só pra garantir que o while entra pelo menos uma vez

  while (opcao !== '0') { // repete o submenu até o utilizador escolher voltar
    console.log('\n--- Relatórios ---');
    console.log('1. Carregamentos e custos por posto');
    console.log('2. Carregamentos e custos por cliente');
    console.log('3. Clientes com carregamentos');
    console.log('4. Filtro carregamentos entre datas;');
    console.log('0. Voltar');
    opcao = readlineSync.question('Opção: '); // lê a opção escolhida (sempre como texto)

    if (opcao === '1') {
      const relatorio = relatorioCarregamentosPorPosto();                              // pede ao service os dados já agrupados e somados
      imprimirRelatorioAgrupado(relatorio, 'Posto');
      // a impressão é igual nos dois relatórios 4.1 — só muda o rótulo do grupo
    } else if (opcao === '2') {
      const relatorio = relatorioCarregamentosPorCliente();                            // mesma lógica, agora agrupado por cliente (NIF)
      imprimirRelatorioAgrupado(relatorio, 'Cliente');

    } else if (opcao === '3') {
      const linhas = relatorioClientes();
      for (let i = 0; i < linhas.length; i++) {
        const c = linhas[i];
        console.log(`${c.nome} | ${c.idade} anos | ${c.contacto} | ${c.matricula} | ${c.quantidade} carregamentos | ${c.energiaTotal} kWh`);
      }
    } else if (opcao === '4') {
      const dataInicio = lerData('Data de início (AAAA-MM-DD): ');
      const dataFim = lerData('Data de fim (AAAA-MM-DD): ');

      const encontrados = relatorioCarregamentosEntreDatas(dataInicio, dataFim);

      console.log(`Entre ${dataInicio} e ${dataFim}: ${encontrados.length} carregamento(s).`);

    } else if (opcao !== '0') { // qualquer opção que não seja 1-4 nem 0
      console.log('Opção inválida.');
    }
  }
}
