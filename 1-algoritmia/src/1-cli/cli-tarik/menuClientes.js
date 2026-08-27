import readlineSync from "readline-sync";
import { CONCELHOS_VALIDOS, CONECTORES_VALIDOS, ESTADOS_POSTO_VALIDOS } from "../../utils/constantes.js";
import { lerNumeroPositivo, lerOpcaoValida, lerTextoObrigatorio, lerData, lerTelefone, lerEmail, lerMatricula, soDigitos } from "../../utils/validacao.js";
import { listarClientes, procurarCliente1, inserirCliente1, alterarCliente1, excluirCliente1 } from "../../2-repositories/clienteRepository.js";

const prompt = readlineSync.question;

/*
  MAPA DESTE FICHEIRO
  ===================
  1. LEITURA DA CHAVE (NIF)      — lerNifNovoCliente (um que ainda NÃO exista),
                                   lernifCliente (um que JÁ exista; "0" cancela)
  2. LEITURA DOS DADOS           — lerDadosCliente (campos sem a chave), inserirNovoCliente (chave + campos)
  3. MENU                        — menuClientes (mostra opções, chama o repositório, repete)
*/

//======================================================
//  1. LEITURA DA CHAVE (NIF do cliente)
//======================================================

function lerNifNovoCliente() { //espelho do lernifCliente: repete enquanto o NIF for inválido OU já existir; "0" cancela
  //não usa o lerNif diretamente: o lerNif exige 9 dígitos e nunca deixaria o "0" de cancelar passar
  let nif = lerTextoObrigatorio("Digite o NIF do cliente (9 dígitos, ou 0 para cancelar): ").trim();
  while (nif !== "0" && (nif.length !== 9 || !soDigitos(nif) || procurarCliente1(nif) !== null)) {
    if (nif.length !== 9 || !soDigitos(nif)) {
      console.log("O NIF tem de ter exatamente 9 dígitos.");
    } else {
      console.log("Já existe um cliente com o NIF " + nif + ".");
    }
    nif = lerTextoObrigatorio("Digite o NIF do cliente (9 dígitos, ou 0 para cancelar): ").trim();
  }
  if (nif === "0") {
    return null; //cancelar
  }
  return nif;
}

function lernifCliente(acao) {
  //lê como texto obrigatório, não com lerNif: o lerNif exigia 9 dígitos e rejeitava o "0" antes de o podermos testar
  let nif = lerTextoObrigatorio(`Digite o NIF do cliente a ser ${acao} (ou 0 para cancelar): `).trim();
  while (nif !== "0" && procurarCliente1(nif) === null) {
    console.log("Esse NIF não existe.");
    nif = lerTextoObrigatorio(`NIF (ou 0 para cancelar): `).trim();
  }
  if (nif === "0") {
    return null; // Retorna null se o usuário escolher cancelar a operação
  }
  return nif;
}

//======================================================
//  2. LEITURA DOS DADOS DO CLIENTE
//======================================================

function lerDadosCliente() { //lê os campos de um cliente SEM o NIF — serve para inserir E para atualizar (no atualizar a chave já foi escolhida e não muda)
  const nomeCliente = lerTextoObrigatorio("Digite o nome do cliente: ");
  const dataNascimentoCliente = lerData("Digite a data de nascimento do cliente (AAAA-MM-DD): ");
  const telefoneCliente = lerTelefone("Digite o contacto telefónico do cliente: ");
  const emailCliente = lerEmail("Digite o email do cliente: ");
  const matriculaCliente = lerMatricula("Digite a matrícula da viatura do cliente (XX-XX-XX): ");

  const dadosCliente = {
    nome: nomeCliente, dataNascimento: dataNascimentoCliente,
    contactoTelefone: telefoneCliente, contactoEmail: emailCliente, matricula: matriculaCliente
  }; return dadosCliente
}

function inserirNovoCliente() { //só o inserir pede o NIF; devolve null se o utilizador cancelar
  const nifCliente = lerNifNovoCliente();
  if (nifCliente === null) {
    return null; //cancelou logo no NIF, não há cliente para montar
  }
  const dadosCliente = lerDadosCliente();

  const novoCliente = {
    nif: nifCliente, nome: dadosCliente.nome, dataNascimento: dadosCliente.dataNascimento,
    contactoTelefone: dadosCliente.contactoTelefone, contactoEmail: dadosCliente.contactoEmail, matricula: dadosCliente.matricula
  }; return novoCliente
}

//======================================================
//  3. MENU DE CLIENTES
//======================================================

export function menuClientes() {
  console.log('1. Listar Clientes cadastrados');
  console.log('2. Inserir novo Cliente');
  console.log('3. Atualizar Cliente');
  console.log('4. Remover Cliente');
  console.log('0. Sair');

  const opcao = prompt('Escolha uma opção: ');

  switch (opcao) {
    case '1': {
      console.log(`Os clientes cadastrados atualmente no nosso sistema são: `);
      console.log(listarClientes());
      break;
    }
    case '2': {
      const novoCliente = inserirNovoCliente(); //Função que capta dados do novo cliente e retorna um objeto com esses dados (ou null se o utilizador cancelou)
      if (novoCliente === null) {
        console.log("Operação cancelada.\n");
        break;
      }
      const resultado = inserirCliente1(novoCliente); //função que insere o novo cliente no JSON e retorna null se o cliente já existir lá

      if (resultado === null) {
        console.log("Já existe um cliente com esse NIF.\n");
      } else {
        console.log("Cliente inserido com sucesso.\n");
      }
      break;
    }

    case '3': {

      const nifCliente = lernifCliente("atualizado"); //Guarda o NIF do cliente a ser atualizado
      if (nifCliente === null) {
        break;
      }
      alterarCliente1(nifCliente, lerDadosCliente()); //a chave não muda — pedem-se só os restantes campos; a existência do cliente já foi garantida pelo lernifCliente
      console.log("Cliente atualizado com sucesso.\n");
      break;
    }
    case '4': {
      const nifCliente = lernifCliente("excluído"); //Guarda o NIF do cliente a ser excluído
      if (nifCliente === null) break;              //Se o usuário escolher cancelar a operação, sai do case

      if (excluirCliente1(nifCliente)) { //Função que exclui o cliente do JSON e retorna true se conseguiu excluir, ou false se não conseguiu (porque tem carregamentos associados)
        console.log("Cliente excluído com sucesso.\n");
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

  menuClientes(); //função recursiva para repetir o menu até que o usuário escolha sair
}


