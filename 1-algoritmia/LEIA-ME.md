# Fase 1 — Algoritmia e Programacao

Aplicacao de consola em JavaScript / Node.js.

## Como vai correr

    node index.js

## Decisoes a fechar com o Fred (ANTES de escrever codigo)

- [ ] **Sincrono ou assincrono?**
      - Sincrono: `readFileSync` / `writeFileSync` -> sem async, sem await. Mais simples.
      - Assincrono: `fs/promises` -> obriga a `async`/`await` em cadeia.
      O enunciado nao exige nenhum. Escolham UM e usem os dois o mesmo.

- [ ] **Como se le o input?**
      - `readline-sync` (o que usamos nas aulas) -> `prompt("...")`, sem await
      - `readline/promises` -> `await rl.question("...")` + `rl.close()`

- [ ] **Nomes dos campos** de cada entidade, escritos e combinados.
      Se um escrever `energiaKwh` e o outro ler `energia`, da `undefined`
      e ninguem percebe porque.

- [ ] **Os 4 estados do carregamento**, escritos EXATAMENTE igual dos dois lados:
      `em curso` | `terminado` | `faturado` | `anulado`
      O dashboard e os relatorios filtram por estes valores.

## Estrutura

    index.js          porta de entrada (so chama o menu)
    rascunho.js       COMECAR AQUI - tudo num ficheiro so
    data/             os ficheiros .json
    src/1-cli/        menus
    src/2-repositories/  CRUD
    src/3-services/   dashboard e relatorios
    src/utils/        funcoes auxiliares
    src/models/       opcional (ver nota la dentro)
