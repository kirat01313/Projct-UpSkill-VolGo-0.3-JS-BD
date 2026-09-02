import path from 'node:path'; //biblioteca do proprio node para definir caminhos de ficheiros
import { readFileSync, writeFileSync, existsSync } from 'node:fs'; //ler ficheiro, escrever ficheiro, verificar se existe ficheiro

const caminhoPostos = path.join(import.meta.dirname, 'data/postos.json'); //define o endereço do ficheiro e o nome do ficheiro em uma constante



 
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


