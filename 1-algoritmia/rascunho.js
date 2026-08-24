/*
  ============================================================
  RASCUNHO — COMECAR POR AQUI
  ============================================================

  A ideia deste ficheiro: escrever TUDO aqui dentro primeiro,
  sem imports, sem pastas, sem se preocupar com organizacao.

  So para perceber a logica e ver alguma coisa a funcionar.

  Depois, quando estiver a andar, corta-se e cola-se cada
  pedaco para o ficheiro certo em src/.

  ------------------------------------------------------------
  ORDEM SUGERIDA DENTRO DESTE FICHEIRO:
  ------------------------------------------------------------

  1) DADOS DE EXEMPLO
     Um array com 2-3 postos escritos a mao.
     (ainda sem ficheiros .json — isso vem depois)

  2) FUNCOES DE GESTAO DOS POSTOS
     listarPostos()    -> devolve o array
     inserirPosto()    -> acrescenta ao array
     atualizarPosto()  -> encontra e altera
     removerPosto()    -> tira do array

     NOTA: estas funcoes NAO fazem console.log.
           Elas devolvem valores; quem mostra e o menu.

  3) MENU
     Um ciclo que mostra as opcoes, le a escolha,
     e chama a funcao certa.

  4) TESTAR
     Correr, inserir um posto, listar, ver se aparece.

  ------------------------------------------------------------
  DEPOIS DE FUNCIONAR — para onde vai cada pedaco:
  ------------------------------------------------------------

     os dados de exemplo  ->  data/postos.json
     as funcoes de gestao ->  src/2-repositories/postoRepository.js
     o menu               ->  src/1-cli/cli-tarik/menuPostos.js
     o arranque           ->  index.js

  ============================================================
*/



//tarifarios:

let tarifarios = [
  { nome: 'Normal', precoPorKwh: 0.30, taxaAtivacao: 0 },
  { nome: 'Verde', precoPorKwh: 0.25, taxaAtivacao: 0.50 },
];


function listarTarifarios() {
  return tarifarios;
}

function inserirTarifario(novoTarifario) {
   if (tarifarios.some(t => t.nome === novoTarifario.nome)) {
    return null; // Tarifário já existe
   } else {
    tarifarios.push(novoTarifario);
    return novoTarifario;
   }
}