# 3-services/ — dashboard e relatórios (PASSO 5)

## Deixar para o FIM

Esta camada só **lê** dados que o CRUD já criou.
Sem CRUD a funcionar, não há nada para relatar.

## O que é um "service"

É a camada que **pensa**: cálculos e regras de negócio.

- **não** guarda dados (isso é o repositório)
- **não** fala com o utilizador (isso é o menu)

```
menu  ->  service  ->  repositório  ->  ficheiro
        (calcula)     (vai buscar)
```

O service pede os dados ao repositório e faz as contas.

## Ficheiros

```
dashboardService.js    (em conjunto — dividir os indicadores)
relatorioService.js    (Tarik faz o 4.2, Fred faz o 4.1)
```

## Porquê "service" e não "calculos"?

Porque "cálculos" seria vago — os relatórios também fazem cálculos.
Um bom nome distingue esta coisa das outras coisas do projeto.

E "dashboard" é a palavra que a formadora usa no enunciado (secção 3).
Falar a língua de quem avalia é sempre boa ideia.
