-- ============================================================
-- Aula 2 - Revisao SQL: Junções, produto cartesiano e agregação
-- Pre-requisitos: rodar exercicios/aula1/01_schema.sql e
-- exercicios/aula1/02_dados.sql antes deste arquivo.
-- ============================================================

-- 1) Listar o nome de todos os hospedes, origem, motivo e possivel
--    data de saida.
-- "todos os hospedes" -> hospedes sempre tem um cliente correspondente
-- (FK obrigatoria), entao um INNER JOIN normal ja resolve.
-- "possivel" data de saida sugere que ela pode nao existir ainda
-- (hospede que ainda nao fez check-out); por isso ela e so exibida,
-- sem filtro.
SELECT c.nome, c.origem, h.motivo, h.datasai
FROM hospedes h
JOIN clientes c ON c.cpf = h.cpf;


-- 2) Quantos quartos duplos possuem frigobar e nao estao com
--    hospedes?
-- "quarto duplo" = tipo cuja descricao contem 'Duplo' (cobre
-- 'quartoDuplo' e 'aptoDuplo').
-- "nao estao com hospedes" = nao ha, no momento, nenhum hospede
-- ocupando o quarto (ou seja, nenhum registro em hospedes com
-- aquele numero de quarto e datasai em aberto).
SELECT COUNT(*) AS quartos_duplos_livres
FROM quartos q
JOIN tiposquartos t ON t.codigo = q.tipo
WHERE q.frigobar = 'S'
  AND t.descricao ILIKE '%duplo%'
  AND NOT EXISTS (
      SELECT 1 FROM hospedes h
      WHERE h.quarto = q.numero
        AND h.datasai IS NULL
  );


-- 3) Buscar o nome e a origem dos clientes que possuem carros com
--    placa cujo quarto digito seja 1 e o ultimo digito seja 3.
-- A placa esta em hospedes (formato antigo: 3 letras + 4 numeros,
-- ex: ABC1234 = 7 caracteres). O 4o caractere eh o "quarto digito"
-- e o 7o caractere eh o ultimo digito.
-- Padrao LIKE: '_' casa 1 caractere qualquer; '___1__3' exige
-- 7 posicoes, com '1' na posicao 4 e '3' na posicao 7.
SELECT c.nome, c.origem
FROM clientes c
JOIN hospedes h ON h.cpf = c.cpf
WHERE h.placaveiculo LIKE '___1__3';


-- 4) Quantos hospedes possuem uma placa inconsistente cadastrada?
--    (considere inconsistencia ter mais ou menos digitos que os
--    7 padrao)
SELECT COUNT(*) AS placas_inconsistentes
FROM hospedes
WHERE LENGTH(placaveiculo) <> 7;


-- 5) Buscar a descricao de cada item do cardapio e quantas vezes
--    ele foi pedido por algum hospede.
-- LEFT JOIN a partir de cardapios garante que itens NUNCA pedidos
-- tambem apareçam no resultado (com contagem 0).
-- COUNT(co.id), e nao COUNT(*), porque em uma linha sem consumo o
-- LEFT JOIN preenche com NULL, e COUNT ignora NULLs.
SELECT ca.descricao, COUNT(co.id) AS vezes_pedido
FROM cardapios ca
LEFT JOIN consumo co ON co.itemcardapio = ca.codigo
GROUP BY ca.codigo, ca.descricao
ORDER BY ca.descricao;


-- 6) Buscar a descricao dos itens mais e menos caro do cardapio e
--    seus respectivos precos.
-- Duas subconsultas escalares (MAX e MIN) comparadas com o preco de
-- cada item; UNION ALL junta os dois resultados em uma unica lista.
SELECT descricao, preco
FROM cardapios
WHERE preco = (SELECT MAX(preco) FROM cardapios)
UNION ALL
SELECT descricao, preco
FROM cardapios
WHERE preco = (SELECT MIN(preco) FROM cardapios);


-- 7) Buscar o CPF, nome, placa do veiculo de cada hospede, assim
--    como o numero e tipo (descricao) do quarto em que esta
--    hospedado e a data prevista de saida.
SELECT
    h.cpf,
    c.nome,
    h.placaveiculo,
    q.numero  AS numero_quarto,
    t.descricao AS tipo_quarto,
    h.datasai AS data_prevista_saida
