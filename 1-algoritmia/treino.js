import path from 'node:path'; //biblioteca do proprio node para definir caminhos de ficheiros
import { readFileSync, writeFileSync, existsSync } from 'node:fs'; //ler ficheiro, escrever ficheiro, verificar se existe ficheiro

const caminhoPostos = path.join(import.meta.dirname, 'data/postos.json'); //define o endereço do ficheiro e o nome do ficheiro em uma constante
const caminhoCarregamentos = path.join(import.meta.dirname, 'data/carregamentos.json'); //define o endereço do ficheiro e o nome do ficheiro em uma constante


//======================================================
//  TESTE Listar os postos ordenados por potência, do maior para o menor.
//======================================================
 
const postos = JSON.parse(readFileSync(caminhoPostos, 'utf-8'));
console.log(postos);

for (let i = 0; i < postos.length; i++) {
    console.log(postos[i].potenciaKw);
}
postos.sort((a, b) => a.potenciaKw - b.potenciaKw);
console.log(postos);

const somentePotencias =[];
for (let i = 0; i < postos.length; i++) {
    somentePotencias.push(postos[i].potenciaKw);
}

somentePotencias.sort((a, b) => a - b);
console.log(somentePotencias);

//======================================================

const postos = listarPostos();
const potencias = [];

for (let i = 0; i < postos.length; i++) {
  potencias.push(postos[i].potenciaKw);
}

potencias.sort((a, b) => a - b);

for (let i = 0; i < potencias.length; i++) {
  console.log(potencias[i] + ' kW');
}

//======================================================
// lista de ranking dos clientes que tiveram mais gasto de energia
//======================================================

const clientes = listarClientes();
const carregamentos = listarCarregamentos();
const ranking = [];

for (let i = 0; i < clientes.length; i++) {
  let energiaTotal = 0;
  for (let j = 0; j < carregamentos.length; j++) {
    if (carregamentos[j].cliente === clientes[i].nif) {
      energiaTotal = energiaTotal + carregamentos[j].energiaKwh;
    }
  }
  ranking.push({ nome: clientes[i].nome, energiaTotal: energiaTotal });
}

ranking.sort((a, b) => b.energiaTotal - a.energiaTotal);

for (let i = 0; i < ranking.length; i++) {
  console.log((i + 1) + 'º  ' + ranking[i].nome + ' - ' + ranking[i].energiaTotal + ' kWh');
}

//======================================================
// Carregamentos e energia por tipo de conector
//======================================================

const postos = listarPostos();
const carregamentos = listarCarregamentos();
const porConector = {};

for (let i = 0; i < carregamentos.length; i++) {

  let conector = null;                                    // o conector está no POSTO, não no carregamento
  for (let j = 0; j < postos.length; j++) {
    if (postos[j].codigo.toLowerCase() === carregamentos[i].posto.toLowerCase()) {
      conector = postos[j].tipoConector;
    }
  }
  if (conector === null) continue;                        // posto inexistente: salta

  if (!porConector[conector]) {
    porConector[conector] = { quantidade: 0, energia: 0 };
  }
  porConector[conector].quantidade++;
  porConector[conector].energia = porConector[conector].energia + carregamentos[i].energiaKwh;
}

for (const conector in porConector) {
  console.log(conector + ' -> ' + porConector[conector].quantidade + ' carregamento(s), ' + porConector[conector].energia + ' kWh');
}

//======================================================
//Postos que nunca tiveram carregamentos
//======================================================

const postos = listarPostos();
const carregamentos = listarCarregamentos();

for (let i = 0; i < postos.length; i++) {
  let temCarregamento = false;

  for (let j = 0; j < carregamentos.length; j++) {
    if (carregamentos[j].posto.toLowerCase() === postos[i].codigo.toLowerCase()) {
      temCarregamento = true;
    }
  }

  if (!temCarregamento) {
    console.log(postos[i].codigo + ' | ' + postos[i].concelho + ' | ' + postos[i].potenciaKw + ' kW');
  }
}

//======================================================
//Apagar um posto que tenha carregamentos associados mas não carregamentos ativos
//======================================================


/*
1 · No postoRepository.js

No fim do ficheiro, ao lado das outras. Não precisa de imports novos — o listarCarregamentos já lá está.

export function contarCarregamentosEmCurso(codigo) { //quantos carregamentos estão a decorrer neste posto agora
    const carregamentos = listarCarregamentos();
    let quantos = 0;
    for (let i = 0; i < carregamentos.length; i++) {
        if (carregamentos[i].posto.toLowerCase() === codigo.toLowerCase() && carregamentos[i].estado === 'em curso') {
            quantos++;
        }
    }
    return quantos;
}

Repara no &&: têm de ser as duas condições — ser deste posto e estar em curso.

2 · No menuPostos.js

Acrescenta ao import do repositório:

import { listarPostos, inserirPosto1, alterarPosto1, procurarPosto1, excluirPosto1, contarCarregamentosEmCurso } from "../../2-repositories/postoRepository.js";

E no case '3', troca esta linha:

      alterarPosto1(codigoPosto, lerDadosPosto());

por isto:

      const dadosPosto = lerDadosPosto();

      if (dadosPosto.estado === "manutencao") {          //só avisa quando o posto está mesmo a ser desativado
        const emCurso = contarCarregamentosEmCurso(codigoPosto);
        if (emCurso > 0) {
          console.log("ATENÇÃO: este posto tem " + emCurso + " carregamento(s) EM CURSO neste momento.");
          const resposta = lerOpcaoValida("Passar para manutenção mesmo assim? (s/n): ", ["s", "n"]);
          if (resposta === "n") {
            console.log("Operação cancelada. O posto não foi alterado.\n");
            break;                                        //sai do case sem gravar nada
          }
        }
      }

      alterarPosto1(codigoPosto, dadosPosto);
O que acontece

Se responder n:

ATENÇÃO: este posto tem 1 carregamento(s) EM CURSO neste momento.
Passar para manutenção mesmo assim? (s/n): n
Operação cancelada. O posto não foi alterado.

Se responder s: grava normalmente.

E se o posto não tiver carregamentos em curso, nem pergunta nada — passa direto.
*/
