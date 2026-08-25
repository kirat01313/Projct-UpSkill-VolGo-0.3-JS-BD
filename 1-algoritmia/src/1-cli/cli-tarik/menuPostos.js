import readlineSync from "readline-sync";
import { CONCELHOS_VALIDOS, CONECTORES_VALIDOS, ESTADOS_POSTO_VALIDOS } from "../../utils/constantes.js";
import { lerNumeroPositivo, lerOpcaoValida, lerTextoObrigatorio } from "../../utils/validacao.js";
import { listarPostos, inserirPosto1, alterarPosto1, procurarPosto1, excluirPosto1 } from "../../2-repositories/postoRepository.js";

const prompt = readlineSync.question;

//----Funções auxiliares do menu----
function inserirNovoPosto() {
  const codigoPosto = lerTextoObrigatorio("Digite o código do novo Posto: ");
  const concelhoPosto = lerOpcaoValida("Digite o concelho do novo Posto: ", CONCELHOS_VALIDOS);
  const potenciaPosto = lerNumeroPositivo("Digite a potência do novo Posto: ");
  const conectorPosto = lerOpcaoValida("Digite o tipo de conector do novo Posto: ", CONECTORES_VALIDOS);
  const estadoPosto = lerOpcaoValida("Digite o estado atual do novo Posto: ", ESTADOS_POSTO_VALIDOS);

  const novoPosto = {
    codigo: codigoPosto, concelho: concelhoPosto,
    potenciaKw: potenciaPosto, tipoConector: conectorPosto, estado: estadoPosto
  }; return novoPosto
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

//----Menu de Postos----

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
      const novoPosto1 = inserirNovoPosto(); //Função que capta dados do novo posto e retorna um objeto com esses dados
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
      const alterarDadosPosto = alterarPosto1(codigoPosto, inserirNovoPosto()); //Função que capta dados do novo posto e retorna um objeto com esses dados
      if (alterarDadosPosto === null) {
        console.log("Não existe um posto com esse código.\n");
      } else {
        console.log("Posto atualizado com sucesso.\n");
      }
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
      console.log('Até já!');
      return;
    default:
      console.log('Opção inválida.\n');
  }

  menuPostos(); //função recursiva para repetir o menu até que o usuário escolha sair
}





/*
  SUBMENU DE POSTOS  (Tarik)  —  PASSO 3
  ======================================

  Este e o PRIMEIRO submenu a fazer.
  Quando este funcionar, os outros tres sao copia com nomes trocados.

  ------------------------------------------------------------
  AS OPCOES:
  ------------------------------------------------------------
     1. Inserir posto
     2. Listar postos
     3. Atualizar posto
     4. Remover posto
     0. Voltar

  ------------------------------------------------------------
  ORDEM DE CONSTRUCAO (uma de cada vez, testando entre cada):
  ------------------------------------------------------------

  1o) LISTAR   <- comecar SEMPRE por aqui

      Porque? Porque e assim que verificas todo o resto.
      Sem o listar feito, nao sabes se o inserir funcionou.

      - pedir os postos ao repositorio
      - percorrer com um ciclo
      - mostrar cada um com console.log
      - se a lista estiver vazia, dizer "nao ha postos registados"
        (nao deixar o ecra em branco)

  2o) INSERIR

      - perguntar cada campo com prompt:
          codigo, concelho, potenciaKw, tipoConector, estado
      - a potencia e NUMERO -> envolver em Number()
      - campos com valores restritos (estado: ativo / manutencao)
        -> usar do...while, repetindo ate o valor ser valido
      - montar o objeto
      - chamar inserirPosto(objeto)
      - VERIFICAR O RETORNO: se devolver null foi recusado
        (codigo duplicado) -> mostrar mensagem de erro

  3o) ATUALIZAR

      - perguntar o codigo do posto a alterar
      - perguntar os campos novos
      - se a funcao devolver null, o posto nao existe -> avisar

  4o) REMOVER

      - perguntar o codigo
      - se devolver false ou null: ou nao existe, ou tem carregamentos
        associados (integridade referencial) -> avisar com clareza

  ------------------------------------------------------------
  ONDE SE VALIDA O QUE:
  ------------------------------------------------------------
    AQUI (no menu)   -> formato: e numero? esta na lista de valores?
    NO REPOSITORIO   -> duplicados e integridade
                        (so ele conhece todos os postos)

  ------------------------------------------------------------
  NAO ESQUECER:
  ------------------------------------------------------------
  - capturar SEMPRE o retorno das funcoes com =
  - o submenu tambem repete num ciclo; so sai no "0"
*/
