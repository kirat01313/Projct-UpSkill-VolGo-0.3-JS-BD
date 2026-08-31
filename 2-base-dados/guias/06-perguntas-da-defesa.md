# Perguntas prováveis da defesa — e as respostas

> Uma pergunta, uma resposta curta. Se te lembrares só da primeira frase de cada uma, chega.

---

## Sobre o modelo

**"Porque é que o Carregamento aponta para a tomada e não para o posto?"**
Porque a tomada já sabe a que posto pertence. Guardar os dois seria repetir informação, e a base de dados podia acabar a dizer duas coisas diferentes sobre o mesmo carregamento.

**"Perderam alguma coisa com isso?"**
Sim, e está documentado. Deixámos de poder garantir por chave estrangeira que o carregamento acontece no posto que foi reservado. Passa a ser uma verificação de aplicação em vez de uma regra estrutural.

**"Porque é que o PostoConector existe?"**
Porque um posto tem vários tipos de tomada e o mesmo tipo de tomada existe em vários postos. É uma relação muitos-para-muitos, e essas resolvem-se sempre com uma tabela no meio.

**"Porque é que nada se apaga?"**
Regra 3.8 do enunciado: remoção lógica. E há uma razão prática — apagar um tarifário deixaria os carregamentos antigos sem forma de explicar o preço que foi cobrado.

**"Porque é que a data de nascimento pode ser nula?"**
Porque as empresas não nascem. A restrição obriga a que os particulares a tenham e proíbe que as empresas a tenham. Não é "opcional", é "não se aplica".

---

## Sobre a Fatura

**"Como funciona um pagamento parcial?"**
A fatura tem um valor. Os pagamentos vão-se somando. Enquanto a soma for menor que o valor, falta receber a diferença. Não há coluna "em dívida" — calcula-se.

**"Porque não guardam o valor total na fatura?"**
Porque é a soma dos carregamentos que ela cobre. Guardar seria arriscar que os dois números deixassem de bater certo.

**"Um carregamento pode ter vários pagamentos?"**
Já não. Foi essa a razão da entidade Fatura. Agora o pagamento abate numa **fatura**, e é a fatura que pode receber vários pagamentos.

---

## Sobre a redundância do preço

**"Não estão a repetir o preço em dois sítios?"**
Estamos, e de propósito. A `TarifarioPreco` é a fonte da verdade e mantém o histórico. As colunas no `Tarifario` são uma cópia mantida por um trigger, que torna impossível alterar uma e esquecer a outra.

**"E se alguém alterar diretamente o Tarifario?"**
Aí a cópia fica errada até à próxima alteração de preço. É o limite conhecido desta solução, e a razão pela qual as alterações de preço devem passar pela procedure `usp_Tarifario_Atualizar`.

---

## Sobre SQL

**"Qual a diferença entre WHERE e HAVING?"**
`WHERE` filtra linhas antes de agrupar. `HAVING` filtra grupos depois de agrupar. Não se pode escrever `WHERE AVG(...) > 5` porque nessa altura a média ainda não existe.

**"Porque é que usaram COUNT(coluna) e não COUNT(*)?"**
Porque num LEFT JOIN, `COUNT(*)` conta a linha vazia e devolve 1 onde devia devolver 0. `COUNT(coluna)` ignora os nulos.

**"Porque é que aquele filtro está no ON e não no WHERE?"**
Porque num LEFT JOIN, um filtro sobre a tabela da direita no `WHERE` elimina as linhas sem correspondência — e transforma o LEFT JOIN num INNER JOIN disfarçado.

**"Qual a diferença entre uma procedure e uma função?"**
A procedure faz coisas e não se pode usar dentro de um SELECT. A função devolve um valor e usa-se dentro de um SELECT. A função não pode alterar dados.

**"O que é o `inserted` num trigger?"**
É uma **tabela**, não uma linha. Tem as linhas como ficaram depois da operação. Por isso os triggers têm de ser escritos em conjunto: um UPDATE que afeta 50 linhas dispara o trigger uma vez, com 50 linhas lá dentro.

---

## Sobre a funcionalidade nova

**"Porque é que o alerta não bloqueia o carregamento?"**
Porque a energia foi mesmo entregue a alguém. Recusar o registo faria a sessão desaparecer, e o problema ficava invisível. Trigger que bloqueia serve para o que está sempre errado; este regista o que é apenas estranho.

**"Porque é uma tabela e não uma consulta?"**
Porque o alerta precisa de memória: quem o viu e o que decidiu. Uma consulta voltava a mostrar todos os dias a mesma anomalia já analisada.

**"Porque não usaram um CHECK?"**
Porque a energia está numa tabela e a potência está noutra. Um CHECK só vê colunas da própria linha. Esta regra cruza duas tabelas — só um trigger a alcança.

**"Como sabem que funciona?"**
Pusemos dois carregamentos impossíveis nos dados de teste, que passam por todas as restrições existentes. O varrimento inicial apanhou-os. Depois inserimos um carregamento impossível novo — foi apanhado — e um plausível — não gerou alerta nenhum.

---

## Sobre o trabalho em si

**"Como é que garantem que o diagrama e os scripts não estão diferentes?"**
Não escrevemos o diagrama à mão. Ele e o dicionário são **gerados a partir do esquema real da base de dados**, depois de os scripts terem corrido. Não podem divergir porque saem da mesma fonte.

**"Os dados de teste servem só para encher?"**
Não. Cada relatório tem lá um caso que só aparece se a consulta estiver certa: um concelho sem postos, um tipo de conector nunca usado, um posto sem carregamentos, uma fatura por pagar mas ainda dentro do prazo.
