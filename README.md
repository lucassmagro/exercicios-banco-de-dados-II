# Exercícios - Banco de Dados II

Exercícios resolvidos e comentados da disciplina **Banco de Dados II** (Sistemas da Informação, UNOESC - Campus Chapecó, prof. Álvaro G. Pagliari), a partir dos slides das aulas em [`aulas/`](aulas/).

Todos os exercícios usam o mesmo cenário de um hotel (clientes, hóspedes, quartos, reservas, cardápio e consumo), cujos dados de exemplo vêm de [`bdHotel.txt`](bdHotel.txt).

## Estrutura

```
aulas/                 Slides originais das aulas 1 a 6 (PDF)
bdHotel.txt             Dados de exemplo usados para popular o banco
exercicios/
  aula1/
    01_schema.sql       CREATE TABLE das 7 tabelas do modelo do hotel
    02_dados.sql         INSERTs com os dados de bdHotel.txt
    03_exercicios.sql   Revisão SQL: seleção e junções (8 exercícios)
  aula2/exercicios.sql  Junções, produto cartesiano e agregação (10 exercícios + questão ENADE)
  aula3/exercicios.sql  Subconsultas aninhadas e EXISTS (10 exercícios)
  aula4/exercicios.sql  Funções em PL/pgSQL (12 exercícios)
  aula5/exercicios.sql  Índices (3 exercícios)
  aula6/exercicios.sql  Triggers (3 exercícios)
```

Cada arquivo `.sql` traz o enunciado do exercício como comentário logo acima da consulta/função que o resolve, explicando o raciocínio da solução.

## Como rodar

Pré-requisito: um PostgreSQL rodando localmente (ou em Docker) e o `psql` disponível.

1. Crie o banco e carregue o schema/dados da Aula 1:

   ```powershell
   psql -U postgres -h localhost -c "CREATE DATABASE bdhotel;"
   psql -U postgres -h localhost -d bdhotel -f exercicios/aula1/01_schema.sql
   psql -U postgres -h localhost -d bdhotel -f exercicios/aula1/02_dados.sql
   ```

2. A partir daí, qualquer arquivo em `exercicios/` pode ser executado contra o banco `bdhotel`:

   ```powershell
   psql -U postgres -h localhost -d bdhotel -f exercicios/aula1/03_exercicios.sql
   ```

### Usando o VS Code

Este repositório já recomenda a extensão oficial [PostgreSQL (Microsoft)](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-pgsql) em [`.vscode/extensions.json`](.vscode/extensions.json). Com ela é possível conectar no banco `bdhotel` e rodar qualquer `.sql` direto do editor, sem sair do VS Code.
