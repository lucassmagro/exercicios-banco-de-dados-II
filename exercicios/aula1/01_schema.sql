-- ============================================================
-- Aula 1 - Exercicio: "Criar o BD conforme as regras disponiveis
-- no portal"
--
-- Modelo (visto no slide "Exercicios" da Aula 1):
--   Clientes     (CPF, nome, origem, fone)
--   Hospedes     (CPF, motivo, placaVeiculo, nroAcomp, dataEnt, dataSai, quarto)
--   Quartos      (numero, frigobar, tipo)
--   TiposQuartos (codigo, descricao, preco)
--   Reservas     (cliente, quarto, dataEnt, dataSai)
--   Cardapios    (codigo, descricao, preco)
--   Consumo      (ID, hospede, itemCardapio, data, qtde)
--
-- As dependencias de FK definem a ordem de criacao das tabelas.
-- ============================================================

CREATE TABLE tiposquartos (
    codigo    INTEGER PRIMARY KEY,
    descricao VARCHAR(50) NOT NULL,
    preco     NUMERIC(10,2) NOT NULL CHECK (preco > 0)
);

CREATE TABLE quartos (
    numero   INTEGER PRIMARY KEY,
    frigobar CHAR(1) CHECK (frigobar IN ('S', 'N')),
    tipo     INTEGER REFERENCES tiposquartos(codigo)
);

CREATE TABLE clientes (
    cpf    NUMERIC(11) PRIMARY KEY,
    nome   VARCHAR(100) NOT NULL,
    origem VARCHAR(50),
    fone   VARCHAR(20)
);

-- Hospede eh um cliente que efetivamente esta/esteve hospedado.
-- CPF referencia clientes: todo hospede precisa ser um cliente cadastrado.
CREATE TABLE hospedes (
    cpf          NUMERIC(11) PRIMARY KEY REFERENCES clientes(cpf),
    motivo       VARCHAR(50),
    placaveiculo VARCHAR(10),
    nroacomp     INTEGER DEFAULT 0,
    dataent      DATE,
    datasai      DATE,
    quarto       INTEGER REFERENCES quartos(numero)
);

-- Reserva: uma mesma data de entrada nao pode ser reservada duas vezes
-- para o mesmo quarto -> chave composta (quarto, dataent).
CREATE TABLE reservas (
    cliente NUMERIC(11) REFERENCES clientes(cpf),
    quarto  INTEGER REFERENCES quartos(numero),
    dataent DATE,
    datasai DATE,
    PRIMARY KEY (quarto, dataent)
);

CREATE TABLE cardapios (
    codigo    INTEGER PRIMARY KEY,
    descricao VARCHAR(50) NOT NULL,
    preco     NUMERIC(10,2) NOT NULL CHECK (preco > 0)
);

-- Consumo: cada linha eh um pedido de um item do cardapio feito
-- por um hospede em uma data especifica.
CREATE TABLE consumo (
    id           SERIAL PRIMARY KEY,
    hospede      NUMERIC(11) REFERENCES hospedes(cpf),
    itemcardapio INTEGER REFERENCES cardapios(codigo),
    data         DATE,
    qtde         INTEGER CHECK (qtde > 0)
);
