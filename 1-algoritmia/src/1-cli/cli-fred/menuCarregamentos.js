/*
  SUBMENU DE CARREGAMENTOS  (Fred)
  ================================

  E a ENTIDADE PRINCIPAL do trabalho, e a mais trabalhosa.
  Deixar para depois dos tarifarios estarem a funcionar.

  ------------------------------------------------------------
  CAMPOS A PEDIR:
  ------------------------------------------------------------
     posto            <- o CODIGO de um posto que ja exista
     cliente          <- o NIF de um cliente que ja exista
     tarifario        <- o NOME de um tarifario que ja exista
     dataHoraInicio
     dataHoraFim
     energiaKwh       <- NUMERO
     custo            <- NUMERO
     estado           <- em curso | terminado | faturado | anulado

  ------------------------------------------------------------
  DUAS COISAS IMPORTANTES:
  ------------------------------------------------------------

  1) GUARDAR SO O IDENTIFICADOR, nunca o objeto inteiro.

     Certo:   posto: "P001"
     Errado:  posto: { codigo: "P001", concelho: "Braga", ... }

     Porque? Se o objeto inteiro for copiado para dentro do carregamento,
     e depois alguem alterar o posto, o carregamento fica com dados velhos.

  2) OS ESTADOS TEM DE SER ESCRITOS EXATAMENTE IGUAL em todo o lado.

     O dashboard e os relatorios filtram por estes valores.
     Se um escrever Terminado e outro terminado, nada bate certo.

     Sugestao: do...while com a lista dos 4 estados validos,
     e passar sempre por .trim().toLowerCase().

  ------------------------------------------------------------
  VALIDACAO EXTRA (especifica desta entidade):
  ------------------------------------------------------------
  Ao inserir, verificar se o posto / cliente / tarifario indicados
  EXISTEM mesmo. Senao cria-se um carregamento que aponta para o vazio —
  exatamente o problema que a integridade referencial evita.
*/

import readlineSync from 'readline-sync';
import { lerOpcaoValida } from '../../utils/validacao.js';
import {
  listarCarregamentos,
  inserirCarregamento,
  atualizarCarregamento,
  removerCarregamento,
} from '../../2-repositories/carregamentoRepository.js';

const ESTADOS_VALIDOS = ['em curso', 'terminado', 'faturado', 'anulado']; //informação que vai ser usada para validar o estado do carregamento

export function menuCarregamentos() { //função que exibe o menu de carregamentos e permite ao usuário interagir com ele
  let opcao = ''; 

  while (opcao !== '0') {
    console.log('\n--- Carregamentos ---');
    console.log('1. Inserir  2. Listar  3. Atualizar  4. Remover  0. Voltar');
    opcao = readlineSync.question('Opção: ');

    if (opcao === '1') {
      // TODO: confirmar que posto/cliente/tarifario existem de facto
      // (precisa dos repositórios deles prontos — por agora só valida que não vêm vazios)
      const posto = readlineSync.question('Código do posto: ');
      const cliente = readlineSync.question('NIF do cliente: ');
      const tarifario = readlineSync.question('Nome do tarifário: ');
      const dataHoraInicio = readlineSync.question('Data/hora de início (AAAA-MM-DD HH:mm): ');

      const resultado = inserirCarregamento({ posto, cliente, tarifario, dataHoraInicio });
      if (resultado === null) {
        console.log('Não foi possível inserir — falta algum campo obrigatório.');
      } else {
        console.log('Carregamento inserido:', resultado);
      }
    } else if (opcao === '2') {
      console.log(listarCarregamentos());
    } else if (opcao === '3') {
      const id = Number(readlineSync.question('ID do carregamento: '));
      const estado = lerOpcaoValida('Novo estado (em curso/terminado/faturado/anulado): ', ESTADOS_VALIDOS);

      const dadosNovos = { estado };
      if (estado === 'terminado' || estado === 'faturado') {
        dadosNovos.dataHoraFim = readlineSync.question('Data/hora de fim (AAAA-MM-DD HH:mm): ');
        dadosNovos.energiaKwh = Number(readlineSync.question('Energia fornecida (kWh): '));
        dadosNovos.custo = Number(readlineSync.question('Custo (EUR): '));
      }

      const resultado = atualizarCarregamento(id, dadosNovos);
      if (resultado === null) {
        console.log('Carregamento não encontrado.');
      } else {
        console.log('Carregamento atualizado:', resultado);
      }
    } else if (opcao === '4') {
      const id = Number(readlineSync.question('ID do carregamento a remover: '));

      const removido = removerCarregamento(id);
      console.log(removido ? 'Carregamento removido.' : 'Carregamento não encontrado.');
    } else if (opcao !== '0') {
      console.log('Opção inválida.');
    }
  }
}
