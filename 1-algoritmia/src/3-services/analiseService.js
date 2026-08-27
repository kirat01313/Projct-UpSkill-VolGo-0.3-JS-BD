/*
  ANÁLISE DE DESVIOS + AUDITORIA  (Tarik)  —  REQUISITO DIFERENCIADOR
  ===================================================================

  Compara, em cada carregamento já concluído, o tempo que ELE DEVERIA
  TER DEMORADO com o tempo que REALMENTE demorou:

     previsto = energia registada (kWh) / potência do posto (kW)
     real     = dataHoraFim - dataHoraInicio
     desvio   = real - previsto        (positivo = demorou mais)

  O desvio é quase sempre positivo, e isso é esperado: a potência do
  posto é um TETO, não uma garantia. O carro reduz o consumo à medida
  que a bateria enche, e pode ficar ligado depois de já estar cheio.

  ------------------------------------------------------------
  UM CICLO, DUAS SAÍDAS
  ------------------------------------------------------------
  Para calcular o desvio é preciso descartar os carregamentos que não
  servem. Essas mesmas verificações são a AUDITORIA — muda só o que se
  faz quando falham:

     linhas    -> passou em tudo, entra na estatística   (opção 4 do menu)
     problemas -> registo estragado, com o motivo        (opção 5 do menu)

  Um carregamento "em curso" ou "anulado" é ignorado, não é erro nenhum, apenas ainda não há nada para medir.
A auditoria serve para a empresa ver se os carregamentos estão a ser registados corretamente, e para o utilizador ver se o seu posto está a funcionar bem. 
Por isso, em caso de anomalias não é um erro do programa, é um erro do registo que precisa ser verificado.
  ------------------------------------------------------------
  O QUE DEVOLVE
  ------------------------------------------------------------
     { linhas, problemas, media, desvioPadrao }

  A média diz se a previsão é otimista; o desvio padrão diz se erra
  sempre da mesma maneira. Este service CALCULA e DEVOLVE — não imprime
  nada. Quem imprime é o menuRelatorios.js.
*/

import { listarCarregamentos } from '../2-repositories/carregamentoRepository.js';
import { listarPostos } from '../2-repositories/postoRepository.js';
import { calcularHorasEntre, dataHoraValida } from '../utils/validacao.js';

const TOLERANCIA = 1.0; //Podemos alterar a tolerancia consoante ao tipo de equipamento do posto e aos parametros estabelecidos, 
//nesse caso não consideramos desvios na medição de energia, mas podemos considerar que um posto de 50kW pode entregar 55kW, por exemplo. 
// A tolerancia é um multiplicador do valor máximo esperado, neste caso 1.0 significa que não há tolerancia, 1.1 significa que há uma tolerancia de 10% 
// acima do valor máximo esperado.

