export function iniciarMenu() {
  console.log('Bem-vindo ao VoltGo — sempre a carregar!\n');
  menuPrincipal();
}

/*
  MENU PRINCIPAL  —  PASSO 2
  ==========================

  O QUE VAI AQUI:
    - a lista de opcoes
    - ler a escolha do utilizador
    - chamar o submenu correspondente
    - repetir ate a opcao ser "0"
    - (PASSO 5) o dashboard no topo — deixar comentado ate la

  O QUE NAO VAI AQUI:
    - a logica de cada submenu (isso vai para cli-tarik/ e cli-fred/)
    - leitura de ficheiros

  ------------------------------------------------------------
  AS OPCOES A MOSTRAR:
  ------------------------------------------------------------
     1. Gerir Postos
     2. Gerir Clientes
     3. Gerir Tarifarios
     4. Gerir Carregamentos
     5. Relatorios
     0. Sair

  ------------------------------------------------------------
  A REPETICAO:
  ------------------------------------------------------------
  O menu tem de voltar a aparecer depois de cada operacao.
  Sugestao: um ciclo while que repete enquanto a opcao nao for "0".

  (Ha quem faca isto com recursao — a funcao chamar-se a si propria.
   Funciona, mas o while e mais simples e e materia da aula 3.)

  ------------------------------------------------------------
  LIGAR OS SUBMENUS (ir acrescentando a medida que existirem):
  ------------------------------------------------------------
  Quando o menuPostos.js estiver feito, acrescentar aqui o import
  e chama-lo na opcao 1.

  Enquanto um submenu nao existir, deixar um console.log a dizer
  "ainda nao implementado". Assim o menu funciona na mesma e
  consegues navegar desde o inicio.

  ------------------------------------------------------------
  NAO ESQUECER:
  ------------------------------------------------------------
  - opcao invalida tem de dar mensagem, nao pode ficar em silencio
  - o input vem sempre como TEXTO: comparar com "1", nao com 1
*/
