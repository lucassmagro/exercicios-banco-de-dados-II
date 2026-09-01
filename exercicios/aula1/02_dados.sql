-- ============================================================
-- Aula 1 - Exercicio: "Popular o BD"
--
-- Dados extraidos de bdHotel.txt (na raiz do projeto).
-- Datas convertidas de DD/MM/YYYY para o formato ISO (YYYY-MM-DD)
-- exigido pelo PostgreSQL.
-- ============================================================

INSERT INTO tiposquartos (codigo, descricao, preco) VALUES
    (1, 'quartoSimples', 10000),
    (2, 'quartoDuplo',   200),
    (3, 'quartoTriplo',  300),
    (4, 'aptoSimples',   400),
    (5, 'aptoDuplo',     500),
    (6, 'aptoDuplo',     600);

INSERT INTO quartos (numero, frigobar, tipo) VALUES
    (1, 'S', 1),
    (2, 'N', 3),
    (3, 'S', 5),
    (4, 'N', 6),
    (5, 'N', 5),
    (6, 'S', 2);

INSERT INTO clientes (cpf, nome, origem, fone) VALUES
    (10000000001, 'Dexyter',        'Florianopolis', '10000000'),
    (20000000002, 'Harry Potter',   'Blumenau',       '20000000'),
    (30000000003, 'Hannibal',       'Joinville',      '30000000'),
    (40000000004, 'Jon Snow',       'Winterfell',     '40000000'),
    (50000000005, 'Lucifer',        'Hell',           '50000000'),
    (60000000006, 'Harvey Specter', 'New York',       '60000000'),
    (70000000007, 'James T Kirk',   'Enterprise',     '70000000');

INSERT INTO hospedes (cpf, motivo, placaveiculo, nroacomp, dataent, datasai, quarto) VALUES
    (10000000001, 'trabalho',         'ABC1234', 0, '2019-10-01', '2019-10-03', 1),
    (20000000002, 'estudo',           'DEF1234', 2, '2019-10-03', '2019-10-13', 2),
    (30000000003, 'visita familiar',  'GHI123',  1, '2019-11-09', '2019-11-14', 3),
    (40000000004, 'visita familiar',  'JKL123',  4, '2019-10-13', '2019-10-15', 4),
    (50000000005, 'turismo',          'MNO123',  1, '2019-01-01', '2019-06-01', 5);

-- Clientes 60000000006 e 70000000007 nunca se hospedaram: apenas fizeram
-- reserva. Isso eh usado nos exercicios sobre "clientes que nao sao hospedes".
INSERT INTO reservas (cliente, quarto, dataent, datasai) VALUES
    (60000000006, 4, '2019-06-05', '2019-06-07'),
    (70000000007, 5, '2019-12-10', '2019-12-23'),
    (20000000002, 3, '2019-11-01', '2019-11-05'),
    (40000000004, 2, '2019-05-23', '2019-05-24'),
    (30000000003, 1, '2019-12-10', '2019-12-14');

INSERT INTO cardapios (codigo, descricao, preco) VALUES
    (1, 'cafe',         10),
    (2, 'almoco',       20),
    (3, 'janta',        30),
    (4, 'salgado',      40),
    (5, 'refrigerante', 50),
    (6, 'sanduiche',    60),
    (7, 'sanduiche',    70),
    (8, 'estricnina',   70);

INSERT INTO consumo (hospede, itemcardapio, data, qtde) VALUES
    (10000000001, 1, '2019-10-02', 1),
    (10000000001, 3, '2019-10-02', 1),
    (20000000002, 2, '2019-10-12', 2),
    (30000000003, 4, '2019-11-10', 5),
    (40000000004, 1, '2019-10-14', 3),
    (50000000005, 5, '2019-05-15', 4),
    (20000000002, 3, '2019-10-12', 1),
    (20000000002, 3, '2019-10-12', 2);
