# VoltGo 3.0 — esqueleto para construirmos nós

Este projeto **não tem código**. Só tem pastas, ficheiros vazios e **notas** a dizer
o que deve ser feito em cada sítio. O código escrevemo-lo nós.

## Ordem de trabalho

As pastas dentro de `src/` estão **numeradas pela ordem em que se constroem**:

```
1-cli/            os menus (é por aqui que se começa)
2-repositories/   guardar e ler os dados (CRUD)
3-services/       dashboard e relatorios (so no fim)
utils/            funcoes auxiliares (vai-se acrescentando)
models/           OPCIONAL - ver a nota la dentro
data/             os ficheiros .json com os dados
```

## Os 5 passos

**Passo 1 — `rascunho.js`**
Comecar aqui: UM ficheiro so, com tudo dentro (menu + dados + funcoes).
Sem imports, sem pastas, sem complicacao. So para perceber a logica.

**Passo 2 — menu a funcionar**
Menu principal que mostra as opcoes e responde. Ainda sem dados a serio.
Quando conseguires navegar entre menus, o esqueleto esta de pe.

**Passo 3 — UM repositorio completo (fatia vertical)**
Escolher UMA entidade (sugestao: Postos) e fazer o CRUD todo:
listar -> inserir -> atualizar -> remover. Testar entre cada um.

Quando isto funcionar, sabes o caminho todo. As outras entidades sao copia.

**Passo 4 — as outras entidades**
Repetir o passo 3 para Clientes (Tarik), Tarifarios e Carregamentos (Fred).

**Passo 5 — dashboard e relatorios**
So agora. Eles apenas LEEM dados que o CRUD ja criou.

## Divisao de tarefas

| Tarik | Fred |
|---|---|
| Postos | Tarifarios |
| Clientes | Carregamentos |
| Relatorio 4.2 (clientes) | Relatorio 4.1 (carregamentos) |

Dashboard e requisito diferenciador: em conjunto.

## Regra transversal

**Correr o programa a cada ~20 linhas escritas.** Se escreveres 200 de uma vez,
ficas com 10 erros misturados e nao sabes qual e qual.
