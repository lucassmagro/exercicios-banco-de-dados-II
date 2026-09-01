-- ============================================================
-- Aula 3 - Revisao SQL: Subconsultas aninhadas e EXISTS
-- Pre-requisitos: rodar exercicios/aula1/01_schema.sql e
-- exercicios/aula1/02_dados.sql antes deste arquivo.
--
-- OBS de datas: os slides originais desta aula usam 12/10/2017 como
-- data de exemplo, mas o nosso conjunto de dados (bdHotel.txt) usa
-- o ano de 2019. As consultas abaixo foram adaptadas para
-- '2019-10-12', que e a data em que realmente existe consumo
-- registrado nos dados carregados.
-- ============================================================

-- 1) Apresentar para todos os hospedes, os nomes e numero de dias
--    hospedado.
-- COALESCE troca um valor nulo pelo valor informado: se o hospede
-- ainda nao fez check-out (datasai NULL), consideramos a estadia
-- em andamento ate hoje (CURRENT_DATE).
SELECT
    c.nome,
    COALESCE(h.datasai, CURRENT_DATE) - h.dataent AS dias_hospedado
FROM hospedes h
JOIN clientes c ON c.cpf = h.cpf;


-- 2) Apresentar para todos os hospedes, os nomes e numero de dias
--    hospedados e o preco gasto apenas com diarias.
-- "preco gasto com diarias" = numero de dias hospedado * preco do
-- tipo de quarto ocupado (join ate tiposquartos, via quartos).
SELECT
    c.nome,
    COALESCE(h.datasai, CURRENT_DATE) - h.dataent AS dias_hospedado,
    (COALESCE(h.datasai, CURRENT_DATE) - h.dataent) * t.preco AS gasto_diarias
FROM hospedes h
JOIN clientes c      ON c.cpf = h.cpf
JOIN quartos q        ON q.numero = h.quarto
JOIN tiposquartos t   ON t.codigo = q.tipo;


-- 3) Buscar a descricao dos itens mais e menos pedidos do cardapio.
-- Primeiro contamos quantas vezes cada item foi pedido (subconsulta
-- no FROM); depois comparamos essa contagem com o MAX/MIN dela
-- mesma para achar os extremos.
SELECT descricao, total_pedidos
FROM (
    SELECT ca.descricao, COUNT(co.id) AS total_pedidos
    FROM cardapios ca
    LEFT JOIN consumo co ON co.itemcardapio = ca.codigo
    GROUP BY ca.codigo, ca.descricao
) resumo
WHERE total_pedidos = (SELECT MAX(total_pedidos) FROM (
        SELECT COUNT(co.id) AS total_pedidos
        FROM cardapios ca
        LEFT JOIN consumo co ON co.itemcardapio = ca.codigo
        GROUP BY ca.codigo
     ) x)
   OR total_pedidos = (SELECT MIN(total_pedidos) FROM (
        SELECT COUNT(co.id) AS total_pedidos
        FROM cardapios ca
        LEFT JOIN consumo co ON co.itemcardapio = ca.codigo
        GROUP BY ca.codigo
     ) y);


-- 4) Buscar o preco minimo e o preco maximo dos itens consumidos no
--    dia 12/10/2019.
-- MIN/MAX sobre o preco do cardapio, filtrando apenas os itens que
-- de fato aparecem em consumo naquela data (join consumo -> cardapios).
SELECT
    MIN(ca.preco) AS preco_minimo,
    MAX(ca.preco) AS preco_maximo
FROM consumo co
JOIN cardapios ca ON ca.codigo = co.itemcardapio
WHERE co.data = '2019-10-12';


-- 5) Buscar o CPF, nome, placa do veiculo de cada hospede, assim
--    como o numero e tipo (descricao) do quarto em que esta
--    hospedado e a data prevista de saida.
-- (mesma consulta da Aula 2, exercicio 7 - revisao.)
SELECT
    h.cpf,
    c.nome,
    h.placaveiculo,
    q.numero    AS numero_quarto,
    t.descricao AS tipo_quarto,
    h.datasai   AS data_prevista_saida
FROM hospedes h
JOIN clientes c     ON c.cpf = h.cpf
JOIN quartos q       ON q.numero = h.quarto
JOIN tiposquartos t  ON t.codigo = q.tipo;


-- 6) Buscar o numero dos quartos onde houve consumo de almoco e
--    janta em 12/10/2019.
-- (mesma consulta da Aula 2, exercicio 8 - revisao.)
SELECT h.quarto
FROM hospedes h
JOIN consumo co   ON co.hospede = h.cpf
JOIN cardapios ca ON ca.codigo = co.itemcardapio
WHERE co.data = '2019-10-12'
  AND ca.descricao IN ('almoco', 'janta')
GROUP BY h.quarto
HAVING COUNT(DISTINCT ca.descricao) = 2;


-- 7) Buscar a descricao dos itens do cardapio que nunca foram
--    pedidos.
-- NOT EXISTS: para cada item do cardapio, verifica se NAO existe
-- nenhuma linha de consumo apontando para ele.
SELECT ca.descricao
FROM cardapios ca
WHERE NOT EXISTS (
    SELECT 1 FROM consumo co
    WHERE co.itemcardapio = ca.codigo
);


-- 8) Utilizando EXISTS, liste o CPF, nome e o fone dos clientes que
--    estavam hospedados no dia 12/10/2019.
-- "estava hospedado" = a data cai dentro do periodo [dataent, datasai]
-- (ou a estadia ainda esta em aberto, datasai IS NULL, e ja comecou).
SELECT c.cpf, c.nome, c.fone
FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM hospedes h
    WHERE h.cpf = c.cpf
      AND h.dataent <= '2019-10-12'
      AND (h.datasai IS NULL OR h.datasai >= '2019-10-12')
);


-- 9) Buscar o codigo e a descricao dos itens do cardapio consumidos
--    por todos os hospedes do hotel.
-- Divisao relacional classica com dupla negacao:
--   "nao existe hospede que NAO consumiu este item"
-- e equivalente a "todo hospede consumiu este item".
SELECT ca.codigo, ca.descricao
FROM cardapios ca
WHERE NOT EXISTS (
    SELECT 1 FROM hospedes h
    WHERE NOT EXISTS (
        SELECT 1 FROM consumo co
        WHERE co.itemcardapio = ca.codigo
          AND co.hospede = h.cpf
    )
);


-- 10) Liste todos os itens do cardapio que nunca foram consumidos.
-- E a mesma ideia do exercicio 7 (nenhum registro em consumo para
-- o item), reforcando o uso de NOT EXISTS.
SELECT ca.codigo, ca.descricao
FROM cardapios ca
WHERE NOT EXISTS (
    SELECT 1 FROM consumo co
    WHERE co.itemcardapio = ca.codigo
);
