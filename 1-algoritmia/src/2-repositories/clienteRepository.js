import path from 'node:path'; //biblioteca do proprio node para definir caminhos de ficheiros
import { readFileSync, writeFileSync, existsSync } from 'node:fs'; //ler ficheiro, escrever ficheiro, verificar se existe ficheiro

const caminhoCliente = path.join(import.meta.dirname, '../../data/clientes.json'); //define o endereço do ficheiro e o nome do ficheiro em uma constante

//======================================================
//  LER  (listar / procurar)
//======================================================

export function listarClientes() {
    if (!existsSync(caminhoCliente))                        //verifica se existe ficheiro naquele endereço/nome que indicamos
        return [];                                           // se não existir retorna um array vazio e já sai da função, a linha a seguir nem chega a rodar
    const conteudo = readFileSync(caminhoCliente, 'utf-8'); //Caso exista já o ficheiro ele lê o conteudo 'utf-8' converte os dados para string
    if (conteudo.trim() === "")                            //se existir um ficheiro mas estiver vazio, faz o mesmo que antes,
        return [];                                           //retorna um array vazio e já sai da função, a linha a seguir nem chega a rodar
    return JSON.parse(conteudo);                           //Caso tenha algo, reconverte o texto para um array e retorna esse array
}

export function procurarCliente1(nif) { //Função que procura um cliente pelo nif, devolvendo o objeto do cliente se encontrado, ou null se não encontrado
    const clientes = listarClientes();
    for (let i = 0; i < clientes.length; i++) {
        if (clientes[i].nif === nif) return clientes[i];
    }
    return null;
}

//======================================================
//  ESCREVER  (inserir / alterar / excluir)
//======================================================

export function inserirCliente1(cliente) {
    if (procurarCliente1(cliente.nif) !== null) return null;   //se já existir um cliente com o mesmo nif, devolve null
    const clientes = listarClientes(); //chama a função listarClientes() para pegar o array de clientes já existentes
    clientes.push(cliente); //acrescenta o novo cliente ao array de clientes
    gravarClientes(clientes); //chama a função gravarClientes() para gravar o array atualizado no ficheiro
    return cliente; //devolve o cliente             inserido
}

export function alterarCliente1(nif, dadosNovos) {
    const clientes = listarClientes(); //chama a função listarClientes() para pegar o array de clientes já existentes
    let clienteIndex = -1;
    for (let i = 0; i < clientes.length; i++) { //percorre o array de clientes para encontrar o cliente com o código fornecido
        if (clientes[i].nif === nif) { //se encontrar, guarda o índice do cliente no array
            clienteIndex = i; //guarda o índice do cliente no array
            break;
        }
    }
    if (clienteIndex === -1) {//se não encontrar, devolve null (essa parte parece duplicada com a parte do menuPostos.js)
        return null;
    } else { //se encontrar, atualiza os campos do cliente com os dados novos fornecidos mas não altera o nif (que é a chave)
        clientes[clienteIndex].nome = dadosNovos.nome;
        clientes[clienteIndex].dataNascimento = dadosNovos.dataNascimento;
        clientes[clienteIndex].contactoTelefone = dadosNovos.contactoTelefone;
        clientes[clienteIndex].contactoEmail = dadosNovos.contactoEmail;
        clientes[clienteIndex].matricula = dadosNovos.matricula;
        gravarClientes(clientes); //chama a função gravarClientes() para gravar o array atualizado no ficheiro
        return clientes[clienteIndex]; //devolve o cliente atualizado
    }
}

export function excluirCliente1(nif) { //Função que exclui um cliente pelo nif, devolvendo true se excluiu, ou false se não encontrou o cliente

    const carregamentos = listarCarregamentos();
    for (let i = 0; i < carregamentos.length; i++) {
        if (carregamentos[i].cliente === nif) return false;
    }

    const clientes = listarClientes(); //chama a função listarClientes() para pegar o array de clientes já existentes
    const restantes = []; //cria um array vazio para guardar os clientes que não serão excluídos
    for (let i = 0; i < clientes.length; i++) {
        if (clientes[i].nif !== nif) {     //se o nif do cliente atual não for igual ao nif fornecido, adiciona o cliente ao array de restantes
            restantes.push(clientes[i]);
        }
    }
    if (restantes.length === clientes.length) return false;   //se o array de restantes tiver o mesmo tamanho que o array original, significa que não encontrou o cliente com o nif fornecido, então devolve false
    gravarClientes(restantes); //chama a função gravarClientes() para gravar o array de restantes no ficheiro, sobrescrevendo o array original
    return true; //devolve true, indicando que o cliente foi excluído com sucesso
}

//======================================================
//  AUXILIAR PRIVADA  (gravação no ficheiro)
//======================================================

function gravarClientes(clientes) { //Função que grava/regrava o array de clientes no ficheiro
    writeFileSync(caminhoCliente, JSON.stringify(clientes, null, 2), 'utf-8'); //writeFileSync() cria o ficheiro se não existir, ou sobrescreve se já existir. JSON.stringify() converte
    //o array de clientes em string, com indentação de 2 espaços para melhor leitura
}