FROM hospedes h
JOIN clientes c     ON c.cpf = h.cpf
JOIN quartos q       ON q.numero = h.quarto
JOIN tiposquartos t  ON t.codigo = q.tipo;


-- 8) Buscar o numero dos quartos onde houve consumo de almoco e
--    janta em 12/10/2019.
-- Ligamos consumo -> hospedes (para saber o quarto) -> cardapios
-- (para saber a descricao do item). Agrupamos por quarto e exigimos
-- que os DOIS itens ('almoco' e 'janta') tenham aparecido naquele
-- dia (COUNT DISTINCT descricao = 2).
SELECT h.quarto
FROM hospedes h
JOIN consumo co   ON co.hospede = h.cpf
JOIN cardapios ca ON ca.codigo = co.itemcardapio
WHERE co.data = '2019-10-12'
  AND ca.descricao IN ('almoco', 'janta')
GROUP BY h.quarto
HAVING COUNT(DISTINCT ca.descricao) = 2;


-- 9) Buscar o nome dos clientes, quantas vezes cada cliente ficou
--    hospedado e qual a media de dias das estadias
--    (dataSaida-dataChegada) dos clientes que se hospedaram pelo
--    menos 2 vezes.
-- OBS: no nosso modelo (Aula 1), "cpf" e chave primaria de
-- hospedes, entao cada cliente so pode ter UM registro de estadia
-- por vez. Em um sistema real, esse historico de estadias ficaria
-- em uma tabela com chave (cpf, dataEnt) para permitir varias
-- passagens do mesmo cliente pelo hotel. A consulta abaixo ja esta
-- pronta para esse cenario mais completo: ela conta quantas linhas
-- de hospedes existem por cliente e so mantem quem tem 2 ou mais.
SELECT
    c.nome,
    COUNT(*)                AS vezes_hospedado,
    AVG(h.datasai - h.dataent) AS media_dias_estadia
FROM clientes c
JOIN hospedes h ON h.cpf = c.cpf
GROUP BY c.cpf, c.nome
HAVING COUNT(*) >= 2;


-- 10) Buscar o codigo e a descricao dos itens do cardapio
--     consumidos por todos os hospedes do hotel.
-- Divisao relacional "manual": para cada item, contamos quantos
-- hospedes DISTINTOS o consumiram; se esse numero bater com o total
-- de hospedes cadastrados, e porque TODOS consumiram aquele item.
SELECT ca.codigo, ca.descricao
FROM cardapios ca
JOIN consumo co ON co.itemcardapio = ca.codigo
GROUP BY ca.codigo, ca.descricao
HAVING COUNT(DISTINCT co.hospede) = (SELECT COUNT(*) FROM hospedes);


-- ============================================================
-- Questao ENADE 2008 (comentada) - nao usa o banco do Hotel.
--
-- Tabelas: Artista(id, nome, cpf, dataNascimento),
--          Evento(id, descricao, numMaxConvidados),
--          Atuacao(idArtista, idEvento)  -- tabela associativa N:N
--
-- SELECT A.nome, E.descricao
-- FROM   Evento E FULL JOIN Atuacao T ON E.id = T.idEvento
--        FULL OUTER JOIN Artista A ON T.idArtista = A.id
--
-- Como sao DOIS "FULL (OUTER) JOIN" encadeados, nenhuma linha de
-- nenhuma das tres tabelas e descartada:
--   - todo Evento aparece, mesmo sem nenhum Artista associado
--     (T.idArtista fica NULL -> A.nome fica NULL);
--   - todo Artista aparece, mesmo sem nenhum Evento associado
--     (T.idEvento fica NULL -> E.descricao fica NULL);
--   - quando ha associacao em Atuacao, artista e evento aparecem
--     combinados na mesma linha.
--
-- Resposta correta: alternativa (e) - "o nome de todos os artistas,
-- a descricao de todos os eventos e, caso se relacionem, os dois
-- combinados."
-- ============================================================
