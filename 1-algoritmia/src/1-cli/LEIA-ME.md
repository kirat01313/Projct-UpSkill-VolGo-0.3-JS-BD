# 1-cli/ — os menus  (PASSOS 1 e 2)

Esta e a camada que FALA COM O UTILIZADOR.
So aqui se usa prompt e console.log.

## Regra de ouro

O menu NAO SABE onde os dados estao guardados.
Ele pede aos repositorios e mostra o que receber.

    menu  ->  pede ao repositorio  ->  mostra no ecra

Se te vires a abrir ficheiros aqui dentro, algo esta no sitio errado.

## Porque esta dividido em cli-tarik e cli-fred

O menu.js principal e o unico ficheiro onde os dois mexemos.
Para nao haver conflitos no git, cada um tem a sua pasta com os seus
submenus. O menu.js principal so os chama.

## Estrutura dos menus

    MENU PRINCIPAL
      1. Gerir Postos        -> cli-tarik/menuPostos.js
      2. Gerir Clientes      -> cli-tarik/menuClientes.js
      3. Gerir Tarifarios    -> cli-fred/menuTarifarios.js
      4. Gerir Carregamentos -> cli-fred/menuCarregamentos.js
      5. Relatorios          -> (PASSO 5)
      0. Sair

Cada submenu tem a MESMA forma:

      1. Inserir
      2. Listar
      3. Atualizar
      4. Remover
      0. Voltar

Quando fizeres um, os outros sao copia com nomes trocados.
