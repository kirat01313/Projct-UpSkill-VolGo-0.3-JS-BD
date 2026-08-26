import readlineSync from 'readline-sync';

import { menuTarifarios } from './cli-fred/menuTarifarios.js';
import { menuCarregamentos } from './cli-fred/menuCarregamentos.js';
import { menuPostos } from './cli-tarik/menuPostos.js';
import { menuClientes } from './cli-tarik/menuClientes.js';
import { menuRelatorios } from './menuRelatorios.js';
import { dashboard } from '../3-services/dashboardService.js';                       // função que calcula os 3 indicadores do dashboard

export function iniciarMenu() {
  console.log('Bem-vindo ao VoltGo — sempre a carregar!\n');
  imprimirDashboard();                                                               // mostra o resumo uma única vez, antes do menu aparecer
  menuPrincipal();
}

function imprimirDashboard() {                                                       // só imprime — quem calcula é o dashboardService.js
  const dados = dashboard();                                                         // pede ao service os 3 indicadores já calculados

  console.log('=== Dashboard ===');
  console.log(`Carregamentos em curso: ${dados.emCurso}`);                           // indicador 1
  console.log(`Carregamentos terminados: ${dados.terminados}`);

  console.log('\nPor posto (só carregamentos terminados):');                         // indicador 2
  let temPosto = false;                                                              // bandeira: vira true se entrar pelo menos uma vez no for...in
  for (const posto in dados.porPosto) {                                              // percorre as chaves (códigos de posto) do objeto porPosto
    temPosto = true;                                                                 // achou pelo menos um posto, levanta a bandeira
    const info = dados.porPosto[posto];                                              // pega o objeto { quantidade, energia, mediaEnergia } do posto atual
    console.log(`  ${posto} -> ${info.quantidade} carregamento(s), média de ${info.mediaEnergia.toFixed(2)} kWh`); // imprime a linha do posto, arredondando a média para 2 casas decimais
  }
  if (!temPosto) {
    console.log('  Nenhum carregamento terminado ainda.');
  }

  console.log('\nPor tarifário (só carregamentos faturados):');                      // indicador 3
  let temTarifario = false;                                                          // mesma lógica de bandeira, agora para os tarifários
  for (const tarifario in dados.porTarifario) {                                      // percorre as chaves (nomes de tarifário) do objeto porTarifario
    temTarifario = true;
    const info = dados.porTarifario[tarifario];
    console.log(`  ${tarifario} -> ${info.quantidade} carregamento(s), média de ${info.mediaReceita.toFixed(2)} EUR`);
  }
  if (!temTarifario) {
    console.log('  Nenhum carregamento faturado ainda.');
  }
  console.log('');
}

function menuPrincipal() {
  let opcao = '';

  while (opcao !== '0') {
    console.log('\n=== VoltGo ===');
    console.log('1. Gerir Postos');
    console.log('2. Gerir Clientes');
    console.log('3. Gerir Tarifários');
    console.log('4. Gerir Carregamentos');
    console.log('5. Relatórios');
    console.log('0. Sair');
    opcao = readlineSync.question('Escolha uma opção: ');

    if (opcao === '1') {
      menuPostos();
    } else if (opcao === '2') {
      menuClientes();
    } else if (opcao === '3') {
      menuTarifarios();
    } else if (opcao === '4') {
      menuCarregamentos();
    } else if (opcao === '5') {
      menuRelatorios();
    } else if (opcao === '0') {
      console.log('Até já!');
    } else {
      console.log('Opção inválida.');
    }
  }
}

/*
  MENU PRINCIPAL  —  PASSO 2
  ==========================

  O QUE VAI AQUI:
    - a lista de opcoes
    - ler a escolha do utilizador
    - chamar o submenu correspondente
    - repetir ate a opcao ser "0"
    - (PASSO 5) o dashboard no topo — deixar comentado ate la

  O QUE NAO VAI AQUI:
    - a logica de cada submenu (isso vai para cli-tarik/ e cli-fred/)
    - leitura de ficheiros

  ------------------------------------------------------------
  AS OPCOES A MOSTRAR:
  ------------------------------------------------------------
     1. Gerir Postos
     2. Gerir Clientes
     3. Gerir Tarifarios
     4. Gerir Carregamentos
     5. Relatorios
     0. Sair

  ------------------------------------------------------------
  A REPETICAO:
  ------------------------------------------------------------
  O menu tem de voltar a aparecer depois de cada operacao.
  Sugestao: um ciclo while que repete enquanto a opcao nao for "0".

  (Ha quem faca isto com recursao — a funcao chamar-se a si propria.
   Funciona, mas o while e mais simples e e materia da aula 3.)

  ------------------------------------------------------------
  LIGAR OS SUBMENUS (ir acrescentando a medida que existirem):
  ------------------------------------------------------------
  Quando o menuPostos.js estiver feito, acrescentar aqui o import
  e chama-lo na opcao 1.

  Enquanto um submenu nao existir, deixar um console.log a dizer
  "ainda nao implementado". Assim o menu funciona na mesma e
  consegues navegar desde o inicio.

  ------------------------------------------------------------
  NAO ESQUECER:
  ------------------------------------------------------------
  - opcao invalida tem de dar mensagem, nao pode ficar em silencio
  - o input vem sempre como TEXTO: comparar com "1", nao com 1
*/
