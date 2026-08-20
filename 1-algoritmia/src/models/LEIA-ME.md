# models/ — OPCIONAL (podem apagar esta pasta)

Pediste para explicar porque é que isto existe. Resposta honesta:
**não é necessário para o vosso trabalho.**

## O que seria um "model"

Uma pequena função-fábrica que constrói um objeto com a forma certa:

```
criarPosto(codigo, concelho, potenciaKw, tipoConector, estado)
   -> devolve { codigo, concelho, potenciaKw, tipoConector, estado }
```

Nada mais. Três ou quatro linhas por entidade.

## Para que serviria

1. **Garantir que todos os postos têm os mesmos campos.**
   Se criarem objetos à mão em sítios diferentes, é fácil um ficar
   sem o campo `estado` e depois ninguém perceber porque o filtro falha.

2. **Ter um sítio único com a "forma" de cada entidade.**
   Quem quiser saber que campos tem um Cliente, olha aqui.

3. **Valores por omissão.**
   Por exemplo, um posto novo começar sempre com `estado: "ativo"`
   sem ninguém ter de o escrever.

## Porque podem dispensar

- São 3-4 linhas por entidade — pouco ganho
- O objeto pode ser montado diretamente no menu, ao ler os campos
- **No projeto anterior estas funções existiam e NÃO eram chamadas
  por ninguém.** Código morto confunde quem lê (a formadora incluída).

## A decisão

**Opção A (recomendada):** apagar esta pasta. Montar os objetos
diretamente nos menus, ao recolher os campos com prompt.

**Opção B:** manter, mas então USAR mesmo — chamar `criarPosto(...)`
sempre que se cria um posto. Se ficar aqui sem ser usada, é pior
que não existir.

**Opção C:** pôr a função `criarPosto()` no topo do
`2-repositories/postoRepository.js`, junto ao CRUD dessa entidade.
Fica tudo do posto no mesmo sítio e desaparecem 4 ficheiros.

O pior cenário é deixar esta pasta com funções que ninguém chama.
Ou usam, ou apagam.
