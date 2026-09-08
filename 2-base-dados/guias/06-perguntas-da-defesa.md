# Perguntas prováveis da defesa — e as respostas

> Uma pergunta, uma resposta curta. Se te lembrares só da primeira frase de cada uma, chega.

---

## Os números, para teres na cabeça

```
16 tabelas · 89 colunas · 19 ligacoes · 1 vista
12 procedures (CRUD em 3 tabelas)
 1 funcao escalar
 2 triggers
 7 scripts
```

---

## Sobre o modelo

**"Porque é que o Carregamento aponta para a tomada e não para o posto?"**
Porque a tomada já sabe a que posto pertence. Guardar os dois seria repetir informação, e a base podia acabar a dizer duas coisas diferentes sobre o mesmo carregamento.

**"Perderam alguma coisa com isso?"**
Sim, e está documentado. Deixámos de garantir por chave estrangeira que o carregamento acontece no posto reservado. Passa a ser uma verificação de aplicação em vez de uma regra estrutural.

**"Porque é que o PostoConector existe?"**
Porque um posto tem vários tipos de tomada e o mesmo tipo existe em vários postos. É uma relação muitos-para-muitos, e essas resolvem-se sempre com uma tabela no meio.

**"Porque é que a data de nascimento pode ser nula?"**
Porque as empresas não nascem. A restrição obriga os particulares a tê-la e proíbe as empresas de a ter. Não é "opcional", é "não se aplica".

**"Um concelho sem postos é um erro?"**
Não. A seta vai `Posto → Concelho`: o posto precisa de um concelho, o concelho não precisa de postos. Um concelho onde a rede ainda não chegou é um estado legítimo.

---

## Sobre a Fatura

**"Como funciona um pagamento parcial?"**
A fatura tem um valor. Os pagamentos vão-se somando. Enquanto a soma for menor, falta receber a diferença. Não há coluna "em dívida" — calcula-se.

**"Porque não guardam o valor total na fatura?"**
Porque é a soma dos carregamentos que ela cobre. Guardar seria arriscar que os dois números deixassem de bater certo.

**"Um carregamento pode ter vários pagamentos?"**
Já não. Foi essa a razão da entidade Fatura. Agora o pagamento abate numa **fatura**, e é a fatura que pode receber vários pagamentos.

---

## Sobre a redundância do preço

**"Não estão a repetir o preço em dois sítios?"**
Estamos, e de propósito. A `TarifarioPreco` é a fonte da verdade e mantém o histórico. As colunas no `Tarifario` são uma cópia mantida por um trigger, que torna impossível alterar uma e esquecer a outra.

**"E se alguém alterar diretamente o Tarifario?"**
Aí a cópia fica errada até à próxima alteração de preço. É o limite conhecido desta solução.

---

## Sobre SQL

**"Qual a diferença entre WHERE e HAVING?"**
`WHERE` filtra linhas antes de agrupar. `HAVING` filtra grupos depois de agrupar. Não se pode escrever `WHERE AVG(...) > 5` porque nessa altura a média ainda não existe.

**"Porque é que usaram COUNT(coluna) e não COUNT(*)?"**
Porque num LEFT JOIN o `COUNT(*)` conta a linha vazia e devolve 1 onde devia devolver 0. O `COUNT(coluna)` ignora os nulos.

**"Porque é que aquele filtro está no ON e não no WHERE?"**
Porque num LEFT JOIN um filtro sobre a tabela da direita no `WHERE` elimina as linhas sem correspondência — e transforma o LEFT JOIN num INNER JOIN disfarçado.

**"Qual a diferença entre uma procedure e uma função?"**
A procedure faz coisas e não se usa dentro de um SELECT. A função devolve um valor e usa-se dentro de um SELECT. A função não altera dados.

**"O que é o `inserted` num trigger?"**
Uma **tabela**, não uma linha. Um UPDATE que afete 50 linhas dispara o trigger uma vez, com 50 linhas lá dentro.

**"Para que serve a vista?"**
A lista dos postos em serviço é pedida constantemente e obriga sempre ao mesmo JOIN e ao mesmo filtro. A vista esconde isso atrás de um nome, e ninguém se pode esquecer do `Ativo = 1`.

**"A vista guarda dados?"**
Não. Guarda a pergunta, não a resposta. Se um posto for desativado amanhã, desaparece sozinho da lista.

---

## Sobre as simplificações

**"Porque é que as procedures de inserir não validam nada?"**
Porque a tabela já valida. O `UNIQUE` recusa duplicados. Validar outra vez punha a mesma regra em dois sítios.

**"Porque é que as três procedures são iguais?"**
Porque as três tabelas são iguais — id e nome. Repetir o mesmo molde mostra que o dominamos; inventar três casos diferentes acrescentava trabalho sem acrescentar ideia.

**"Não há nenhuma transação?"**
Não. Nenhuma operação escreve em duas tabelas ao mesmo tempo. A transação serve para quando há mais do que uma escrita a ter de acontecer junta.

**"Porque é que a Parte E não tem trigger?"**
Porque o enunciado pede a proposta — descrição, regras, impacto, alterações ao modelo — e não a automação. A Fase 1 também corria a pedido.

---

## Sobre a funcionalidade nova

**"Porque é uma tabela e não uma consulta?"**
Porque o alerta precisa de memória: quem o viu e o que decidiu. Uma consulta voltava a mostrar todos os dias a mesma anomalia já analisada.

**"Porque não usaram um CHECK?"**
Porque a energia está numa tabela e a potência está noutra. Um CHECK só vê colunas da própria linha.

**"Como sabem que funciona?"**
Pusemos dois carregamentos impossíveis nos dados de teste, que passam por todas as restrições existentes. A consulta apanha-os, e não apanha mais nenhum.

---

## Sobre o trabalho em si

**"Como garantem que o diagrama e os scripts não estão diferentes?"**
Não escrevemos o diagrama à mão. Ele e o dicionário são **gerados a partir do esquema real da base de dados**, depois de os scripts correrem.

**"Os dados de teste servem só para encher?"**
Não. Cada relatório tem lá um caso que só aparece se a consulta estiver certa: um concelho sem postos, dois tipos de conector nunca usados, um posto sem carregamentos, um cliente sem carregamentos, uma fatura por pagar mas ainda dentro do prazo.

**"Porque é que a demonstração está num ficheiro à parte?"**
Porque um script de criação não devia alterar dados. O `03` cria os objetos; o `07` mostra-os a funcionar.
