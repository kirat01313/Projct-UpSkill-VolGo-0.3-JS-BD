/*
  RELATÓRIOS  (secção 4 do enunciado)

  4.1 — Carregamentos e custos          (Fred)
        Carregamentos 'terminado' ou 'faturado', agrupados por posto e por
        cliente, com energia e custo de cada um, subtotal por grupo e o
        somatório final que o enunciado pede.

  4.2 — Clientes com carregamentos      (Tarik)
        Nome, idade calculada a partir da data de nascimento, contacto,
        matrícula, número de carregamentos e energia total.
        Cruza duas entidades: dois ciclos, um dentro do outro.
        Clientes sem carregamentos aparecem com zero, em vez de desaparecer.

  Os três devolvem os dados calculados; nenhum imprime. É isso que permite
  reutilizá-los — o mesmo cálculo alimenta opções de menu diferentes.
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
