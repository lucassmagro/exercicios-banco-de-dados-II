-- ============================================================
-- Aula 1 - Revisao SQL: Selecao e Joins
-- Pre-requisitos: 01_schema.sql e 02_dados.sql ja executados.
-- ============================================================

-- 1) Buscar o nome, CPF e origem de todos os clientes.
-- Projecao simples (SELECT) sem nenhuma condicao (WHERE).
SELECT nome, cpf, origem
FROM clientes;


-- 2) Buscar nome, CPF e o motivo de hospedagem de todos os clientes.
-- "motivo" so existe na tabela hospedes, entao precisamos juntar
-- clientes com hospedes pela chave CPF (junto = INNER JOIN).
SELECT c.nome, c.cpf, h.motivo
FROM clientes c
JOIN hospedes h ON h.cpf = c.cpf;


-- 3) Buscar a descricao e o preco dos itens do cardapio que custam
--    mais de 30 reais.
-- Filtro simples com WHERE sobre um atributo numerico.
SELECT descricao, preco
FROM cardapios
WHERE preco > 30;


-- 4) Buscar para todos os quartos: numero do quarto, a descricao,
--    o preco e se tem frigobar.
-- descricao/preco vem de tiposquartos, entao precisamos do join
-- quartos -> tiposquartos usando a FK "tipo".
-- LEFT JOIN garante que TODOS os quartos aparecam, mesmo que algum
-- fique sem tipo cadastrado (o enunciado pede "para todos os quartos").
SELECT q.numero, t.descricao, t.preco, q.frigobar
FROM quartos q
LEFT JOIN tiposquartos t ON t.codigo = q.tipo;


-- 5) Buscar o motivo e o numero de acompanhantes de todos os
--    hospedes que vieram de carro.
-- "vieram de carro" = possuem uma placa de veiculo cadastrada
-- (placaveiculo preenchida, ou seja, nao nula).
SELECT motivo, nroacomp
FROM hospedes
WHERE placaveiculo IS NOT NULL;


-- 6) Buscar o nome, CPF e telefone dos clientes de 'Florianopolis',
--    'Joinville' e 'Blumenau'.
-- IN eh um atalho para varios "OR origem = ...".
SELECT nome, cpf, fone
FROM clientes
WHERE origem IN ('Florianopolis', 'Joinville', 'Blumenau');


-- 7) Buscar o motivo da hospedagem, o numero de hospedes por motivo,
--    a media de acompanhantes e a media de dias que os hospedes
--    ficaram no hotel.
-- GROUP BY motivo agrupa as linhas; as funcoes de agregacao
-- (COUNT/AVG) sao calculadas dentro de cada grupo.
-- datasai - dataent (subtracao de DATE) retorna o numero de dias
-- da estadia.
SELECT
    motivo,
    COUNT(*)                      AS numero_hospedes,
    AVG(nroacomp)                 AS media_acompanhantes,
    AVG(datasai - dataent)        AS media_dias_hospedado
FROM hospedes
GROUP BY motivo;


-- 8) Buscar o numero de quartos que nao possuem reserva na data de
--    29/07/2019.
-- Usamos um subselect com NOT IN: pegamos primeiro os quartos que
-- TEM reserva justamente naquela data de entrada, e depois filtramos
-- os quartos que NAO estao nessa lista.
SELECT numero
FROM quartos
WHERE numero NOT IN (
    SELECT quarto
    FROM reservas
    WHERE dataent = '2019-07-29'
);
