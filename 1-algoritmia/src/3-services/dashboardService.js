/*
  DASHBOARD  —  PASSO 5  (em conjunto)
  ====================================

  Vale 10% da nota. É mostrado ao ARRANCAR a aplicação, por cima do menu.

  ------------------------------------------------------------
  OS 3 INDICADORES (secção 3 do enunciado)
  ------------------------------------------------------------

  1) Quantidade de carregamentos EM CURSO e TERMINADOS
     -> dois contadores simples

  2) Quantidade + ENERGIA MÉDIA (kWh) por POSTO
     -> ATENÇÃO: só conta os de estado "terminado"

  3) Quantidade + RECEITA MÉDIA por TARIFÁRIO
     -> ATENÇÃO: só conta os de estado "faturado"

  ------------------------------------------------------------
  O ERRO MAIS FÁCIL DE COMETER AQUI
  ------------------------------------------------------------
  Cada indicador tem um FILTRO DE ESTADO DIFERENTE.

  O indicador 2 ignora os faturados.
  O indicador 3 ignora os terminados.

  Ler mal isto é o erro mais provável nesta parte.

  ------------------------------------------------------------
  COMO SE CALCULA CADA UM
  ------------------------------------------------------------

  Indicador 1:
     percorrer os carregamentos, contar quantos têm cada estado

  Indicador 2:
     para cada posto:
        percorrer os carregamentos TERMINADOS desse posto
        contar quantos e somar a energia
        média = somaEnergia / quantidade

  Indicador 3:
     igual, mas por tarifário, filtrando FATURADO,
     e somando o CUSTO em vez da energia

  É o padrão do acumulador (soma + contador -> dividir no fim),
  aplicado três vezes com filtros diferentes.

  ------------------------------------------------------------
  NÃO ESQUECER
  ------------------------------------------------------------
  Guarda de divisão por zero: se um posto não tiver carregamentos
  terminados, 0/0 dá NaN. Verificar a quantidade antes de dividir.

  ------------------------------------------------------------
  SUGESTÃO DE DIVISÃO
  ------------------------------------------------------------
     Indicador 2 (por posto)      -> Tarik   (os postos são dele)
     Indicador 3 (por tarifário)  -> Fred    (os tarifários são dele)
     Indicador 1                  -> quem chegar primeiro

  ------------------------------------------------------------
  O QUE DEVOLVER
  ------------------------------------------------------------
  Uma função só pode devolver UMA coisa. Para devolver vários valores,
  embrulham-se num objeto:

     { emCurso, terminados, porPosto, porTarifario }

  O menu recebe esse objeto e imprime cada parte.
*/

import { listarCarregamentos } from '../2-repositories/carregamentoRepository.js'; // função que devolve todos os carregamentos do repositório

export function dashboard() {
  const carregamentos = listarCarregamentos();                                      // busca todos os carregamentos do repositório
  let emCurso = 0;
  let terminados = 0;
  let porPosto = {};                                                                // objeto para acumular quantidade e energia por posto 
  let porTarifario = {};                                                            // objeto para acumular quantidade e receita por tarifário

  for (let i = 0; i < carregamentos.length; i++) {                                  // percorre todos os carregamentos do repositório
    const carregamento = carregamentos[i];                                          // pega o carregamento atual para facilitar a leitura do código

    // Indicador 1
    if (carregamento.estado === 'em curso') {
      emCurso++;                                                                   // incrementa o contador de carregamentos em curso
    } else if (carregamento.estado === 'terminado') {
      terminados++;                                                                // incrementa o contador de carregamentos terminados
    }

    // Indicador 2
    if (carregamento.estado === 'terminado') {                                    // só conta os terminados para o indicador 2
      if (!porPosto[carregamento.posto]) {                                        // se ainda não existe um objeto para este posto, cria um com quantidade e energia inicializados a 0
        porPosto[carregamento.posto] = { quantidade: 0, energia: 0 };             // inicializa o objeto para este posto
      }
      porPosto[carregamento.posto].quantidade++;                                  // incrementa o contador de carregamentos terminados para este posto
      porPosto[carregamento.posto].energia += carregamento.energiaKwh;            // soma a energia consumida deste carregamento ao total do posto
    }

    // Indicador 3
    if (carregamento.estado === 'faturado') {                                     // só conta os faturados para o indicador 3
      if (!porTarifario[carregamento.tarifario]) {                                // se ainda não existe um objeto para este tarifário, cria um com quantidade e receita inicializados a 0
        porTarifario[carregamento.tarifario] = { quantidade: 0, receita: 0 };     // inicializa o objeto para este tarifário
      }
      porTarifario[carregamento.tarifario].quantidade++;                          // incrementa o contador de carregamentos faturados para este tarifário
      porTarifario[carregamento.tarifario].receita += carregamento.custo;         // soma o custo deste carregamento ao total do tarifário
    }
  }

  // Calcular médias
  for (const posto in porPosto) {                                        // percorre as chaves (códigos de posto) do objeto porPosto
    if (porPosto[posto].quantidade > 0) {                                // evita divisão por zero: só calcula a média se houver pelo menos um carregamento terminado para este posto
      porPosto[posto].mediaEnergia = porPosto[posto].energia / porPosto[posto].quantidade; // calcula a média de energia consumida por carregamento terminado para este posto
    } else {
      porPosto[posto].mediaEnergia = 0;                                  // se não houver carregamentos terminados, a média é 0
    }
  }

  for (const tarifario in porTarifario) {
    if (porTarifario[tarifario].quantidade > 0) {
      porTarifario[tarifario].mediaReceita = porTarifario[tarifario].receita / porTarifario[tarifario].quantidade;
    } else {
      porTarifario[tarifario].mediaReceita = 0;
    }
  }

  return { emCurso, terminados, porPosto, porTarifario };
}
