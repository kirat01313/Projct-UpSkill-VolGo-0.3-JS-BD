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

export function lerTextoObrigatorio(mensagem) { //função que lê um texto do usuário, repetindo a solicitação até que o valor não seja vazio
    let valor = prompt(mensagem).trim();
    while (valor === "") {
        console.log("Este campo é obrigatório. Deve inserir um valor.");
        valor = prompt(mensagem).trim();
    }
    return valor;
}

export function lerNumeroPositivo(mensagem) { //função que lê um número positivo do usuário, repetindo a solicitação até que o valor seja válido
    let valor = Number(prompt(mensagem).trim());
    while (Number.isNaN(valor) || valor <= 0) {
        console.log("Insira um valor numérico maior que zero.");
        valor = Number(prompt(mensagem).trim());
    }
    return valor;
}

export function lerNif(mensagem) { //função que lê um NIF do usuário, repetindo a solicitação até que o valor seja válido (9 dígitos)
    let valor = prompt(mensagem).trim();
    while (valor.length !== 9 || !soDigitos(valor)) {
        console.log("O NIF tem de ter exatamente 9 dígitos.");
        valor = prompt(mensagem).trim();
    }
    return valor;
}

export function lerTelefone(mensagem) { //função que lê um contacto telefónico do usuário, repetindo a solicitação até que o valor seja válido (9 dígitos)
    let valor = prompt(mensagem).trim();
    while (valor.length !== 9 || !soDigitos(valor)) { //sodigitos() é uma função auxiliar que verifica se a string contém apenas dígitos
        console.log("O contacto tem de ter 9 dígitos.");
        valor = prompt(mensagem).trim();
    }
    return valor;
}

export function lerEmail(mensagem) { //função que lê um email do usuário, repetindo a solicitação até que o valor seja válido (contendo "@" e ".")
    let valor = prompt(mensagem).trim().toLowerCase();
    while (valor.indexOf("@") < 1 || valor.indexOf(".") < valor.indexOf("@") + 2 || valor.indexOf(".") === valor.length - 1) {
        console.log("Email inválido. Exemplo: ana@mail.pt");
        valor = prompt(mensagem).trim().toLowerCase();
    }
    return valor;
}

export function lerMatricula(mensagem) { //função que lê uma matrícula do usuário, repetindo a solicitação até que o valor seja válido (formato XX-XX-XX)
    let valor = prompt(mensagem).trim().toUpperCase();
    while (valor.length !== 8 || valor[2] !== "-" || valor[5] !== "-") {
        console.log("Matrícula inválida. Formato: XX-XX-XX (ex.: AA-01-BB).");
        valor = prompt(mensagem).trim().toUpperCase();
    }
    return valor;
}

export function lerData(mensagem) { //função que lê uma data do usuário, repetindo a solicitação até que o valor seja válido (formato AAAA-MM-DD)
    let valor = prompt(mensagem).trim();
    while (!dataValida1(valor)) {
        console.log("Data inválida. Use o formato AAAA-MM-DD (ex.: 1990-05-12).");
        valor = prompt(mensagem).trim();
    }
    return valor;
}

//------------- Auxiliares das funções de validação -------------

function dataValida1(data) { //função auxiliar que verifica se uma string é uma data válida no formato AAAA-MM-DD
    if (data.length !== 10) return false;
    if (data[4] !== "-" || data[7] !== "-") return false;
    const ano = Number(data.substring(0, 4)); //substring(0, 4) pega os 4 primeiros caracteres da string sem incluir o índice final (0, 1, 2 e 3)
    const mes = Number(data.substring(5, 7));
    const dia = Number(data.substring(8, 10));
    if (Number.isNaN(ano) || Number.isNaN(mes) || Number.isNaN(dia)) return false;
    if (mes < 1 || mes > 12) return false;
    if (dia < 1 || dia > 31) return false;
    if (ano < 1900 || ano > 2026) return false;

    //até aqui só confirmamos que cada pedaço está na escala certa, mas isso deixa
    //passar dias que não existem (ex.: 30 de fevereiro). O JavaScript "arruma"
    //essas datas em vez de as rejeitar (30 de fevereiro vira 2 de março), então
    //aproveitamos isso: criamos a data e vemos se o mês continua o que pedimos.
    const dataTeste = new Date(ano, mes - 1, dia); //mes - 1 porque no objeto Date janeiro é 0
    if (dataTeste.getMonth() !== mes - 1) return false; //se o mês mudou, o dia não existia nesse mês (também apanha anos bissextos)

    return true;
}

function soDigitos(texto) { //função auxiliar que verifica se uma string contém apenas dígitos
    for (let i = 0; i < texto.length; i++) {
        if (texto[i] < "0" || texto[i] > "9") return false;
    }
    return true;
}


//Funções de validação do Fred )
export function campoObrigatorio(valor) { //função que verifica se um valor é obrigatório (não pode ser undefined, null ou string vazia)
    return valor !== undefined && valor !== null && String(valor).trim() !== ''; //retorna true se o valor não for undefined, null ou string vazia (após remover espaços)
}

export function valorPositivo(valor) { //função que verifica se um valor é um número positivo (maior que zero)
    return typeof valor === 'number' && valor > 0;
}

export function dataHoraValida(valor) { //função que verifica se uma string tem data E hora completas, no formato AAAA-MM-DD HH:mm
  const texto = String(valor).trim();
  if (texto.length !== 16) return false; //"AAAA-MM-DD HH:mm" tem sempre 16 caracteres
  if (texto[10] !== " " || texto[13] !== ":") return false; //espaço a separar a data da hora, dois pontos a separar a hora dos minutos

  const parteData = texto.substring(0, 10); //"AAAA-MM-DD"
  if (!dataValida1(parteData)) return false; //reaproveita a mesma validação de data usada em lerData (ano/mes/dia, incluindo dias por mês)

  const hora = Number(texto.substring(11, 13));
  const minuto = Number(texto.substring(14, 16));
  if (Number.isNaN(hora) || Number.isNaN(minuto)) return false; //algum dos pedaços não era número
  if (hora < 0 || hora > 23) return false; //hora válida vai de 00 a 23
  if (minuto < 0 || minuto > 59) return false; //minuto válido vai de 00 a 59

  return true;
}