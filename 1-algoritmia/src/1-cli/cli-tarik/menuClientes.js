import readlineSync from "readline-sync";
import { CONCELHOS_VALIDOS, CONECTORES_VALIDOS, ESTADOS_POSTO_VALIDOS } from "../../utils/constantes.js";
import { lerNumeroPositivo, lerOpcaoValida, lerTextoObrigatorio, lerNif, lerData, lerTelefone, lerEmail, lerMatricula } from "../../utils/validacao.js";
import { listarClientes, procurarCliente1, inserirCliente1, alterarCliente1, excluirCliente1 } from "../../2-repositories/clienteRepository.js";

const prompt = readlineSync.question;

//----Funções auxiliares do menu----
function inserirNovoCliente() {
  const nifCliente = lerNif("Digite o NIF do cliente (9 dígitos): ");
  const nomeCliente = lerTextoObrigatorio("Digite o nome do cliente: ");
  const dataNascimentoCliente = lerData("Digite a data de nascimento do cliente (AAAA-MM-DD): ");
  const telefoneCliente = lerTelefone("Digite o contacto telefónico do cliente: ");
  const emailCliente = lerEmail("Digite o email do cliente: ");
  const matriculaCliente = lerMatricula("Digite a matrícula da viatura do cliente (XX-XX-XX): ");

  const novoCliente = {
    nif: nifCliente, nome: nomeCliente, dataNascimento: dataNascimentoCliente,
    contactoTelefone: telefoneCliente, contactoEmail: emailCliente, matricula: matriculaCliente
  }; return novoCliente
}

function lernifCliente(acao) {
  let nif = lerNif(`Digite o NIF do cliente a ser ${acao} (9 dígitos): `);
  while (nif !== "0" && procurarCliente1(nif) === null) {
    console.log("Esse NIF não existe.");
    nif = lerNif(`NIF (ou 0 para cancelar): `);
  }
  if (nif === "0") {
    return null; // Retorna null se o usuário escolher cancelar a operação
  }
  return nif;
}

//----Menu de Clientes----

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
      const novoCliente = inserirNovoCliente(); //Função que capta dados do novo cliente e retorna um objeto com esses dados
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
      const alterarDadosCliente = alterarCliente1(nifCliente, inserirNovoCliente()); //Função que capta dados do novo cliente e retorna um objeto com esses dados
      if (alterarDadosCliente === null) {
        console.log("Não existe um cliente com esse NIF.\n");
      } else {
        console.log("Cliente atualizado com sucesso.\n");
      }
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
      console.log('Até já!');
      return;
    default:
      console.log('Opção inválida.\n');
  }

  menuClientes(); //função recursiva para repetir o menu até que o usuário escolha sair
}



/*
  SUBMENU DE CLIENTES  (Tarik)  —  PASSO 4
  ========================================

  So fazer DEPOIS do menuPostos.js estar a funcionar.
  E a mesma estrutura; o que muda sao os campos e as validacoes.

  ------------------------------------------------------------
  CAMPOS A PEDIR:
  ------------------------------------------------------------
     nome
     nif              <- chave unica (nao pode repetir)
     dataNascimento   <- necessaria para calcular a IDADE no relatorio 4.2
     contacto
     matricula

  ------------------------------------------------------------
  VALIDACOES ESPECIFICAS:
  ------------------------------------------------------------
  - NIF: 9 digitos
  - dataNascimento: tem de ser uma data valida

  ATENCAO ao campo dataNascimento: sem ele nao ha relatorio 4.2.

  ------------------------------------------------------------
  NOTA SOBRE O NIF:
  ------------------------------------------------------------
  O NIF fica guardado como TEXTO, nao como numero.
  Razao: nao se fazem contas com NIFs, e assim nao se perdem
  eventuais zeros a esquerda.
*/
