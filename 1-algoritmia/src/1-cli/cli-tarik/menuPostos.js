import readlineSync from "readline-sync";
import { CONCELHOS_VALIDOS, CONECTORES_VALIDOS, ESTADOS_POSTO_VALIDOS } from "../../utils/constantes.js";
import { lerNumeroPositivo, lerOpcaoValida, lerTextoObrigatorio } from "../../utils/validacao.js";
import { listarPostos, inserirPosto1, alterarPosto1, procurarPosto1, excluirPosto1 } from "../../2-repositories/postoRepository.js";

const prompt = readlineSync.question;

/*
  MAPA DESTE FICHEIRO
  ===================
  1. LEITURA DA CHAVE (código)   — lerCodigoNovoPosto (um que ainda NÃO exista),
                                   lercodigoPosto (um que JÁ exista; "0" cancela)
  2. LEITURA DOS DADOS           — lerDadosPosto (campos sem a chave), inserirNovoPosto (chave + campos)
  3. MENU                        — menuPostos (mostra opções, chama o repositório, repete)
*/

//======================================================
//  1. LEITURA DA CHAVE (código do posto)
//======================================================

function lerCodigoNovoPosto() { //espelho do lercodigoPosto: aqui repete enquanto o código JÁ existir
  let codigo = lerTextoObrigatorio("Digite o código do novo Posto (ou 0 para cancelar): ").trim().toUpperCase();
  while (codigo !== "0" && procurarPosto1(codigo) !== null) {
    console.log("Já existe um posto com o código " + codigo + ". Escolha outro.");
    codigo = lerTextoObrigatorio("Digite o código do novo Posto (ou 0 para cancelar): ").trim().toUpperCase();
  }
  if (codigo === "0") {
    return null; //"0" fica reservado para cancelar — assim nunca chega a existir um posto com esse código, que depois seria impossível de gerir
  }
  return codigo;
}

function lercodigoPosto(acao) {
  let codigo = lerTextoObrigatorio(`Digite o Código do posto a ser ${acao} (ou 0 para cancelar): `).trim().toUpperCase();
  while (codigo !== "0" && procurarPosto1(codigo) === null) {
    console.log("Esse código não existe.");
    codigo = lerTextoObrigatorio(`Código (ou 0 para cancelar): `).trim().toUpperCase();
  }
  if (codigo === "0") {
    return null; // Retorna null se o usuário escolher cancelar a operação
  }
  return codigo;
}

//======================================================
//  2. LEITURA DOS DADOS DO POSTO
//======================================================

function lerDadosPosto() { //lê os campos de um posto SEM o código — serve para inserir E para atualizar (no atualizar a chave já foi escolhida e não muda)
  const concelhoPosto = lerOpcaoValida("Digite o concelho do Posto: ", CONCELHOS_VALIDOS);
  const potenciaPosto = lerNumeroPositivo("Digite a potência do Posto: ");
  const conectorPosto = lerOpcaoValida("Digite o tipo de conector do Posto: ", CONECTORES_VALIDOS);
  const estadoPosto = lerOpcaoValida("Digite o estado atual do Posto: ", ESTADOS_POSTO_VALIDOS);

  const dadosPosto = {
    concelho: concelhoPosto, potenciaKw: potenciaPosto,
    tipoConector: conectorPosto, estado: estadoPosto
  }; return dadosPosto
}

function inserirNovoPosto() { //só o inserir pede o código; devolve null se o utilizador cancelar
  const codigoPosto = lerCodigoNovoPosto();
  if (codigoPosto === null) {
    return null; //cancelou logo no código, não há posto para montar
  }
  const dadosPosto = lerDadosPosto();

  const novoPosto = {
    codigo: codigoPosto, concelho: dadosPosto.concelho,
    potenciaKw: dadosPosto.potenciaKw, tipoConector: dadosPosto.tipoConector, estado: dadosPosto.estado
  }; return novoPosto
}

//======================================================
//  3. MENU DE POSTOS
//======================================================

export function menuPostos() {
  console.log('1. Listar Postos cadastrados');
  console.log('2. Inserir novo Posto');
  console.log('3. Atualizar Posto');
  console.log('4. Remover Posto');
  console.log('0. Sair');

  const opcao = prompt('Escolha uma opção: ');

  switch (opcao) {
    case '1': {
      console.log(`Os postos cadastrados atualmente no nosso sistema são: `);
      console.log(listarPostos());
      break;
    }
    case '2': {
      const novoPosto1 = inserirNovoPosto(); //Função que capta dados do novo posto e retorna um objeto com esses dados (ou null se o utilizador cancelou)
      if (novoPosto1 === null) {
        console.log("Operação cancelada.\n");
        break;
      }
      const resultado = inserirPosto1(novoPosto1); //função que insere o novo posto no JSON e retorna null se o posto já existir lá

      if (resultado === null) {
        console.log("Já existe um posto com esse código.\n");
      } else {
        console.log("Posto inserido com sucesso.\n");
      }
      break;
    }

    case '3': {

      const codigoPosto = lercodigoPosto("atualizado"); //Guarda o código do posto a ser atualizado
      if (codigoPosto === null) {
        break;
      }
      alterarPosto1(codigoPosto, lerDadosPosto()); //a chave não muda — pedem-se só os restantes campos; a existência do posto já foi garantida pelo lercodigoPosto
      console.log("Posto atualizado com sucesso.\n");
      break;
    }

    case '4': {
      const codigoPosto = lercodigoPosto("excluído"); //Guarda o código do posto a ser excluído
      if (codigoPosto === null) break;              //Se o usuário escolher cancelar a operação, sai do case

      if (excluirPosto1(codigoPosto)) { //Função que exclui o posto do JSON e retorna true se conseguiu excluir, ou false se não conseguiu (porque tem carregamentos associados)
        console.log("Posto excluído com sucesso.\n");
      } else {
        console.log("Não foi possível remover: tem carregamentos associados.\n");
      }
      break;
    };

    case '0':
      return; //volta ao menu principal sem mensagem — o "Até já!" é só da saída real da aplicação
    default:
      console.log('Opção inválida.\n');
  }

  menuPostos(); //função recursiva para repetir o menu até que o usuário escolha sair
}
