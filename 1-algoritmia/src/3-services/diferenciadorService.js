/*
  REQUISITO DIFERENCIADOR  (Fred)
  ===============================

  As funcionalidades extra, fora do que o enunciado obriga.
  Ficam num ficheiro próprio para serem fáceis de identificar.

  ------------------------------------------------------------
  1) receitaPorConcelho()
  ------------------------------------------------------------
  Cruza CARREGAMENTOS com POSTOS para responder à pergunta:
  "em que concelhos é que o negócio rende mais?"

  É o único sítio do projeto que faz um LOOKUP entre entidades:
  o carregamento só guarda o CÓDIGO do posto, e o concelho está
  guardado dentro do posto — logo é preciso ir lá buscá-lo.

  (Na Fase 2 isto vira um JOIN + GROUP BY — e corresponde ao
   relatório 6 obrigatório: "Concelhos e valor total faturado".)
*/

import { listarCarregamentos } from '../2-repositories/carregamentoRepository.js'; // devolve todos os carregamentos
import { listarPostos } from '../2-repositories/postoRepository.js';               // devolve todos os postos (é lá que está o concelho)
import { CONCELHOS_VALIDOS } from '../utils/constantes.js';                        // lista dos concelhos onde a VoltGo trabalha

export function receitaPorConcelho() {
  const carregamentos = listarCarregamentos();
  const postos = listarPostos();

  // Arranca com TODOS os concelhos a zero, mesmo os que ainda não deram receita.
  // Um concelho com 0 EUR não é ruído: é precisamente a informação de onde
  // ainda não há negócio — que é a pergunta que este relatório responde.
  const porConcelho = {};
  for (let i = 0; i < CONCELHOS_VALIDOS.length; i++) {                             // percorre a lista fixa de concelhos válidos
    porConcelho[CONCELHOS_VALIDOS[i]] = { quantidade: 0, receita: 0 };             // inicializa o objeto para cada concelho com quantidade e receita a 0
  }

  let totalReceita = 0; // acumulador do total geral, começa em 0

  for (let i = 0; i < carregamentos.length; i++) {                                 // percorre todos os carregamentos do repositório
    const carregamento = carregamentos[i];                                         // pega o carregamento atual para facilitar a leitura do código

    // Só interessa quem já foi FATURADO — receita é dinheiro efetivamente cobrado.
    // Um 'terminado' ainda não foi cobrado, logo ainda não é receita.
    if (carregamento.estado === 'faturado') {

      // O LOOKUP: o carregamento só tem o código do posto ("P001"),
      // por isso é preciso percorrer os postos para descobrir o concelho dele
      let concelhoDoPosto = null;                                                    // fica null se o posto não for encontrado
      for (let j = 0; j < postos.length; j++) {                                      // ciclo dentro do ciclo: para cada carregamento, percorre os postos
        if (postos[j].codigo.toLowerCase() === carregamento.posto.toLowerCase()) {   // compara os códigos, ignorando maiúsculas/minúsculas
          concelhoDoPosto = postos[j].concelho;                                      // achou, guarda o concelho
        }
      }

      // Se o posto já não existir (carregamento órfão), não se deita fora em
      // silêncio — agrupa-se à parte para o problema ficar visível na listagem
      if (concelhoDoPosto === null) {
        concelhoDoPosto = '(posto desconhecido)';
      }

      // O concelho pode não estar na lista inicial (caso do "posto desconhecido",
      // ou de um posto guardado com um concelho fora dos CONCELHOS_VALIDOS)
      if (!porConcelho[concelhoDoPosto]) {
        porConcelho[concelhoDoPosto] = { quantidade: 0, receita: 0 };
      }

      porConcelho[concelhoDoPosto].quantidade++;                 // mais um carregamento faturado neste concelho
      porConcelho[concelhoDoPosto].receita += carregamento.custo; // soma o custo à receita do concelho
      totalReceita += carregamento.custo;                         // soma também ao total geral
    }
  }

  return { porConcelho, totalReceita }; // devolve os dados; quem imprime é o menu
}
