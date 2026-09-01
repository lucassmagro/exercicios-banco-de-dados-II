-- ============================================================
-- Aula 4 - SQL Avancado: Functions (PL/pgSQL)
-- Pre-requisitos: rodar exercicios/aula1/01_schema.sql e
-- exercicios/aula1/02_dados.sql antes deste arquivo.
-- ============================================================

-- 1) Funcao que calcula o fatorial de um numero n.
-- Laco FOR simples multiplicando o resultado a cada iteracao.
-- RAISE EXCEPTION protege contra entrada invalida (numero negativo).
CREATE OR REPLACE FUNCTION fatorial(n INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    resultado NUMERIC := 1;
    i INTEGER;
BEGIN
    IF n < 0 THEN
        RAISE EXCEPTION 'fatorial nao definido para numeros negativos: %', n;
    END IF;

    FOR i IN 1..n LOOP
        resultado := resultado * i;
    END LOOP;

    RETURN resultado;
END;
$$ LANGUAGE plpgsql;

-- Teste: SELECT fatorial(5);  -> 120


-- ============================================================
-- 2) CRUD (insercao / alteracao / exclusao) para Quartos e
--    Clientes, seguindo as regras do enunciado:
--    a) insercao retorna a PK do novo registro (INSERT ... RETURNING)
--    b) alteracao recebe a PK + dados e nao retorna nada (VOID)
--    c) exclusao recebe a PK e retorna TRUE se apagou algo,
--       FALSE caso contrario (GET DIAGNOSTICS ... ROW_COUNT)
-- ============================================================

-- --- Quartos (PK = numero) ---

