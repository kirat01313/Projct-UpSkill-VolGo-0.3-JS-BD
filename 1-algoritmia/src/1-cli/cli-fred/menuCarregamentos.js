import readlineSync from 'readline-sync';                                  // biblioteca de leitura síncrona do terminal (mesma dos exercícios das aulas)
import { lerOpcaoValida, lerDataHora, lerDataHoraDepoisDe, lerNumeroPositivo, lerInteiroPositivo, lerTextoObrigatorio } from '../../utils/validacao.js';                 // função do Tarik: pergunta e repete até vir um valor da lista permitida
import {
  listarCarregamentos,
  inserirCarregamento,
  atualizarCarregamento,
  removerCarregamento,
} from '../../2-repositories/carregamentoRepository.js';                   // as 4 funções de CRUD do repositório de carregamentos
import { listarTarifarios } from '../../2-repositories/tarifarioRepository.js';
import { listarPostos } from '../../2-repositories/postoRepository.js';   // usado para repetir a pergunta até o código do posto existir
import { listarClientes } from '../../2-repositories/clienteRepository.js'; // usado para repetir a pergunta até o NIF do cliente existir

const ESTADOS_VALIDOS = ['em curso', 'terminado', 'faturado', 'anulado']; // lista fixa usada pelo lerOpcaoValida, pra não aceitar um estado escrito errado

/*
  MAPA
  ===================
  1. AUXILIAR GENÉRICA           — procurarNaLista (procura um item por campo, ignorando maiúsculas)
  2. LEITURA COM EXISTÊNCIA      — lerCodigoPostoExistente, lerNifClienteExistente, lerNomeTarifarioExistente
                                   (repetem até o valor EXISTIR; "0" cancela e devolve null)
  3. FLUXO DE INSERÇÃO           — inserirCarregamentoInterativo (os 4 campos + saídas de cancelar/manutenção)
  4. MENU                        — menuCarregamentos (opções 1-4 e 0)
*/

//======================================================
//  1. AUXILIAR GENÉRICA
//======================================================

function procurarNaLista(lista, campo, valor) { //percorre a lista e devolve o item cujo campo bate certo, ignorando maiúsculas
  for (let i = 0; i < lista.length; i++) {
    if (lista[i][campo].toLowerCase() === valor.toLowerCase()) {
      return lista[i];
    }
  }
  return null;
}

//======================================================
//  2. LEITURA COM EXISTÊNCIA GARANTIDA  ("0" cancela e devolve null)
//======================================================

function lerCodigoPostoExistente(mensagem) {
  let codigo = lerTextoObrigatorio(mensagem).trim();
  while (codigo !== '0' && procurarNaLista(listarPostos(), 'codigo', codigo) === null) {
    console.log('Esse posto não existe.');
    codigo = lerTextoObrigatorio(mensagem).trim();
  }
  if (codigo === '0') return null; // o utilizador cancelou; é o menu que decide o que fazer com isso
  return codigo;
}

function lerNifClienteExistente(mensagem) {
  let nif = lerTextoObrigatorio(mensagem).trim();
  while (nif !== '0' && procurarNaLista(listarClientes(), 'nif', nif) === null) {
    console.log('Esse cliente não existe.');
    nif = lerTextoObrigatorio(mensagem).trim();
  }
  if (nif === '0') return null; // cancelar
  return nif;
}

function lerNomeTarifarioExistente(mensagem) {
  let nome = lerTextoObrigatorio(mensagem).trim();
  while (nome !== '0' && procurarNaLista(listarTarifarios(), 'nome', nome) === null) {
    console.log('Esse tarifário não existe.');
    nome = lerTextoObrigatorio(mensagem).trim();
  }
  if (nome === '0') return null; // cancelar
  return nome;
}

//======================================================
//  3. FLUXO DE INSERÇÃO
//======================================================

function inserirCarregamentoInterativo() { // lê os 4 campos e insere; devolve mais cedo se o utilizador cancelar ou o posto não estiver ativo
  // A validação de campos vazios, data inválida, e existência de posto/tarifário
  // já acontece dentro do inserirCarregamento (repositório) — aqui só se lê o input.

  const posto = lerCodigoPostoExistente('Código do posto (ou 0 para cancelar): ');       // lê o código do posto do utilizador
  if (posto === null) {
    console.log('Operação cancelada.');
    return;
  }

  // aviso cedo e com a causa certa: o repositório também recusa posto não-ativo, mas só no fim,
  // depois de o utilizador já ter escrito os 4 campos — e com uma mensagem genérica
  const postoEscolhido = procurarNaLista(listarPostos(), 'codigo', posto);               // já se sabe que existe; falta saber o estado
  if (postoEscolhido.estado !== 'ativo') {
    console.log('O posto ' + postoEscolhido.codigo + ' está em manutenção — não pode receber carregamentos.');
    return;
  }

  const cliente = lerNifClienteExistente('NIF do cliente (ou 0 para cancelar): ');       // lê o NIF do cliente do utilizador
  if (cliente === null) {
    console.log('Operação cancelada.');
    return;
  }

  const tarifario = lerNomeTarifarioExistente('Nome do tarifário (ou 0 para cancelar): '); // lê o nome do tarifário do utilizador
  if (tarifario === null) {
    console.log('Operação cancelada.');
    return;
  }

  const dataHoraInicio = lerDataHora('Data/hora de início (AAAA-MM-DD HH:mm): ');        // lê a data/hora de início do utilizador

  const resultado = inserirCarregamento({ posto, cliente, tarifario, dataHoraInicio });  // chama o repositório com os dados lidos
  if (resultado === null) { // null significa que alguma validação do repositório recusou (é a rede de segurança; as causas comuns já foram tratadas acima)
    console.log('Não foi possível inserir — verifique se todos os campos estão certos e se o posto/tarifário existem.');
  } else {
    console.log('Carregamento inserido:', resultado); // mostra o carregamento completo, já com o id gerado
  }
}

