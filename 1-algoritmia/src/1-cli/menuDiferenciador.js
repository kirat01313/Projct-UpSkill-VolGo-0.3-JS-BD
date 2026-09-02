import readlineSync from 'readline-sync';                                    // biblioteca de leitura síncrona do terminal
import { receitaPorConcelho } from '../3-services/diferenciadorService.js';  // função que cruza carregamentos com postos e agrupa por concelho
import { analisarDesvios } from '../3-services/analiseService.js';           // análise de desvios + auditoria (Tarik)

//======================================================
//  1. AUXILIAR DE DESENHO
//======================================================

// desenha uma barra de "#" — é isto o "gráfico" no terminal
function barra(quantidade) {
  // Teto de segurança: um registo estragado dá desvios enormes (o #15 tem 252 dias,
  // que a 5 minutos por '#' daria mais de 72 mil caracteres numa linha só e enchia
  // o ecrã). Corta-se em COMPRIMENTO_MAXIMO e marca-se com '>' que foi cortada.
  const COMPRIMENTO_MAXIMO = 40;
  const foiCortada = quantidade > COMPRIMENTO_MAXIMO;
  const quantos = foiCortada ? COMPRIMENTO_MAXIMO : quantidade;

  let texto = '';
  for (let i = 0; i < quantos; i++) {
    texto += '#';
  }
  if (foiCortada) {
    texto += '>';
  }
  return texto;
}

//======================================================
//  2. MENU DAS FUNCIONALIDADES EXTRA
//======================================================

export function menuDiferenciador() { // função que mostra o submenu das funcionalidades extra e trata cada opção
  let opcao = ''; // começa vazia, só pra garantir que o while entra pelo menos uma vez

  while (opcao !== '0') { // repete o submenu até o utilizador escolher voltar
    console.log('\n--- Funcionalidades extra ---');
    console.log('1. Receita por concelho');
    console.log('2. Análise de desvios (previsto vs real)');
    console.log('3. Auditoria de carregamentos');
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
      const analise = analisarDesvios();
      if (analise.linhas.length === 0) {
        console.log('Não há carregamentos completos suficientes para analisar.');
      } else {
        console.log('');
        console.log('  id | posto | previsto |  real |  desvio');
        for (let i = 0; i < analise.linhas.length; i++) {
          const l = analise.linhas[i];
          const sinal = l.desvio >= 0 ? '+' : ''; //esse operador ternário é só pra mostrar o sinal "+" nos desvios positivos, porque o negativo já aparece sozinho
          console.log('  ' + String(l.id).padStart(2) + ' | ' + l.posto.padEnd(5) + ' | '
            + String(Math.round(l.previsto)).padStart(6) + 'm | '
            + String(Math.round(l.real)).padStart(4) + 'm | '
            + (sinal + Math.round(l.desvio) + 'm').padStart(7) + '  '
            + barra(Math.round(Math.abs(l.desvio) / 5))); //cada "#" vale 5 minutos
        }
        console.log('');
        console.log('  Carregamentos analisados: ' + analise.linhas.length);
        console.log('  Desvio médio: ' + (analise.media >= 0 ? '+' : '') + analise.media.toFixed(1) + ' min');
        console.log('  Desvio padrão: ' + analise.desvioPadrao.toFixed(1) + ' min');

        const faixas = [
          { rotulo: 'previsão otimista demais', min: -999999, max: 0 },
          { rotulo: '0 a 15 min', min: 0, max: 15 },
          { rotulo: '15 a 30 min', min: 15, max: 30 },
          { rotulo: '30 a 60 min', min: 30, max: 60 },
          { rotulo: 'mais de 60 min', min: 60, max: 999999 },
        ];
        console.log('');
        console.log('  Distribuição dos desvios:');
        for (let i = 0; i < faixas.length; i++) {
          let quantos = 0;
          for (let j = 0; j < analise.linhas.length; j++) { //para cada faixa, conta os que lá caem
            if (analise.linhas[j].desvio >= faixas[i].min && analise.linhas[j].desvio < faixas[i].max) {
              quantos++;
            }
          }
          console.log('  ' + faixas[i].rotulo.padEnd(26) + '| ' + barra(quantos) + ' ' + quantos);
        }
      }
    } else if (opcao === '3') {
      const analise = analisarDesvios(); //a MESMA função: os problemas saíram do mesmo ciclo
      if (analise.problemas.length === 0) {
        console.log('Nenhum problema encontrado nos carregamentos.');
      } else {
        console.log('');
        console.log('  ' + analise.problemas.length + ' registo(s) com problemas:');
        for (let i = 0; i < analise.problemas.length; i++) {
          console.log('  Carregamento #' + analise.problemas[i].id + ' -> ' + analise.problemas[i].motivo);
        }
      }
    }
    else if (opcao !== '0') { // qualquer opção que não seja 1-3 nem 0
      console.log('Opção inválida.');
    }
  }
}