CREATE OR REPLACE FUNCTION inserir_quarto(p_numero INTEGER, p_frigobar CHAR(1), p_tipo INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_numero INTEGER;
BEGIN
    INSERT INTO quartos (numero, frigobar, tipo)
    VALUES (p_numero, p_frigobar, p_tipo)
    RETURNING numero INTO v_numero;

    RETURN v_numero;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alterar_quarto(p_numero INTEGER, p_frigobar CHAR(1), p_tipo INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE quartos
    SET frigobar = p_frigobar,
        tipo     = p_tipo
    WHERE numero = p_numero;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION excluir_quarto(p_numero INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    linhas_afetadas INTEGER;
BEGIN
    DELETE FROM quartos WHERE numero = p_numero;
    GET DIAGNOSTICS linhas_afetadas = ROW_COUNT;
    RETURN linhas_afetadas > 0;
END;
$$ LANGUAGE plpgsql;

-- --- Clientes (PK = cpf) ---

CREATE OR REPLACE FUNCTION inserir_cliente(p_cpf NUMERIC, p_nome VARCHAR, p_origem VARCHAR, p_fone VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_cpf NUMERIC;
BEGIN
    INSERT INTO clientes (cpf, nome, origem, fone)
    VALUES (p_cpf, p_nome, p_origem, p_fone)
    RETURNING cpf INTO v_cpf;

    RETURN v_cpf;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alterar_cliente(p_cpf NUMERIC, p_nome VARCHAR, p_origem VARCHAR, p_fone VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE clientes
    SET nome   = p_nome,
        origem = p_origem,
        fone   = p_fone
    WHERE cpf = p_cpf;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION excluir_cliente(p_cpf NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE
    linhas_afetadas INTEGER;
BEGIN
    DELETE FROM clientes WHERE cpf = p_cpf;
    GET DIAGNOSTICS linhas_afetadas = ROW_COUNT;
    RETURN linhas_afetadas > 0;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 3) "passaRegua": fecha a conta do hospede (recebe o CPF),
--    marca a data de saida como hoje e retorna o valor gasto
--    apenas com a estadia (dias hospedado * preco do quarto).
-- ============================================================
CREATE OR REPLACE FUNCTION passaregua(p_cpf NUMERIC)
RETURNS NUMERIC AS $$
DECLARE
    v_dias         INTEGER;
    v_preco_quarto NUMERIC;
BEGIN
    -- so fecha a conta se a estadia ainda estiver em aberto
    UPDATE hospedes
    SET datasai = CURRENT_DATE
    WHERE cpf = p_cpf AND datasai IS NULL;

    SELECT (h.datasai - h.dataent), t.preco
    INTO v_dias, v_preco_quarto
    FROM hospedes h
    JOIN quartos q      ON q.numero = h.quarto
    JOIN tiposquartos t ON t.codigo = q.tipo
    WHERE h.cpf = p_cpf;

    RETURN v_dias * v_preco_quarto;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 4) Atualizacao de "passaRegua" considerando tambem o valor
--    gasto em consumo de itens do cardapio durante a estadia.
-- ============================================================
CREATE OR REPLACE FUNCTION passaregua(p_cpf NUMERIC, p_incluir_consumo BOOLEAN)
RETURNS NUMERIC AS $$
DECLARE
    v_dias           INTEGER;
    v_preco_quarto   NUMERIC;
    v_valor_diarias  NUMERIC;
    v_valor_consumo  NUMERIC;
BEGIN
    UPDATE hospedes
    SET datasai = CURRENT_DATE
    WHERE cpf = p_cpf AND datasai IS NULL;

    SELECT (h.datasai - h.dataent), t.preco
    INTO v_dias, v_preco_quarto
    FROM hospedes h
    JOIN quartos q      ON q.numero = h.quarto
    JOIN tiposquartos t ON t.codigo = q.tipo
    WHERE h.cpf = p_cpf;

    v_valor_diarias := v_dias * v_preco_quarto;

    IF NOT p_incluir_consumo THEN
        RETURN v_valor_diarias;
    END IF;

    SELECT COALESCE(SUM(co.qtde * ca.preco), 0)
    INTO v_valor_consumo
    FROM consumo co
    JOIN cardapios ca ON ca.codigo = co.itemcardapio
    WHERE co.hospede = p_cpf;

    RETURN v_valor_diarias + v_valor_consumo;
END;
$$ LANGUAGE plpgsql;

-- Teste: SELECT passaregua(10000000001, true);


-- ============================================================
-- 5) Tabela "teste" (id serial PK, texto varchar(100)) e funcao
--    que gera N registros com string aleatoria via MD5(random()).
-- ============================================================
CREATE TABLE tabela_teste (
    id    SERIAL PRIMARY KEY,
    texto VARCHAR(100)
);

CREATE OR REPLACE FUNCTION gerar_tabela_teste(p_quantidade INTEGER)
RETURNS VOID AS $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..p_quantidade LOOP
        INSERT INTO tabela_teste (texto) VALUES (MD5(random()::text));
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Teste: SELECT gerar_tabela_teste(10);


-- ============================================================
-- 6) Registra o consumo de um item pelo nome (descricao), a
--    quantidade e o CPF do hospede. Se o item nao existir no
--    cardapio, ele e cadastrado automaticamente antes.
-- ============================================================
CREATE OR REPLACE FUNCTION registrar_consumo(p_item VARCHAR, p_qtde INTEGER, p_cpf NUMERIC)
RETURNS VOID AS $$
DECLARE
    v_codigo INTEGER;
BEGIN
    SELECT codigo INTO v_codigo
    FROM cardapios
    WHERE descricao = p_item;

    IF v_codigo IS NULL THEN
        INSERT INTO cardapios (codigo, descricao, preco)
        VALUES ((SELECT COALESCE(MAX(codigo), 0) + 1 FROM cardapios), p_item, 0)
        RETURNING codigo INTO v_codigo;
    END IF;

    INSERT INTO consumo (hospede, itemcardapio, data, qtde)
    VALUES (p_cpf, v_codigo, CURRENT_DATE, p_qtde);
END;
$$ LANGUAGE plpgsql;

-- Teste: SELECT registrar_consumo('pizza', 2, 10000000001);


-- ============================================================
-- 7) Funcao que retorna um array com a descricao de todos os
--    itens do cardapio.
-- ============================================================
CREATE OR REPLACE FUNCTION listar_itens_cardapio()
RETURNS TEXT[] AS $$
DECLARE
    resultado TEXT[] := ARRAY[]::TEXT[];
    item RECORD;
BEGIN
    FOR item IN SELECT descricao FROM cardapios LOOP
        resultado := array_append(resultado, item.descricao);
    END LOOP;

    RETURN resultado;
END;
$$ LANGUAGE plpgsql;

-- Teste: SELECT listar_itens_cardapio();


-- ============================================================
-- 8) Funcao que realiza a reserva de um hospede, validando:
--    - o quarto nao pode ja estar reservado no periodo pedido;
--    - o cliente nao pode ter mais de uma reserva ativa por vez.
-- ============================================================
CREATE OR REPLACE FUNCTION reservar(p_cpf NUMERIC, p_quarto INTEGER, p_dataent DATE, p_datasai DATE)
RETURNS VOID AS $$
BEGIN
    -- ha sobreposicao de periodo para o mesmo quarto?
    IF EXISTS (
        SELECT 1 FROM reservas r
        WHERE r.quarto = p_quarto
          AND r.dataent <= p_datasai
          AND r.datasai >= p_dataent
    ) THEN
        RAISE EXCEPTION 'Quarto % ja possui reserva no periodo informado', p_quarto;
    END IF;

    -- o cliente ja tem alguma reserva cujo periodo ainda nao terminou?
    IF EXISTS (
        SELECT 1 FROM reservas r
        WHERE r.cliente = p_cpf
          AND r.datasai >= CURRENT_DATE
    ) THEN
        RAISE EXCEPTION 'Cliente % ja possui uma reserva ativa', p_cpf;
    END IF;

    INSERT INTO reservas (cliente, quarto, dataent, datasai)
    VALUES (p_cpf, p_quarto, p_dataent, p_datasai);
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 9) Funcao que calcula o lucro do hotel em um periodo,
--    somando diarias (proporcionais aos dias dentro do periodo)
--    e itens de cardapio consumidos no periodo.
-- ============================================================
CREATE OR REPLACE FUNCTION lucro_periodo(p_inicio DATE, p_fim DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_diarias NUMERIC;
    v_consumo NUMERIC;
BEGIN
    -- para cada hospedagem que se sobrepoe ao periodo, conta so os
    -- dias que caem dentro dele (GREATEST/LEAST fazem a intersecao
    -- dos intervalos de datas).
    SELECT COALESCE(SUM(
        (LEAST(COALESCE(h.datasai, p_fim), p_fim) - GREATEST(h.dataent, p_inicio)) * t.preco
    ), 0)
    INTO v_diarias
    FROM hospedes h
    JOIN quartos q      ON q.numero = h.quarto
    JOIN tiposquartos t ON t.codigo = q.tipo
    WHERE h.dataent <= p_fim
      AND COALESCE(h.datasai, p_fim) >= p_inicio;

    SELECT COALESCE(SUM(co.qtde * ca.preco), 0)
    INTO v_consumo
    FROM consumo co
    JOIN cardapios ca ON ca.codigo = co.itemcardapio
    WHERE co.data BETWEEN p_inicio AND p_fim;

    RETURN v_diarias + v_consumo;
END;
$$ LANGUAGE plpgsql;

-- Teste: SELECT lucro_periodo('2019-01-01', '2019-12-31');


-- ============================================================
-- 10) Funcao que recebe o CPF de um cliente e retorna uma string
--     "Nome, telefone".
-- ============================================================
CREATE OR REPLACE FUNCTION nome_e_telefone(p_cpf NUMERIC)
RETURNS TEXT AS $$
DECLARE
    resultado TEXT;
