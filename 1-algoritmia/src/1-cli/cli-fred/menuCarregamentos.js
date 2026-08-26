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

import readlineSync from 'readline-sync';                                  // biblioteca de leitura síncrona do terminal (mesma dos exercícios das aulas)
import { lerOpcaoValida } from '../../utils/validacao.js';                 // função do Tarik: pergunta e repete até vir um valor da lista permitida
import {
  listarCarregamentos,
  inserirCarregamento,
  atualizarCarregamento,
  removerCarregamento,
} from '../../2-repositories/carregamentoRepository.js';                   // as 4 funções de CRUD do repositório de carregamentos
import { listarTarifarios } from '../../2-repositories/tarifarioRepository.js'; // usado para calcular o custo a partir do preço do tarifário

const ESTADOS_VALIDOS = ['em curso', 'terminado', 'faturado', 'anulado']; // lista fixa usada pelo lerOpcaoValida, pra não aceitar um estado escrito errado

export function menuCarregamentos() { // função que mostra o submenu de Carregamentos e trata cada opção escolhida
  let opcao = ''; // começa vazia, só pra garantir que o while entra pelo menos uma vez

  while (opcao !== '0') { // repete o submenu até o utilizador escolher voltar
    console.log('\n--- Carregamentos ---');
    console.log('1. Inserir  2. Listar  3. Atualizar  4. Remover  0. Voltar');
    opcao = readlineSync.question('Opção: '); // lê a opção escolhida (sempre como texto)

    if (opcao === '1') {
      // A validação de campos vazios, data inválida, e existência de posto/tarifário
      // já acontece dentro do inserirCarregamento (repositório) — aqui só se lê o input.
      
      const posto = readlineSync.question('Código do posto: ');                                  // lê o código do posto do utilizador
      const cliente = readlineSync.question('NIF do cliente: ');                                  // lê o NIF do cliente do utilizador
      const tarifario = readlineSync.question('Nome do tarifário: ');                              // lê o nome do tarifário do utilizador
      const dataHoraInicio = readlineSync.question('Data/hora de início (AAAA-MM-DD HH:mm): ');    // lê a data/hora de início do utilizador

      const resultado = inserirCarregamento({ posto, cliente, tarifario, dataHoraInicio }); // chama o repositório com os dados lidos
      if (resultado === null) { // null significa que alguma validação recusou (campo vazio, data inválida, ou posto/tarifário inexistente)
        console.log('Não foi possível inserir — verifique se todos os campos estão certos e se o posto/tarifário existem.');
      } else {
        console.log('Carregamento inserido:', resultado); // mostra o carregamento completo, já com o id gerado
      }
    } else if (opcao === '2') {
      console.log(listarCarregamentos()); // só busca e imprime, sem lógica nenhuma aqui
    } else if (opcao === '3') {
      const id = Number(readlineSync.question('ID do carregamento: '));                                          // lê o id e converte pra número (o input vem sempre como texto)

      // busca o carregamento primeiro — precisamos saber o TARIFÁRIO dele para calcular o custo mais à frente
      const carregamentos = listarCarregamentos();
      let carregamentoAtual = null;                                                                              // bandeira: fica null até encontrar o carregamento com esse id
      for (let i = 0; i < carregamentos.length; i++) {
        if (carregamentos[i].id === id) {
          carregamentoAtual = carregamentos[i];
        }
      }

      if (carregamentoAtual === null) {
        console.log('Carregamento não encontrado.');
      } else {
        const estado = lerOpcaoValida('Novo estado (em curso/terminado/faturado/anulado): ', ESTADOS_VALIDOS);     // lê o novo estado, repetindo até ser um dos 4 válidos

        const dadosNovos = { estado }; // objeto que vai crescendo conforme o estado escolhido
        if (estado === 'terminado' || estado === 'faturado') { // só pede os campos de fecho se o carregamento está mesmo terminando
          dadosNovos.dataHoraFim = readlineSync.question('Data/hora de fim (AAAA-MM-DD HH:mm): ');   // lê a data/hora de fim
          dadosNovos.energiaKwh = Number(readlineSync.question('Energia fornecida (kWh): '));        // lê a energia consumida, medida pelo posto

          // custo NÃO é perguntado — é calculado a partir da energia medida e do preço do tarifário deste carregamento
          const tarifarios = listarTarifarios();                                                     // busca todos os tarifários já cadastrados
          let tarifarioUsado = null;                                                                  // bandeira: fica null até encontrar o tarifário do carregamento
          for (let i = 0; i < tarifarios.length; i++) {
            if (tarifarios[i].nome.toLowerCase() === carregamentoAtual.tarifario.toLowerCase()) {
              tarifarioUsado = tarifarios[i];
            }
          }
          dadosNovos.custo = dadosNovos.energiaKwh * tarifarioUsado.precoPorKwh + tarifarioUsado.taxaAtivacao; // energia × preço por kWh, mais a taxa de ativação
        }

        const resultado = atualizarCarregamento(id, dadosNovos); // envia só os campos que mudaram
        if (resultado === null) { // aqui já sabemos que o id existe, então null só pode significar: energia impossível para este posto/duração
          console.log('Não foi possível atualizar — a energia informada não é possível para este posto, na duração indicada.');
        } else {
          console.log('Carregamento atualizado:', resultado);
        }
      }
    } else if (opcao === '4') {
      const id = Number(readlineSync.question('ID do carregamento a remover: ')); // lê o id a remover

      const removido = removerCarregamento(id); // devolve true/false, nunca precisa de integridade referencial aqui
      console.log(removido ? 'Carregamento removido.' : 'Carregamento não encontrado.');
    } else if (opcao !== '0') { // qualquer opção que não seja 1-4 nem 0
      console.log('Opção inválida.');
    }
  }
}
