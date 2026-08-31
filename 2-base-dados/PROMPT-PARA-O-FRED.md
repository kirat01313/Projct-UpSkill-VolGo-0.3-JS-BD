# Prompt para o Claude Code do Fred

> **Como usar:** copia tudo o que está dentro do bloco abaixo (da linha "Contexto" até ao fim) e cola no Claude Code do Fred, na pasta onde ele tiver os ficheiros da VoltGo.
> Antes disso, o Fred precisa da pasta `2-base-dados` inteira (guias + Entregaveis Finais).

---

## Contexto

Estou a trabalhar no projeto **VoltGo**, o trabalho prático de Bases de Dados do IPCA/UpSkill (docente: Marta Martinho). Somos dois: eu (Fred) e o Tarik. É a Fase 2 de um trabalho que começou com uma aplicação de consola em JavaScript.

O tema é um sistema de informação para uma **rede de postos de carregamento de veículos elétricos**: postos, tomadas, clientes, veículos, reservas, carregamentos, faturas, pagamentos, manutenção e tarifários.

O trabalho de modelação e os scripts **já estão feitos e testados**. O que preciso de ti agora é ajuda a **perceber**, **estudar** e **defender** o que está feito — não a refazer.

## Onde está tudo

Na pasta `2-base-dados`:

```
guias/                                 material de estudo em português
  00-as-quatro-alteracoes.md           o que mudou depois da conversa com a professora
  01-parte-B-procedures-funcoes-triggers.md
  02-parte-C-relatorios.md
  03-parte-D-relatorio-proposto.md
  04-parte-E-alerta.md
  05-perguntas-da-defesa.md

Entregaveis Finais/                    o que se entrega
  VoltGo-ModeloRelacional.drawio       diagrama final
  VoltGo-ModeloRelacional.png
  VoltGo-DicionarioDados.xlsx          dicionário final (6 folhas)
  01-criar-bd.sql                      17 tabelas
  02-dados-teste.sql                   dados de teste
  03-procedures-funcoes-triggers.sql   PARTE B
  04-relatorios.sql                    PARTE C — os 7 relatórios obrigatórios
  05-relatorio-proposto.sql            PARTE D
  06-parte-e-alerta.sql                PARTE E — funcionalidade nova
```

**Lê primeiro `guias/00-as-quatro-alteracoes.md` e depois `Entregaveis Finais/01-criar-bd.sql`.** Os scripts estão todos comentados a explicar o *porquê* de cada decisão, não só o *quê*.

## Estado atual

- Base de dados: **SQL Server Express**, instância `localhost\SQLEXPRESS`, base `VoltGo`.
- **17 tabelas, 99 colunas, 20 ligações.**
- Os seis scripts foram executados e testados com sucesso, por esta ordem: 01 → 02 → 03 → 04 → 05 → 06.
- O diagrama e o dicionário **não foram escritos à mão**: foram gerados a partir do esquema real da base de dados depois de os scripts correrem, e verificados um contra o outro. Por isso não podem divergir dos scripts.

## As quatro alterações que a professora pediu (todas já feitas)

1. **Nova entidade `Fatura`.** Agrupa vários carregamentos num documento. O `Pagamento` deixou de apontar ao carregamento e passou a apontar à fatura, o que permite pagamentos **parciais**. O `Carregamento` ganhou `IDFatura` (NULL enquanto não faturado), com uma restrição que impede o estado 'Faturado' sem fatura.

2. **Retirar o `IDPosto` do `Carregamento`.** Era redundante: a tomada (`PostoConector`) já sabe a que posto pertence. Todas as consultas passaram a fazer o caminho `Carregamento → PostoConector → Posto`. Perde-se a garantia por chave de que o carregamento acontece no posto reservado — limitação assumida e documentada no diagrama.

3. **Preço e taxa de ativação também na tabela `Tarifario`** (`PrecoKwhAtual`, `TaxaAtivacaoAtual`), mantendo a `TarifarioPreco` como histórico e fonte da verdade. Um trigger (`TR_TarifarioPreco_SincronizaAtual`) copia automaticamente o preço em vigor, para não ser possível alterar um e esquecer o outro.

4. **Nova funcionalidade `Alerta`.** Regista automaticamente carregamentos que declararam mais energia do que o posto conseguiria ter entregue no tempo da sessão (com margem de 10%). Não bloqueia o registo — regista e deixa um humano classificar como Justificado ou Confirmado. Evolui a função de auditoria da Fase 1.

## Divisão do trabalho

Relatórios obrigatórios da Parte C: **Fred → 3, 5, 6** · **Tarik → 1, 2, 4, 7**.

## Como quero que trabalhes comigo

- **Respostas curtas.** Blocos bem definidos, um assunto de cada vez, sem dar voltas.
- **Explica os conceitos como se eu estivesse a aprender bases de dados do zero.** Exemplos concretos e desenhados valem mais do que definições.
- **Não me mostres código a menos que eu peça.** Prefiro perceber a lógica primeiro.
- **Não alteres ficheiros sem eu pedir.** Se achares que algo está errado, diz-me e explica porquê.
- **Não instales nem configures nada na minha máquina sem perguntar.** Se for preciso, dá-me o passo a passo para eu fazer.

## O que preciso agora

Começa por ler a pasta e fazer-me um resumo do modelo em português simples: que tabelas existem, como se ligam, e onde é que os meus três relatórios (3, 5 e 6) vão buscar a informação.
