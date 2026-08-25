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

export function relatorioCarregamentosPorPosto() {
  const carregamentos = listarCarregamentos();

  // 1. Filtra só os carregamentos terminados ou faturados,
  //    guardando só os campos que interessam ao relatório
  const linhas = [];
  for (let i = 0; i < carregamentos.length; i++) {
    if (carregamentos[i].estado === 'terminado' || carregamentos[i].estado === 'faturado') {
      linhas.push({ //faz um push no array linhas com os campos que interessam
        posto: carregamentos[i].posto,
        energiaKwh: carregamentos[i].energiaKwh,
        custo: carregamentos[i].custo,
      });
    }
  }

  // 2. Soma a energia e o custo de tudo o que ficou na lista
  let totalEnergia = 0;
  let totalCusto = 0;
  for (let i = 0; i < linhas.length; i++) { // percorre a lista filtrada, não o array original
    totalEnergia += linhas[i].energiaKwh;// soma a energia
    totalCusto += linhas[i].custo;// soma o custo
  }

  return { linhas, totalEnergia, totalCusto };// devolve os dados para o menu imprimir
}

export function relatorioCarregamentosPorCliente() {
  const carregamentos = listarCarregamentos();

  const linhas = [];// array para guardar só os carregamentos que interessam ao relatório
  for (let i = 0; i < carregamentos.length; i++) {// percorre todos os carregamentos
    if (carregamentos[i].estado === 'terminado' || carregamentos[i].estado === 'faturado') {
      linhas.push({// guarda só os campos que interessam ao relatório
        cliente: carregamentos[i].cliente,
        energiaKwh: carregamentos[i].energiaKwh,
        custo: carregamentos[i].custo,
      });
    }
  }

  let totalEnergia = 0;
  let totalCusto = 0;
  for (let i = 0; i < linhas.length; i++) {
    totalEnergia += linhas[i].energiaKwh;
    totalCusto += linhas[i].custo;
  }

  return { linhas, totalEnergia, totalCusto };
}
