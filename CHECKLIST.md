# Checklist do enunciado (Fase 1)

Marcar com [x] a medida que ficar feito **e testado**.

## CRUD — 30%
- [ ] Postos: listar / inserir / atualizar / remover        (Tarik)
- [ ] Clientes: listar / inserir / atualizar / remover      (Tarik)
- [ ] Tarifarios: listar / inserir / atualizar / remover    (Fred)
- [ ] Carregamentos: listar / inserir / atualizar / remover (Fred)

## Integridade referencial — 15%
- [ ] Nao remover POSTO com carregamentos associados      (Tarik)
- [ ] Nao remover CLIENTE com carregamentos associados    (Tarik)
- [ ] Nao remover TARIFARIO em uso                        (Fred)

## Organizacao, validacao e legibilidade — 15%
- [ ] Codigo separado em: menus / CRUD / relatorios
- [ ] Campos obrigatorios validados (nao aceitar vazios)
- [ ] Sem codigos/NIF repetidos
- [ ] Sem codigo morto (funcoes que ninguem chama)

## Relatorios — 20%
- [ ] 4.1 Carregamentos terminados/faturados, por posto e por cliente,
      com energia, custo e SOMATORIO final                (Fred)
- [ ] 4.2 Clientes: nome, idade, contacto, matricula,
      n.o de carregamentos e energia total                (Tarik)

## Dashboard — 10%
- [ ] Quantidade em curso e terminados
- [ ] Quantidade + energia media por POSTO (so estado "terminado")
- [ ] Quantidade + receita media por TARIFARIO (so estado "faturado")

## Requisito diferenciador — 10%
- [ ] Escolhido: ______________________
- [ ] Implementado

## Entregaveis
- [ ] Codigo .js pronto a correr
- [ ] README com: instrucoes de execucao, descricao do diferenciador,
      e divisao de tarefas pelo grupo
