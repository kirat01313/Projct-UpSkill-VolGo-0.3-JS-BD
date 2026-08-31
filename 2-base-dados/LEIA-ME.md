# Fase 2 — Base de Dados

SGBD: **Microsoft SQL Server** (Express, instancia local `.\SQLEXPRESS`).
Base de dados: **VoltGo**.

O enunciado da Fase 2 **nao exige ligar a aplicacao JavaScript a base de dados**.
E um trabalho de modelacao + SQL, entregue em PDF + scripts.

---

## Ficheiros e ordem de execucao

Correr sempre por esta ordem. Cada um depende do anterior.

| Ficheiro | O que faz | Entregavel |
|---|---|---|
| `01-criar-bd.sql` | Cria a base e as 15 tabelas, com todas as restricoes e indices | Parte B |
| `02-dados-teste.sql` | Insere os dados de teste | Parte B |
| `03-relatorios.sql` | Os 7 relatorios obrigatorios | Parte C |
| `04-relatorio-proposto.sql` | O relatorio estrategico proposto por nos | Parte D |
| `05-parte-e-proposta.sql` | Proposta de nova funcionalidade. **Nao faz parte do modelo entregue** — aplica, demonstra e reverte | Parte E |

**Porque nao ha um ficheiro por tabela:** uma FK nao pode apontar para uma
tabela que ainda nao existe, por isso a ordem de criacao e fixa. Espalhada
por 15 ficheiros, essa ordem ficava so no nome deles — e a ordem correta
entrelaca os dois autores, portanto nem por pessoa daria para separar.

---

## Documentos do modelo

Estao fora do repositorio, na pasta `UPSKILL/Base de Dados/`:

- `VoltGo-ModeloRelacional-v2.drawio` — o diagrama
- `VoltGo-DicionarioDados-v2.xlsx` — tipos, obrigatoriedade, restricoes
- `VoltGo-GuiaModelacao-v2.docx` — justificacao das decisoes

Os tres estao na versao **v2**, com as sete correcoes aplicadas.
Os originais (sem sufixo) sao a v1 e ficam como estao.

---

## Divisao de tarefas

| | Fred | Tarik |
|---|---|---|
| **Tabelas** | TipoConector, PostoConector, Tarifario, TarifarioPreco, Carregamento, CarregamentoHistorico, Pagamento | Concelho, Posto, Cliente, Veiculo, Reserva, TipoAvaria, Ocorrencia, OcorrenciaHistorico |
| **Relatorios** | 3, 5, 6 | 1, 2, 4, 7 |
| **Parte D** | Relatorio "por cobrar" | — |
| **Parte E** | — | Estimativa de tempo de carregamento |

Em conjunto: dados de teste e montagem do PDF final.

---

## Como correr

Pelo SSMS, abrindo cada ficheiro e executando (F5).

Ou pela linha de comandos:

```
sqlcmd -S .\SQLEXPRESS -E -C -f 65001 -i 01-criar-bd.sql
```

O `-C` e preciso porque o certificado da instancia local nao e de uma
autoridade fidedigna. O `-f 65001` e para os acentos nao virem partidos.

---

## Estado

- [x] Modelo relacional (diagrama + dicionario + guia)
- [x] `01` — catalogos: Concelho, TipoConector, TipoAvaria
- [x] `01` — as restantes 12 tabelas
- [x] `01` — indices unicos filtrados
- [x] `02` — dados de teste
- [x] `03` — os 7 relatorios
- [x] `04` — relatorio proposto
- [x] Parte E (proposta + demonstracao em `05`, revertivel)
- [ ] PDF final
