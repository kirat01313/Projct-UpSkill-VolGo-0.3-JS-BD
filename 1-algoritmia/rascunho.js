/*



ponto1: ao inserir codigo de posto ja indicar se ja existe ou nao, e se nao existir, nao permitir inserir o carregamento
ponto2: ao inserir nome de tarifario ja indicar se ja existe ou nao, e se nao existir, nao permitir inserir o carregamento

ponto3: ao inserir carregamento fazer ja o calculo dos KWH e custo, pois esta sendo inserido manualmente,
 e nao esta sendo feito o calculo automatico,
 e o custo deve ser calculado com base no tarifario escolhido,
 e o KWH deve ser calculado com base na potencia do posto e no tempo de carregamento


ponto diferencial estimativa de tempo com base na bateria do carro % da bateria atual para estimativa de 100%

 outro diferencial seria user a energia kwh com um teto maximo tento por abse a potencia do posto e o 
 tempo de carregamento, e se passar do teto maximo, nao permitir inserir o carregamento

O menor kwh define a velocidade de carregamento, e o tempo de carregamento
 é calculado com base na potencia do posto e no kwh do carro

 

 correções:

 Cliente com carregamento sendo excluido

Impedir um carregamento em curso de ser removido 
*/