# data/ — os dados guardados

Aqui ficam os ficheiros `.json` com os dados da aplicacao.

Um ficheiro por entidade:

    postos.json          (Tarik)   <- ja existe, com exemplos
    clientes.json        (Tarik)
    tarifarios.json      (Fred)
    carregamentos.json   (Fred)

## Como criar os outros

Botao direito nesta pasta -> New File -> nome.json
E escrever `[]` (array vazio) ou ja com alguns registos de exemplo.

## Regras do JSON (apanham toda a gente)

1. Aspas **duplas** sempre, ate nas chaves:  `"codigo": "P001"`
2. **Sem virgula** no ultimo elemento
3. **Sem comentarios** — nao existem em JSON

Se o VSCode sublinhar a vermelho, ha um erro de sintaxe.

## Dica

Ter dados de exemplo com VARIEDADE (concelhos diferentes, estados
diferentes, potencias diferentes) ajuda a descobrir bugs que so
aparecem em certos casos.
