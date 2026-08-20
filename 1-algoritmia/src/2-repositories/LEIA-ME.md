# 2-repositories/ — guardar e ler os dados (PASSOS 3 e 4)

## O que é um "repositório"

ATENÇÃO: nada a ver com "repositório do GitHub". Aqui é outra coisa.

Um repositório é simplesmente **o ficheiro de uma entidade**.
Tem duas coisas lá dentro:

1. onde os dados vivem (o caminho do `.json`)
2. as 4 funções do CRUD

```
listar     -> devolve todos
inserir    -> acrescenta um
atualizar  -> encontra e altera um
remover    -> tira um
```

## Regra de ouro

O repositório **não fala com o utilizador**.

- nada de `console.log` aqui dentro
- nada de `prompt` aqui dentro

Ele **devolve** valores; quem os mostra é o menu.

## O que cada função deve devolver

Convenção simples e consistente:

```
listar     ->  o array (vazio se não houver nada)
inserir    ->  o objeto inserido, ou null se foi recusado
atualizar  ->  o objeto atualizado, ou null se não existe
remover    ->  true se removeu, false se não
```

É o menu que verifica esse retorno e mostra a mensagem certa.
Sem isto, o menu diz "inserido!" mesmo quando não inseriu nada.

## Divisão

```
postoRepository.js         (Tarik)  <- PASSO 3, começar por este
clienteRepository.js       (Tarik)  <- PASSO 4
tarifarioRepository.js     (Fred)
carregamentoRepository.js  (Fred)
```

## Nota sobre repetição

As 4 funções vão ficar muito parecidas nos 4 ficheiros.
**Não tentar generalizar isso já.**

Escrever primeiro, sentir a repetição, e só depois (se valer a pena)
extrair o que for comum para `utils/`.

Escrever a abstração antes de sentir o problema só complica.
