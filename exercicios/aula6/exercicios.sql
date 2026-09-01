-- ============================================================
-- Aula 6 (slide interno da aula: "Aula 5 - Triggers")
-- Pre-requisitos: rodar exercicios/aula1/01_schema.sql e
-- exercicios/aula1/02_dados.sql antes deste arquivo.
-- ============================================================

-- 1) Trigger que verifica e grava o nome de novos clientes em
--    MAIUSCULO.
-- Precisa ser BEFORE INSERT (executa antes de o registro ser
-- gravado) e FOR EACH ROW (para poder alterar NEW, a linha que
-- esta sendo inserida). A funcao retorna NEW ja modificado.
CREATE OR REPLACE FUNCTION clientes_nome_maiusculo()
RETURNS TRIGGER AS $$
BEGIN
    NEW.nome := UPPER(NEW.nome);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_clientes_nome_maiusculo
    BEFORE INSERT ON clientes
    FOR EACH ROW
    EXECUTE PROCEDURE clientes_nome_maiusculo();

-- Teste:
-- INSERT INTO clientes (cpf, nome, origem, fone)
-- VALUES (99999999999, 'teste minusculo', 'Chapeco', '00000000');
-- SELECT nome FROM clientes WHERE cpf = 99999999999;  -- 'TESTE MINUSCULO'


-- ============================================================
-- 2) Tabela "log" para auditoria de alteracoes.
-- ============================================================
CREATE TABLE log (
    identificador SERIAL PRIMARY KEY,
    tabela        VARCHAR(50),
    operacao      VARCHAR(10),
    dadosnovos    TEXT,
    dadosantigos  TEXT
);


-- ============================================================
-- 3) Trigger de log para as tabelas "Hospedes" e "Reservas".
--    - UPDATE: grava o nome da tabela, a operacao ("UPDATE") e o
--      conteudo ANTERIOR (OLD) e ATUAL (NEW) do registro.
--    - DELETE: grava o nome da tabela, a operacao ("DELETE") e o
--      conteudo do registro excluido (OLD); nao existe "dado novo".
--
-- Uma unica funcao generica serve para as duas tabelas: TG_TABLE_NAME
-- e TG_OP sao variaveis especiais preenchidas automaticamente pelo
-- PostgreSQL com o nome da tabela e o tipo de operacao que disparou
-- a trigger. ROW(OLD.*) / ROW(NEW.*) convertem a linha inteira em um
-- registro composto, que e entao convertido para texto (::TEXT) para
-- caber na coluna TEXT de log.
-- ============================================================
CREATE OR REPLACE FUNCTION registra_log()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO log (tabela, operacao, dadosantigos, dadosnovos)
        VALUES (TG_TABLE_NAME, TG_OP, ROW(OLD.*)::TEXT, ROW(NEW.*)::TEXT);
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO log (tabela, operacao, dadosantigos, dadosnovos)
        VALUES (TG_TABLE_NAME, TG_OP, ROW(OLD.*)::TEXT, NULL);
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_hospedes
    AFTER UPDATE OR DELETE ON hospedes
    FOR EACH ROW
    EXECUTE PROCEDURE registra_log();

CREATE TRIGGER log_reservas
    AFTER UPDATE OR DELETE ON reservas
    FOR EACH ROW
    EXECUTE PROCEDURE registra_log();

-- Teste:
-- UPDATE hospedes SET motivo = 'ferias' WHERE cpf = 10000000001;
-- DELETE FROM reservas WHERE quarto = 4 AND dataent = '2019-06-05';
-- SELECT * FROM log ORDER BY identificador;