BEGIN
    SELECT nome || ', ' || fone
    INTO resultado
    FROM clientes
    WHERE cpf = p_cpf;

    RETURN resultado;
END;
$$ LANGUAGE plpgsql;

-- Teste: SELECT nome_e_telefone(10000000001);


-- ============================================================
-- 11) Funcao que gera clientes aleatorios. Recebe quantos
--     clientes (hospedes em potencial) devem ser criados.
-- ============================================================
CREATE OR REPLACE FUNCTION gerar_clientes(p_quantidade INTEGER)
RETURNS VOID AS $$
DECLARE
    i INTEGER;
    v_cpf NUMERIC;
    origens TEXT[] := ARRAY['Florianopolis', 'Joinville', 'Blumenau', 'Chapeco', 'Curitiba'];
BEGIN
    FOR i IN 1..p_quantidade LOOP
        -- CPF aleatorio de 11 digitos (apenas para fins didaticos)
        v_cpf := (90000000000 + floor(random() * 9999999999))::NUMERIC;

        INSERT INTO clientes (cpf, nome, origem, fone)
        VALUES (
            v_cpf,
            'Cliente ' || substr(MD5(random()::text), 1, 8),
            origens[1 + floor(random() * array_length(origens, 1))::INT],
            (10000000 + floor(random() * 89999999))::TEXT
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Teste: SELECT gerar_clientes(5);


-- ============================================================
-- 12) Funcao que gera hospedagens. Recebe quantos registros de
--     hospedagem devem ser criados; cada hospedagem tambem gera
--     entre 0 e 30 consumos aleatorios.
-- ============================================================
CREATE OR REPLACE FUNCTION gerar_hospedagens(p_quantidade INTEGER)
RETURNS VOID AS $$
DECLARE
    i INTEGER;
    j INTEGER;
    v_cpf NUMERIC;
    v_quarto INTEGER;
    v_dataent DATE;
    v_datasai DATE;
    v_num_consumos INTEGER;
    v_item INTEGER;
BEGIN
    FOR i IN 1..p_quantidade LOOP
        SELECT cpf    INTO v_cpf    FROM clientes ORDER BY random() LIMIT 1;
        SELECT numero INTO v_quarto FROM quartos   ORDER BY random() LIMIT 1;

        v_dataent := CURRENT_DATE - (floor(random() * 365))::INT;
        v_datasai := v_dataent + (1 + floor(random() * 14))::INT;

        -- cpf e PK de hospedes: so criamos a hospedagem se esse
        -- cliente ainda nao tiver uma (em um modelo com historico de
        -- estadias, a chave seria cpf + dataEnt e essa checagem nao
        -- seria necessaria).
        IF NOT EXISTS (SELECT 1 FROM hospedes WHERE cpf = v_cpf) THEN
            INSERT INTO hospedes (cpf, motivo, placaveiculo, nroacomp, dataent, datasai, quarto)
            VALUES (v_cpf, 'gerado automaticamente', NULL, floor(random() * 4)::INT, v_dataent, v_datasai, v_quarto);

            v_num_consumos := floor(random() * 31)::INT; -- entre 0 e 30

            FOR j IN 1..v_num_consumos LOOP
                SELECT codigo INTO v_item FROM cardapios ORDER BY random() LIMIT 1;

                INSERT INTO consumo (hospede, itemcardapio, data, qtde)
                VALUES (
                    v_cpf,
                    v_item,
                    v_dataent + floor(random() * GREATEST(v_datasai - v_dataent, 1))::INT,
                    1 + floor(random() * 5)::INT
                );
            END LOOP;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Teste: SELECT gerar_hospedagens(3);
