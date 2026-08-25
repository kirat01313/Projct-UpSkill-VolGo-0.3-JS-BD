/*
  PORTA DE ENTRADA DA APLICACAO
  =============================

  Este ficheiro deve ser MUITO pequeno — 2 ou 3 linhas.
  A unica coisa que faz e chamar o menu principal.

  O QUE VAI AQUI:
    - import do menu principal (src/1-cli/menu.js)
    - a chamada que arranca a aplicacao

  O QUE NAO VAI AQUI:
    - logica nenhuma
    - console.log de menus
    - leitura de dados

  Corre-se com:  node index.js
*/

import { iniciarMenu } from './src/1-cli/menu.js';

iniciarMenu();
