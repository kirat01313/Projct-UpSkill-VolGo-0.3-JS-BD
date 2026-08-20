import readlineSync from "readline-sync";
import { CONCELHOS_VALIDOS, CONECTORES_VALIDOS, ESTADOS_POSTO_VALIDOS } from "../../utils/constantes.js";
import { lerNumeroPositivo, lerOpcaoValida, lerTextoObrigatorio } from "../../utils/validacao.js";

const prompt = readlineSync.question;

export function menuPostos() {
  console.log('1. Listar Postos cadastrados');
  console.log('2. Inserir novo Posto');
  console.log('3. Atualizar Posto');
  console.log('4. Remover Posto');
  console.log('0. Sair');

  const opcao = prompt('Escolha uma opção: ');

  switch (opcao) {
    case '1':
      //Aqui entra um console.log("Com a função de listar os postos cadastrados que estão no repositório")!
      console.log('TODO: submenu de Listar Postos ainda não implementado.\n');
      break;
    case '2':
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



      //Chamar a função para inserir posto na lista
      //Passar uma mensgem confirmando que foi inserido um posto na lista
      //Perguntar se quer inserir mais um ou voltar ao menu principal

      console.log('TODO: submenu de Inserir Postos ainda não implementado.\n');
      break;
    case '3':
      console.log('TODO: submenu de Atualizar Posto ainda não implementado.\n');
      break;
    case '4':
      console.log('TODO: submenu de Remover Posto ainda não implementado.\n');
      break;
    case '0':
      console.log('Até já!');
      return;
    default:
      console.log('Opção inválida.\n');
  }

  menuPostos();
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
