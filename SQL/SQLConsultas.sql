--pessoa fisica
SELECT * FROM DBM.Pessoa JOIN DBM.Pessoa_fisica 
ON Pessoa.id_pessoa = Pessoa_fisica.id_pessoa
--pessoa juridica
SELECT * FROM DBM.Pessoa JOIN DBM.Pessoa_juridica 
ON Pessoa.id_pessoa = Pessoa_juridica.id_pessoa
--movimentacoes de "E" entrada
SELECT * FROM DBM.Movimentacao WHERE tipo = 'E'
--movimentacoes de "S" saida
SELECT * FROM DBM.Movimentacao WHERE tipo = 'S'
--valor total de "E"
SELECT id_produto, SUM(preco_unitario * quantidade_E_S) AS valor_total
FROM DBM.Movimentacao
WHERE tipo = 'E'
GROUP BY id_produto
ORDER BY id_produto;
--valor total de "S"
SELECT id_produto, SUM(preco_unitario * quantidade_E_S) AS valor_total
FROM DBM.Movimentacao
WHERE tipo = 'S'
GROUP BY id_produto
ORDER BY id_produto;
--Operadores que nao efetuaram "E"
SELECT logon
FROM DBM.Usuario
WHERE id_usuario NOT IN (
    SELECT id_usuario
    FROM DBM.Movimentacao
    WHERE tipo = 'E'
);
--valor total de entrada por operador
SELECT Movimentacao.id_usuario, Usuario.logon, SUM(preco_unitario * quantidade_E_S) AS valor_total
FROM DBM.Movimentacao
JOIN DBM.Usuario ON Movimentacao.id_usuario = Usuario.id_usuario
WHERE tipo = 'E'
GROUP BY Movimentacao.id_usuario, Usuario.logon;
--valor total de saida por operador
SELECT Movimentacao.id_usuario, Usuario.logon, SUM(preco_unitario * quantidade_E_S) AS valor_total
FROM DBM.Movimentacao
JOIN DBM.Usuario ON Movimentacao.id_usuario = Usuario.id_usuario
WHERE tipo = 'S'
GROUP BY Movimentacao.id_usuario, Usuario.logon;
--MEDIA AVG por produto
SELECT id_produto, AVG(preco_unitario * quantidade_E_S) AS valor_medio
FROM DBM.Movimentacao
WHERE tipo = 'S'
GROUP BY id_produto;

