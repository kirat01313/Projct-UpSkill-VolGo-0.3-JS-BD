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
├── LEIA-ME.md                    <-- estás aqui        }
├── PROMPT-PARA-O-FRED.md                               }  VOSSO
├── guias/                        material de estudo    }  nunca sai daqui
│   ├── 00-comeca-aqui.md               o modelo do zero, sem assumir nada
│   ├── 01-as-quatro-alteracoes.md      o que mudou depois da conversa com a professora
│   ├── 02-procedures-funcoes-triggers.md   pedido oral da docente, fora do PDF
│   ├── 03-parte-C-relatorios.md
│   ├── 04-parte-D-relatorio-proposto.md
│   ├── 05-parte-E-alerta.md
│   └── 06-perguntas-da-defesa.md       perguntas prováveis e respostas curtas
│
└── Entregaveis Finais/           PARA A PROFESSORA
    ├── VoltGo-Relatorio.docx           abrir no Word e exportar para PDF
    ├── VoltGo-ModeloRelacional.drawio
    ├── VoltGo-ModeloRelacional.png
    ├── VoltGo-DicionarioDados.xlsx
    └── scripts/
        ├── 01-criar-bd.sql
        ├── 02-dados-teste.sql
        ├── 03-procedures-funcoes-triggers.sql
        ├── 04-relatorios.sql
        ├── 05-relatorio-proposto.sql
        ├── 06-parte-e-alerta.sql
        └── 07-demonstracao.sql
```

> **Antes de entregar:** abrir o `.docx` no Word, clicar com o botão direito no índice
> e escolher «Atualizar campo» para ele se preencher. Depois exportar para PDF.

---

## Por onde começar a estudar

1. **`guias/00-comeca-aqui.md`** — o modelo explicado do zero. Se nunca leste nada disto, começa por aqui.
2. **`guias/01-as-quatro-alteracoes.md`** — o que mudou depois da conversa com a professora.
3. O guia da parte que te calhou (C, D ou E).
4. **`guias/06-perguntas-da-defesa.md`** — na véspera.

Os ficheiros `.sql` estão comentados de cima a baixo. Os comentários explicam **porquê**, não só o quê.

---

## Como correr os scripts

Sempre **por esta ordem**. Cada um assume que os anteriores já correram.

```
01-criar-bd.sql                    cria a base, 16 tabelas e 1 vista
02-dados-teste.sql                 enche com dados de teste
03-procedures-funcoes-triggers.sql 12 procedures, 1 funcao, 2 triggers
04-relatorios.sql                  PARTE C — os 7 obrigatorios
05-relatorio-proposto.sql          PARTE D
06-parte-e-alerta.sql              PARTE E — a funcionalidade nova
07-demonstracao.sql                mostra os objetos a funcionar (opcional)
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
| Dicionário de dados | `VoltGo-DicionarioDados.xlsx` |
| **A** — modelo relacional | `VoltGo-ModeloRelacional.drawio` / `.png` + `guias/00-...md` |
| **B** — implementação SQL | `01-criar-bd.sql` e `02-dados-teste.sql` |
| **C** — 7 relatórios obrigatórios | `04-...sql` + `guias/03-...md` |
| **D** — relatório estratégico proposto | `05-...sql` + `guias/04-...md` |
| **E** — funcionalidade nova | `06-...sql` + `guias/05-...md` |

O enunciado escrito **não pede** procedures, funções nem triggers. O
`03-procedures-funcoes-triggers.sql` responde a um pedido feito **oralmente**
pela docente: CRUD com stored procedures em três tabelas, uma função de
estatística e um trigger com lógica automática.

---

## Números do modelo

```
16 tabelas · 89 colunas · 19 ligações · 1 vista
12 stored procedures (CRUD em 3 tabelas: TipoConector, Concelho, TipoAvaria)
 1 função escalar
 2 triggers
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