export function analisarDesvios() { 
  const carregamentosListados = listarCarregamentos(); 
  const postos = listarPostos();
  const linhas = [];    //os que passaram em todas as verificações
  const problemas = []; //os que falharam, com o motivo

  for (let i = 0; i < carregamentosListados.length; i++) {
    const carregamento = carregamentosListados[i]; 

    if (carregamento.estado !== 'terminado' && carregamento.estado !== 'faturado') { //se não estiver terminado ou faturado, não dá para medir nada
      continue;
    }

    let potencia = null; //procura a potência do posto associado ao carregamento, para poder calcular o tempo previsto
    for (let j = 0; j < postos.length; j++) {
      if (postos[j].codigo.toLowerCase() === carregamento.posto.toLowerCase()) {
        potencia = postos[j].potenciaKw;
      }
    }
    if (potencia === null) { //não encontrou o posto associado ao carregamento, não dá para medir nada
      problemas.push({ id: carregamento.id, motivo: 'Aponta para o posto ' + carregamento.posto + ', que não existe.' }); 
      continue;
    }

    if (carregamento.dataHoraFim === null || !dataHoraValida(carregamento.dataHoraFim)) { //se não tiver data/hora de fim, não dá para medir nada
      problemas.push({ id: carregamento.id, motivo: 'Está ' + carregamento.estado + ' mas não tem data/hora de fim válida.' });
      continue;
    }

    const horas = calcularHorasEntre(carregamento.dataHoraInicio, carregamento.dataHoraFim);
    if (horas <= 0) { //se a data/hora de fim não for depois da data/hora de início, não dá para medir nada
      problemas.push({ id: carregamento.id, motivo: 'A data de fim não é depois da data de início.' });
      continue;
    }

    if (carregamento.energiaKwh <= 0) { //se a energia fornecida for 0 ou negativa, não dá para medir nada
      problemas.push({ id: carregamento.id, motivo: 'Está ' + carregamento.estado + ' mas tem 0 kWh registados.' });
      continue;
    }

    const energiaMaxima = potencia * horas;
    if (carregamento.energiaKwh > energiaMaxima * TOLERANCIA) { //se a energia fornecida for maior do que a energia máxima que o posto poderia fornecer nesse tempo, é um erro de medição ou de registo, não dá para medir nada
      problemas.push({
        id: carregamento.id,
        motivo: carregamento.energiaKwh + ' kWh é impossível: o posto ' + carregamento.posto
              + ' (' + potencia + ' kW) só entrega ' + energiaMaxima.toFixed(1) + ' kWh em ' + horas.toFixed(1) + 'h.' //toFixed(1) para mostrar apenas uma casa decimal
      });
      continue;
    }

    const previsto = (carregamento.energiaKwh / potencia) * 60; //tempo previsto em minutos, com base na energia fornecida e na potência do posto. 
    const real = horas * 60;   //O calculo é energia / potência = tempo em horas, multiplicado por 60 para converter para minutos                                  
    linhas.push({
      id: carregamento.id,
      posto: carregamento.posto,
      previsto: previsto,
      real: real,
      desvio: real - previsto, //positivo = demorou mais do que o previsto
    });
  }


    /*
    ============================================================
    A MATEMÁTICA DAQUI PARA BAIXO  (nota de estudo)
    ============================================================

    Dois números resumem todos os desvios:

       MÉDIA          -> onde está o centro
       DESVIO PADRÃO  -> quão espalhados os valores estão à volta desse centro

    ------------------------------------------------------------
    A MÉDIA
    ------------------------------------------------------------
    Somar tudo e dividir pelo número de elementos. O acumulador
    de sempre, igual ao do dashboard.

       exemplo com os nossos 8 desvios:
       27 + 622 + 42 + 5 + 44 + 16 + 24 + 48 = 828
       828 / 8 = 103,5 minutos

    ------------------------------------------------------------
    O DESVIO PADRÃO, EM 4 PASSOS
    ------------------------------------------------------------
    1. distância de cada valor à média      ->  27 - 103,5 = -76,5
    2. elevar cada distância ao quadrado    ->  (-76,5)^2  = 5852,25
    3. somar tudo e dividir pelo total      ->  308776 / 8 = 38597   (variância)
    4. tirar a raiz quadrada                ->  raiz(38597) = 196,5

    PORQUÊ O QUADRADO (passo 2)?
    Porque somar as distâncias sem sinal dá SEMPRE ZERO, para
    qualquer conjunto de números — é a definição de média: o que
    está acima cancela exatamente o que está abaixo. Ao quadrado,
    negativo x negativo = positivo, e todas as distâncias contam.

    PORQUÊ A RAIZ (passo 4)?
    Porque o passo 2 também elevou as UNIDADES ao quadrado. A
    variância está em "minutos ao quadrado", que não quer dizer
    nada. A raiz desfaz isso e devolve minutos outra vez.

    ------------------------------------------------------------
    PORQUE SÃO DOIS CICLOS SEPARADOS
    ------------------------------------------------------------
    O segundo ciclo precisa da média (desvio - media), e a média
    só existe depois de o primeiro ciclo ter percorrido tudo.
    Não dá para juntar: a segunda passagem é obrigatória.

    ------------------------------------------------------------
    O if (linhas.length > 0)
    ------------------------------------------------------------
    Guarda de divisão por zero. Sem carregamentos válidos, 0/0 dá
    NaN, e um NaN contamina tudo o que toca a seguir.

    ------------------------------------------------------------
    COMO LER O RESULTADO
    ------------------------------------------------------------
    media = 103,5   desvioPadrao = 196,5

    O desvio padrão ser MAIOR que a média é um sinal de alarme:
    quer dizer que os valores não estão agrupados à volta do
    centro. E não estão — o carregamento #2 sozinho vale 87% de
    toda a dispersão (ficou 24h ligado tendo carregado ~13,6h).

    Sem esse registo: media 29,4 e desvioPadrao 14,8, que é o
    retrato honesto do taper (a potência cai à medida que a
    bateria enche, por isso o real demora sempre um pouco mais
    do que a conta "energia / potência" prevê).
  */


  //---- média dos desvios ----
  let soma = 0;
  for (let i = 0; i < linhas.length; i++) {
    soma = soma + linhas[i].desvio; 
  }
  let media = 0;
  if (linhas.length > 0) {
    media = soma / linhas.length; 
  }

  //---- desvio padrão ----
  let somaDosQuadrados = 0;
  for (let i = 0; i < linhas.length; i++) {
    const diferenca = linhas[i].desvio - media;
    somaDosQuadrados = somaDosQuadrados + diferenca * diferenca; //ao quadrado para os negativos não anularem os positivos
  }
  let desvioPadrao = 0;
  if (linhas.length > 0) {
    desvioPadrao = Math.sqrt(somaDosQuadrados / linhas.length);
  }

  return { linhas, problemas, media, desvioPadrao }; //o service CALCULA e DEVOLVE. Quem imprime é o menu.
}