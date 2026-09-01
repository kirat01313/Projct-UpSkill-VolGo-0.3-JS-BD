import path from 'node:path';                                                             //importa o módulo path do Node.js para manipulação de caminhos de arquivos
import { readFileSync, writeFileSync, existsSync } from 'node:fs';                        //importa funções do módulo fs do Node.js para leitura e escrita de arquivos
import { campoObrigatorio, valorPositivo } from '../utils/validacao.js';
import { listarCarregamentos } from './carregamentoRepository.js';                        //importa a função listarCarregamentos do repositório de carregamentos para verificar integridade referencial

const caminhoTarifarios = path.join(import.meta.dirname, '../../data/tarifarios.json');   //define o caminho do arquivo JSON que armazenará os dados dos tarifários

//======================================================
//  LER  (listar)
//======================================================

export function listarTarifarios() {
  if (!existsSync(caminhoTarifarios)) return [];                                          //verifica se o arquivo de tarifários existe; se não existir, retorna um array vazio
  const conteudo = readFileSync(caminhoTarifarios, 'utf-8');                              //lê o conteúdo do arquivo de tarifários como uma string
  if (conteudo.trim() === '') return [];                                                  //verifica se o conteúdo do arquivo está vazio; se estiver, retorna um array vazio
  return JSON.parse(conteudo);                                                            //converte a string JSON em um array de objetos e retorna esse array
}

//======================================================
//  ESCREVER  (inserir / atualizar / remover)
//======================================================

export function inserirTarifario(novoTarifario) {
  if (!campoObrigatorio(novoTarifario.nome)) {
    return null; // nome vazio, recusa
  }
  if (!valorPositivo(novoTarifario.precoPorKwh)) {
    return null; // preço inválido, recusa
  }

  const tarifarios = listarTarifarios();
  if (tarifarios.some(t => t.nome.toLowerCase() === novoTarifario.nome.toLowerCase())) {  // verifica se já existe um tarifário com o mesmo nome (ignorando maiúsculas/minúsculas)
    return null; // já existe
  }

  tarifarios.push(novoTarifario);                                                         // adiciona o novo tarifário ao array de tarifários
  gravarTarifarios(tarifarios);
  return novoTarifario;
}

export function atualizarTarifario(nome, dados) {                                         // nome é a chave, não se pode alterar
   const tarifarios = listarTarifarios();
   const index = tarifarios.findIndex(t => t.nome.toLowerCase() === nome.toLowerCase());  // procura pelo nome, ignorando maiúsculas/minúsculas
   if (index === -1) return null; // não encontrado
   tarifarios[index] = { ...tarifarios[index], ...dados };                                // atualiza os campos com os novos dados
   gravarTarifarios(tarifarios);
   return tarifarios[index];
}

export function removerTarifario(nome) {
   // Integridade referencial: não remove se algum carregamento usa este tarifário
   const carregamentos = listarCarregamentos();                                           // lista todos os carregamentos do repositório
   let emUso = false;                                                                     // percorre todos os carregamentos para verificar se algum deles está usando o tarifário que se deseja remover
   for (let i = 0; i < carregamentos.length; i++) {                                       // percorre todos os carregamentos
     if (carregamentos[i].tarifario.toLowerCase() === nome.toLowerCase()) {               // compara o nome do tarifário do carregamento com o nome do tarifário que se deseja remover, ignorando maiúsculas/minúsculas
       emUso = true;                                                                      // encontrou um carregamento que usa este tarifário
     }
   }
   if (emUso) {                                                                           // se algum carregamento está usando o tarifário, não permite a remoção e retorna false
     return false; // recusa a remoção, está em uso
   }

   const tarifarios = listarTarifarios();                                                 // lista todos os tarifários do repositório
   const index = tarifarios.findIndex(t => t.nome.toLowerCase() === nome.toLowerCase());  // procura pelo nome do tarifário que se deseja remover, ignorando maiúsculas/minúsculas
   if (index === -1) return false;                                                        // se não encontrar o tarifário, retorna false
   tarifarios.splice(index, 1);                                                           // remove o tarifário do array de tarifários
   gravarTarifarios(tarifarios);                                                          // grava o array atualizado de tarifários no arquivo JSON
   return true;
}

//======================================================
//  AUXILIAR PRIVADA  (gravação no ficheiro)
//======================================================

function gravarTarifarios(tarifarios) {
  writeFileSync(caminhoTarifarios, JSON.stringify(tarifarios, null, 2), 'utf-8');         //converte o array de objetos em uma string JSON formatada e grava no arquivo de tarifários
}