//======================================================
//  4. MENU DE CARREGAMENTOS
//======================================================

export function menuCarregamentos() { // função que mostra o submenu de Carregamentos e trata cada opção escolhida
  let opcao = ''; // começa vazia, só pra garantir que o while entra pelo menos uma vez

  while (opcao !== '0') { // repete o submenu até o utilizador escolher voltar
    console.log('\n--- Carregamentos ---');
    console.log('1. Inserir  2. Listar  3. Atualizar  4. Remover  0. Voltar');
    opcao = readlineSync.question('Opção: '); // lê a opção escolhida (sempre como texto)

    if (opcao === '1') {
      inserirCarregamentoInterativo(); // fluxo com vários pontos de saída (cancelar/manutenção) — numa função própria para poder usar return
    } else if (opcao === '2') {
      console.log(listarCarregamentos()); // só busca e imprime, sem lógica nenhuma aqui
    } else if (opcao === '3') {
      const id = lerInteiroPositivo('ID do carregamento: ');                                          // lê o id e converte pra número (o input vem sempre como texto)

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
        let tarifarioEmFalta = false;  // trava o fecho se o tarifário do carregamento já não existir

        if (estado === 'terminado' || estado === 'faturado') { // só pede os campos de fecho se o carregamento está mesmo terminando

          // O custo é calculado a partir do tarifário DESTE carregamento, por isso procura-se
          // primeiro: se já não existir, não há preço para aplicar e não vale a pena pedir o resto.
          // Acontece com registos antigos cujo tarifário desapareceu (ex.: o carregamento #10).
          const tarifarios = listarTarifarios();                                                     // busca todos os tarifários já cadastrados
          let tarifarioUsado = null;                                                                  // bandeira: fica null até encontrar o tarifário do carregamento
          for (let i = 0; i < tarifarios.length; i++) {
            if (tarifarios[i].nome.toLowerCase() === carregamentoAtual.tarifario.toLowerCase()) {
              tarifarioUsado = tarifarios[i];
            }
          }

          if (tarifarioUsado === null) {
            tarifarioEmFalta = true;                                                    // não se lê mais nada; a mensagem é dada em baixo
          } else {
            dadosNovos.dataHoraFim = lerDataHoraDepoisDe('Data/hora de fim (AAAA-MM-DD HH:mm): ', carregamentoAtual.dataHoraInicio);   // lê a data/hora de fim
            dadosNovos.energiaKwh = lerNumeroPositivo('Energia fornecida (kWh): ');     // lê a energia consumida, medida pelo posto
            // custo NÃO é perguntado — é calculado a partir da energia medida e do preço do tarifário
            dadosNovos.custo = dadosNovos.energiaKwh * tarifarioUsado.precoPorKwh + tarifarioUsado.taxaAtivacao; // energia × preço por kWh, mais a taxa de ativação
          }
        }

        if (tarifarioEmFalta) {
          console.log('Não foi possível fechar — o tarifário "' + carregamentoAtual.tarifario + '" deste carregamento já não existe.');
        } else {
          const resultado = atualizarCarregamento(id, dadosNovos); // envia só os campos que mudaram
          if (resultado === null) { // aqui já sabemos que o id existe, então null só pode significar: energia impossível para este posto/duração
            console.log('Não foi possível atualizar — a energia informada não é possível para este posto, na duração indicada.');
          } else {
            console.log('Carregamento atualizado:', resultado);
          }
        }
      }
    } else if (opcao === '4') {
      const id = lerInteiroPositivo('ID do carregamento a remover: '); // lê o id a remover

      const removido = removerCarregamento(id); // devolve true/false, nunca precisa de integridade referencial aqui
      console.log(removido ? 'Carregamento removido.' : 'Carregamento não encontrado.');
    } else if (opcao !== '0') { // qualquer opção que não seja 1-4 nem 0
      console.log('Opção inválida.');
    }
  }
}
