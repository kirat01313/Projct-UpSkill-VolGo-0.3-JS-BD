/*
  RELATÓRIOS  —  PASSO 5
  ======================

  Valem 20% da nota. São dois, um para cada um.

  ============================================================
  RELATÓRIO 4.1 — Carregamentos e custos          (FRED)
  ============================================================

  Carregamentos com estado "terminado" OU "faturado", agrupados:
     - por posto
     - por cliente

  Para cada carregamento, mostrar a energia (kWh) e o custo.
  No FIM, apresentar o SOMATÓRIO da energia e do custo.

  Esse somatório final é explicitamente pedido no enunciado —
  é fácil esquecer.

  ============================================================
  RELATÓRIO 4.2 — Clientes com carregamentos      (TARIK)
  ============================================================

  Para cada cliente, mostrar:
     - nome
     - IDADE  (calculada a partir da dataNascimento)
     - contacto
     - matrícula
     - número de carregamentos
     - energia total consumida

  ------------------------------------------------------------
  A LÓGICA (é o exercício mais interessante da parte do Tarik)
  ------------------------------------------------------------
  Este relatório CRUZA DUAS ENTIDADES:

     1. percorrer os clientes
     2. para CADA cliente, percorrer os carregamentos
        e contar os dele, somando a energia
     3. mostrar a linha

  São dois ciclos, um dentro do outro — como os desenhos da aula 3,
  mas em vez de linhas e colunas são clientes e carregamentos.

  ------------------------------------------------------------
  A IDADE
  ------------------------------------------------------------
  Não basta subtrair os anos.

  Se a pessoa ainda não fez anos este ano, é preciso tirar 1.
  Pensar em como comparar o mês e o dia de hoje com os da data
  de nascimento.

  ------------------------------------------------------------
  NÃO ESQUECER
  ------------------------------------------------------------
  Clientes SEM carregamentos têm de aparecer com 0 —
  não podem desaparecer da lista nem dar NaN.

  ------------------------------------------------------------
  REGRA DESTA CAMADA
  ------------------------------------------------------------
  O service CALCULA e DEVOLVE os dados.
  Quem imprime é o menu.

  (Se um relatório fizer console.log aqui dentro, deixa de poder
   ser reutilizado — por exemplo, para exportar para ficheiro,
   que é uma das sugestões de requisito diferenciador.)
*/

import { listarCarregamentos } from '../2-repositories/carregamentoRepository.js';
import { listarClientes } from '../2-repositories/clienteRepository.js';
import { calcularIdade } from '../utils/validacao.js';

//======================================================
//  RELATÓRIO 4.1 — carregamentos e custos  (parte Fred)
//======================================================

export function relatorioCarregamentosPorPosto() {
  const carregamentos = listarCarregamentos();

  // Junta os carregamentos terminados ou faturados em GRUPOS, um por posto —
  // é o agrupamento que faz o relatório ser "por posto", como o enunciado pede.
  // Cada grupo guarda as suas linhas e o seu subtotal; o total geral soma tudo.
  const grupos = {};       // objeto com uma entrada por posto: { linhas, subtotalEnergia, subtotalCusto }
  let totalEnergia = 0;    // acumulador do total geral de energia, começa em 0
  let totalCusto = 0;      // acumulador do total geral de custo, começa em 0

  for (let i = 0; i < carregamentos.length; i++) {                                            // percorre todos os carregamentos
    if (carregamentos[i].estado === 'terminado' || carregamentos[i].estado === 'faturado') {  // só entra quem está terminado ou faturado
      const chave = carregamentos[i].posto;                                                   // o código do posto é a chave do grupo
      if (!grupos[chave]) {                                                                   // primeira vez que este posto aparece: cria o grupo zerado
        grupos[chave] = { linhas: [], subtotalEnergia: 0, subtotalCusto: 0 };
      }
      grupos[chave].linhas.push({                                                             // guarda só os campos que interessam ao relatório
        id: carregamentos[i].id,                                                              // identifica o carregamento na listagem
        energiaKwh: carregamentos[i].energiaKwh,                                              // energia consumida nesse carregamento
        custo: carregamentos[i].custo,                                                        // custo desse carregamento
      });
      grupos[chave].subtotalEnergia += carregamentos[i].energiaKwh;                           // subtotal do posto
      grupos[chave].subtotalCusto += carregamentos[i].custo;
      totalEnergia += carregamentos[i].energiaKwh;                                            // total geral (o somatório pedido no enunciado)
      totalCusto += carregamentos[i].custo;
    }
  }

  return { grupos, totalEnergia, totalCusto };  // devolve os dados para o menu imprimir
}

export function relatorioCarregamentosPorCliente() {
  const carregamentos = listarCarregamentos();                                                // lista todos os carregamentos do repositório

  // Mesma lógica do relatório por posto, mas a chave do grupo é o NIF do cliente
  const grupos = {};       // objeto com uma entrada por cliente: { linhas, subtotalEnergia, subtotalCusto }
  let totalEnergia = 0;    // acumulador do total geral de energia, começa em 0
  let totalCusto = 0;      // acumulador do total geral de custo, começa em 0

  for (let i = 0; i < carregamentos.length; i++) {                                            // percorre todos os carregamentos
    if (carregamentos[i].estado === 'terminado' || carregamentos[i].estado === 'faturado') {  // só entra quem está terminado ou faturado
      const chave = carregamentos[i].cliente;                                                 // o NIF do cliente é a chave do grupo
      if (!grupos[chave]) {                                                                   // primeira vez que este cliente aparece: cria o grupo zerado
        grupos[chave] = { linhas: [], subtotalEnergia: 0, subtotalCusto: 0 };
      }
      grupos[chave].linhas.push({                                                             // guarda só os campos que interessam ao relatório
        id: carregamentos[i].id,                                                              // identifica o carregamento na listagem
        energiaKwh: carregamentos[i].energiaKwh,                                              // energia consumida nesse carregamento
        custo: carregamentos[i].custo,                                                        // custo desse carregamento
      });
      grupos[chave].subtotalEnergia += carregamentos[i].energiaKwh;                           // subtotal do cliente
      grupos[chave].subtotalCusto += carregamentos[i].custo;
      totalEnergia += carregamentos[i].energiaKwh;                                            // total geral (o somatório pedido no enunciado)
      totalCusto += carregamentos[i].custo;
    }
  }

  return { grupos, totalEnergia, totalCusto };  // devolve os dados para o menu imprimir
}

//======================================================
//  RELATÓRIO 4.2 — clientes com carregamentos  (parte Tarik)
//======================================================

export function relatorioClientes() {
  const clientes = listarClientes();
  const carregamentos = listarCarregamentos();

  const linhas = [];

  for (let i = 0; i < clientes.length; i++) {        // ciclo de FORA: cada cliente
    let quantidade = 0;
    let energiaTotal = 0;

    for (let j = 0; j < carregamentos.length; j++) { // ciclo de DENTRO: os carregamentos dele
      if (carregamentos[j].cliente === clientes[i].nif) {
        quantidade = quantidade + 1;
        energiaTotal = energiaTotal + carregamentos[j].energiaKwh;
      }
    }

    linhas.push({
      nome: clientes[i].nome,
      idade: calcularIdade(clientes[i].dataNascimento),
      contacto: clientes[i].contactoTelefone,
      matricula: clientes[i].matricula,
      quantidade: quantidade,
      energiaTotal: energiaTotal,
    });
  }

  return linhas;      // devolve os dados; quem imprime é o menu
}
