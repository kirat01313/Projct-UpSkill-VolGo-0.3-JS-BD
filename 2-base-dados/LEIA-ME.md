# Fase 2 — Base de Dados (VoltGo)

Sistema de informação para uma rede de postos de carregamento de veículos elétricos.
Continua a aplicação de consola da Fase 1.

**Base de dados:** SQL Server Express · instância `localhost\SQLEXPRESS` · base `VoltGo`
**Estado:** os seis scripts foram executados e testados. Diagrama e dicionário gerados a partir do esquema real.

---

## O que está aqui

```
2-base-dados/
│
├── LEIA-ME.md                    <-- estás aqui
│
├── guias/                        material de estudo, para ler antes de defender
│   ├── 00-as-quatro-alteracoes.md      o que mudou depois da conversa com a professora
│   ├── 01-parte-B-procedures-funcoes-triggers.md
│   ├── 02-parte-C-relatorios.md
│   ├── 03-parte-D-relatorio-proposto.md
│   ├── 04-parte-E-alerta.md
│   └── 05-perguntas-da-defesa.md       perguntas prováveis e respostas curtas
│
└── Entregaveis Finais/           o que se entrega
    ├── VoltGo-ModeloRelacional.drawio
    ├── VoltGo-ModeloRelacional.png
    ├── VoltGo-DicionarioDados.xlsx
    ├── 01-criar-bd.sql
    ├── 02-dados-teste.sql
    ├── 03-procedures-funcoes-triggers.sql
    ├── 04-relatorios.sql
    ├── 05-relatorio-proposto.sql
    └── 06-parte-e-alerta.sql
```

---

## Por onde começar a estudar

1. **`guias/00-as-quatro-alteracoes.md`** — o que mudou e porquê. É o contexto de tudo o resto.
2. O guia da parte que te calhou (B, C, D ou E).
3. **`guias/05-perguntas-da-defesa.md`** — na véspera.

Os ficheiros `.sql` estão comentados de cima a baixo. Os comentários explicam **porquê**, não só o quê.

---

## Como correr os scripts

Sempre **por esta ordem**. Cada um assume que os anteriores já correram.

```
01-criar-bd.sql                    cria a base e as 17 tabelas
02-dados-teste.sql                 enche com dados de teste
03-procedures-funcoes-triggers.sql PARTE B
04-relatorios.sql                  PARTE C — os 7 obrigatórios
05-relatorio-proposto.sql          PARTE D
06-parte-e-alerta.sql              PARTE E — a funcionalidade nova
```

### No VSCode

1. Extensão **SQL Server (mssql)** instalada.
2. `Ctrl+Shift+P` → **MS SQL: Connect** → servidor `localhost\SQLEXPRESS`, autenticação Windows.
3. Abrir o ficheiro e `Ctrl+Shift+E` para executar tudo.

> Se aparecer um erro a dizer que a base está a ser usada, fecha os outros separadores ligados à `VoltGo` antes de correr o `01`.

### Pelo terminal

```bash
sqlcmd -S "localhost\SQLEXPRESS" -E -C -i "01-criar-bd.sql"
```

---

## O que o enunciado pede, e onde está

| Ponto do enunciado | Onde |
|---|---|
| Modelo relacional | `VoltGo-ModeloRelacional.drawio` / `.png` |
| Dicionário de dados | `VoltGo-DicionarioDados.xlsx` |
| Script de criação | `01-criar-bd.sql` |
| Dados de teste | `02-dados-teste.sql` |
| **B** — procedures, funções, triggers | `03-...sql` + `guias/01-...md` |
| **C** — 7 relatórios obrigatórios | `04-...sql` + `guias/02-...md` |
| **D** — relatório estratégico proposto | `05-...sql` + `guias/03-...md` |
| **E** — funcionalidade nova | `06-...sql` + `guias/04-...md` |

---

## Números do modelo

```
17 tabelas · 99 colunas · 20 ligações
3 triggers de negócio + 1 trigger de deteção
4 stored procedures (CRUD sobre o Tarifário)
2 funções (uma escalar, uma tabular)
```

---

## Divisão do trabalho

| | Fred | Tarik |
|---|---|---|
| Relatórios obrigatórios | 3, 5, 6 | 1, 2, 4, 7 |

---

## Nota importante sobre o diagrama

O diagrama e o dicionário **não são escritos à mão**. São gerados a partir do esquema real da base de dados, depois de os scripts terem corrido, e verificados um contra o outro.

Por isso é impossível que digam coisas diferentes dos scripts. Se alterares um script, é preciso regenerá-los — não os edites à mão.
