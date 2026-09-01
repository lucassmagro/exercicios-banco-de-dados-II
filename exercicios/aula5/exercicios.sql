-- ============================================================
-- Aula 5 - Indices
-- Pre-requisitos: rodar exercicios/aula1/01_schema.sql e
-- exercicios/aula1/02_dados.sql antes deste arquivo.
-- ============================================================

-- 1) Crie um indice que otimize a busca do CPF de um cliente com
--    base na placa de seu veiculo.
-- A placa do veiculo fica na tabela hospedes (placaveiculo). Uma
-- consulta tipica seria "SELECT cpf FROM hospedes WHERE
-- placaveiculo = 'ABC1234'" -- exatamente o tipo de busca por
-- igualdade que um indice B-Tree (padrao) acelera.
CREATE INDEX idx_hospedes_placaveiculo ON hospedes (placaveiculo);


-- 2) Crie um indice que otimize consultas na tabela reservas que
--    busquem o numero do quarto que nao possui reservas apos uma
--    determinada data.
-- Consultas desse tipo filtram por "dataent > algumaData" (ou
-- similar) e depois olham o quarto. Um indice em dataent acelera
-- o filtro por data, que e o gargalo dessas consultas.
CREATE INDEX idx_reservas_dataent ON reservas (dataent);


-- 3) Crie um indice que otimize consultas que listem em ordem
--    crescente os tipos de quartos por preco.
-- Um indice B-Tree ja mantem as chaves ordenadas internamente,
-- entao ele evita uma ordenacao (ORDER BY) explicita em tempo de
-- consulta quando o SGBD decide usa-lo para varrer a tabela nessa
-- ordem.
CREATE INDEX idx_tiposquartos_preco ON tiposquartos (preco ASC);


-- Para conferir se os indices estao sendo usados, use EXPLAIN
-- ANALYZE nas consultas correspondentes, por exemplo:
-- EXPLAIN ANALYZE SELECT cpf FROM hospedes WHERE placaveiculo = 'ABC1234';
-- EXPLAIN ANALYZE SELECT * FROM tiposquartos ORDER BY preco ASC;
