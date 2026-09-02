/*
  MENU PRINCIPAL  (em conjunto)

  A única camada que fala com o utilizador. Mostra o dashboard uma vez ao
  arrancar, depois repete o menu até a opção ser "0".

  Não calcula nada e não lê ficheiros: cada opção chama o submenu respetivo,
  e o dashboard vem já calculado do dashboardService.
*/

import readlineSync from 'readline-sync';

import { menuTarifarios } from './cli-fred/menuTarifarios.js';
import { menuCarregamentos } from './cli-fred/menuCarregamentos.js';
import { menuPostos } from './cli-tarik/menuPostos.js';
import { menuClientes } from './cli-tarik/menuClientes.js';
import { menuRelatorios } from './menuRelatorios.js';
import { menuDiferenciador } from './menuDiferenciador.js';                          // submenu das funcionalidades extra (requisito diferenciador)
import { dashboard } from '../3-services/dashboardService.js';                       // função que calcula os 3 indicadores do dashboard

//======================================================
//  1. ARRANQUE DA APLICAÇÃO
//======================================================

export function iniciarMenu() {
  console.log('Bem-vindo ao VoltGo — sempre a carregar!\n');
  imprimirDashboard();                                                               // mostra o resumo uma única vez, antes do menu aparecer
  menuPrincipal();
}

//======================================================
//  2. DASHBOARD  (impressão — quem calcula é o dashboardService)
//======================================================

function imprimirDashboard() {                                                       // só imprime — quem calcula é o dashboardService.js
  const dados = dashboard();                                                         // pede ao service os 3 indicadores já calculados

  console.log('=== Dashboard ===');
  console.log(`Carregamentos em curso: ${dados.emCurso}`);                           // indicador 1
  console.log(`Carregamentos terminados: ${dados.terminados}`);
  console.log(`Carregamentos faturados: ${dados.faturados}`);                        // linha extra: já cobrados

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

//======================================================
//  3. MENU PRINCIPAL
//======================================================

function menuPrincipal() {
  let opcao = '';

  while (opcao !== '0') {
    console.log('\n=== VoltGo ===');
    console.log('1. Gerir Postos');
    console.log('2. Gerir Clientes');
    console.log('3. Gerir Tarifários');
    console.log('4. Gerir Carregamentos');
    console.log('5. Relatórios');
    console.log('6. Funcionalidades extra');
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
    } else if (opcao === '6') {
      menuDiferenciador();
    } else if (opcao === '0') {
      console.log('Até já!');
    } else {
      console.log('Opção inválida.');
    }
  }
}
