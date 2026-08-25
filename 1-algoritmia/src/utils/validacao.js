/*
ISSO VAI FOI TRANSFORMADO NO CÓDIGO A SEGUIR

    case '2':
      let codigoPosto = prompt(`Digite o código do novo Posto: `);
      while (codigoPosto === "") {
        console.log(`O código do novo Posto inserido não é válido no momento. Insira um conselho válido ["Braga", "Faro", "Porto" ou "Lisboa"]: `);
        concelhoPosto = prompt(`Digite novamente o código do novo Posto: `).trim().toLowerCase();
      }
      let concelhoPosto = prompt(`Digite o concelho do novo Posto: `).trim().toLowerCase();
      while (!CONCELHOS_VALIDOS.includes(concelhoPosto)) {
        console.log(`O conselho inserido não é válido no momento. Insira um conselho válido ["Braga", "Faro", "Porto" ou "Lisboa"]: `);
        concelhoPosto = prompt(`Digite novamente o concelho do novo Posto: `).trim().toLowerCase();
      }
      let potenciaPosto = Number(prompt(`Digite a potência do novo Posto: `));
      while (potenciaPosto <= 0 || potenciaPosto !== Number) {
        console.log(`A potência inserida não é válida. Insira apenas números válidos: `);
        potenciaPosto = Number(prompt(`Digite novamente a potência do novo Posto: `).trim().toLowerCase());
      }
      let conectorPosto = prompt(`Digite o tipo do conector do novo Posto["Type2" ou "CCS"]: `).trim().toLowerCase();
      while (!CONECTORES_VALIDOS.includes(conectorPosto)) {
        console.log(`O conector inserido não é válido.Insira um conector válido["Type2" ou "CCS"]: `);
        conectorPosto = prompt(`Digite novamente o conector desse novo Posto: `).trim().toLowerCase();
      }
      let estadoPosto = prompt(`Digite o estado do novo Posto["ativo" ou "manutencao"]: `).trim().toLowerCase();
      while (!ESTADOS_POSTO_VALIDOS.includes(estadoPosto)) {
        console.log(`O estado inserido não é válido.Insira um estado válido["ativo","manutencao"]: `);
        estadoPosto = prompt(`Digite novamente o estado desse novo Posto: `).trim().toLowerCase();
      }

*/ //NESSE CÓDIGO:

import readlineSync from "readline-sync";
const prompt = readlineSync.question;

export function lerOpcaoValida(mensagem, listaValidos) { //mensagem é o "prompt(`Digite o código do novo Posto: `);"
  let valor = prompt(mensagem).trim().toLowerCase();     //listaValidos vem da constantes.js que lista valores que a empresa usa
  while (!listaValidos.includes(valor)) {                //checa se o valor inserido no prompt está incluido na lista de valores válidos
    console.log(`Valor Inválido. Valores Válidos: [${listaValidos.join(", ")}]`); //
    valor = prompt(mensagem).trim().toLowerCase();
  }
  return valor;
}

export function lerTextoObrigatorio(mensagem) {
  let valor = prompt(mensagem).trim();
  while (valor === "") {
    console.log("Este campo é obrigatório. Deve inserir um valor.");
    valor = prompt(mensagem).trim();
  }
  return valor;
}

export function lerNumeroPositivo(mensagem) {
  let valor = Number(prompt(mensagem).trim());
  while (Number.isNaN(valor) || valor <= 0) {
    console.log("Insira um valor numérico maior que zero.");
    valor = Number(prompt(mensagem).trim());
  }
  return valor;
}










/*
  UTILS / VALIDAÇÃO
  =================

  Ferramentas GENÉRICAS, usadas por todos.
  Vai-se acrescentando conforme a necessidade aparece — não escrever
  tudo de uma vez.

  ------------------------------------------------------------
  O QUE VAI AQUI vs. O QUE NÃO VAI
  ------------------------------------------------------------

  VAI:    funções que serviriam em QUALQUER projeto
          (validar campo vazio, validar data, validar número positivo)

  NÃO VAI: funções específicas de uma entidade
          (criarCliente, listarPostos — essas ficam no repositório dela)

  A regra: código que só serve uma entidade fica COM essa entidade.

  ------------------------------------------------------------
  FUNÇÕES QUE VÃO SER PRECISAS
  ------------------------------------------------------------

  campoObrigatorio(valor)
      -> true se tem conteúdo, false se está vazio ou só espaços
      USADA EM: todos os "inserir", antes de gravar

  valorPositivo(valor)
      -> true se é número maior que 0
      USADA EM: potenciaKw (postos), precoPorKwh (tarifários),
                energiaKwh e custo (carregamentos)

  dataValida(valor)
      -> true se é uma data que existe
      USADA EM: dataNascimento (clientes),
                dataHoraInicio / dataHoraFim (carregamentos)

  nifValido(nif)
      -> true se tem 9 dígitos
      USADA EM: inserirCliente

  ------------------------------------------------------------
  SUGESTÃO: uma função de leitura validada
  ------------------------------------------------------------
  Se derem por vocês a repetir o mesmo do...while em todos os menus
  ("repete até o valor estar na lista"), vale a pena extrair para aqui
  uma função tipo:

      lerOpcaoValida(mensagem, listaDeValoresValidos)

  MAS: só fazer isso DEPOIS de sentirem a repetição.
  Escrever a abstração antes do problema aparecer só complica.

  ------------------------------------------------------------
  ONDE SE VALIDA O QUÊ (importante)
  ------------------------------------------------------------
     NO MENU          -> formato (é número? está na lista?)
     NO REPOSITÓRIO   -> duplicados e integridade
                         (só ele conhece todos os registos)
*/

export function campoObrigatorio(valor) {
  return valor !== undefined && valor !== null && String(valor).trim() !== ''; //retorna true se o valor não for undefined, null ou string vazia (após remover espaços)
}

export function valorPositivo(valor) {
  return typeof valor === 'number' && valor > 0; 
}
