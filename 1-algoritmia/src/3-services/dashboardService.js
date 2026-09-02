import { listarCarregamentos } from '../2-repositories/carregamentoRepository.js'; // função que devolve todos os carregamentos do repositório

export function dashboard() {
  const carregamentos = listarCarregamentos();                                      // busca todos os carregamentos do repositório
  let emCurso = 0;
  let terminados = 0;
  let faturados = 0;                                                                // contador dos já cobrados 
  let porPosto = {};                                                                // objeto para acumular quantidade e energia por posto 
  let porTarifario = {};                                                            // objeto para acumular quantidade e receita por tarifário

  for (let i = 0; i < carregamentos.length; i++) {                                  // percorre todos os carregamentos do repositório
    const carregamento = carregamentos[i];                                          // pega o carregamento atual para facilitar a leitura do código

    // Indicador 1
    if (carregamento.estado === 'em curso') {
      emCurso++;                                                                   // incrementa o contador de carregamentos em curso
    } else if (carregamento.estado === 'terminado') {
      terminados++;                                                                // incrementa o contador de carregamentos terminados
    } else if (carregamento.estado === 'faturado') {
      faturados++;                                                                 // incrementa o contador de carregamentos já faturados
    }

    // Indicador 2
    if (carregamento.estado === 'terminado') {                                    // só conta os terminados para o indicador 2
      if (!porPosto[carregamento.posto]) {                                        // porPosto["P001"] — se ainda não houver "gaveta" com esse nome, devolve undefined. Undefined é falsy,o ! torna-o true e cria-se zerada.
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

  return { emCurso, terminados, faturados, porPosto, porTarifario };
}
