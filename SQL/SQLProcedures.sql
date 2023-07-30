--STORED PROCEDURE 

--STORED PROCEDURE Pessoa insert
CREATE PROCEDURE DBM.insert_pessoa
@nome varchar(50),
@logradouro varchar(50),
@cidade varchar(20),
@estado varchar(3),
@telefone varchar(11),
@email varchar(35)
AS 
BEGIN
	IF NOT EXISTS(SELECT 1 FROM DBM.Pessoa WHERE nome=@nome)
		BEGIN
			DECLARE @id_pessoa int;
			SET @id_pessoa = NEXT VALUE FOR sequencia;

			INSERT INTO DBM.Pessoa(id_pessoa, nome, logradouro,cidade,estado,telefone,email)
			VALUES (@id_pessoa,@nome,@logradouro,@cidade,@estado,@telefone,@email)
		END
	ELSE
		BEGIN
			RAISERROR('Pessoa ja cadastrada',16,1)
		END
END
GO

--STORED PROCEDURE Produto insert
CREATE PROCEDURE DBM.insert_produto
@nome varchar(50) ,
@quantidade int  ,
@preco_de_venda decimal(18,2)  
AS 
BEGIN
	IF NOT EXISTS(SELECT 1 FROM DBM.Produtos WHERE nome=@nome)
		BEGIN
			INSERT INTO DBM.Produtos(nome,quantidade,preco_de_venda)
			VALUES (@nome,@quantidade,@preco_de_venda)
		END
	ELSE
		BEGIN
			RAISERROR('Produto ja cadastrado',16,1)
		END
END
GO
--STORED PROCEDURE Usuario insert
CREATE PROCEDURE DBM.insert_usuario
@logon varchar(10) ,
@senha varchar(50)  
AS 
BEGIN
	IF NOT EXISTS(SELECT 1 FROM DBM.Usuario WHERE logon=@logon)
		BEGIN
			INSERT INTO DBM.Usuario(logon,senha)
			VALUES (@logon,@senha)
		END
	ELSE
		BEGIN
			RAISERROR('Usuario ja cadastrado',16,1)
		END
END
GO
--STORED PROCEDURE Movimentacao insert
CREATE PROCEDURE DBM.insert_movimentacao
@id_pessoa int ,
@id_usuario int ,
@id_produto int ,
@tipo varchar(1) ,
@quantidade_E_S int ,
@preco_unitario decimal(18,2)
AS 
BEGIN
--Tratamento do ID	
	IF NOT EXISTS (SELECT 1 FROM DBM.Pessoa WHERE id_pessoa=@id_pessoa)
		BEGIN
				RAISERROR('ID de PESSOA nao existe no banco de dados',16,1)
		END
	ELSE IF NOT EXISTS (SELECT 1 FROM DBM.Usuario WHERE id_usuario=@id_usuario)
		BEGIN
				RAISERROR('ID de USUARIO nao existe no banco de dados',16,1)
		END
	ELSE IF NOT EXISTS (SELECT 1 FROM DBM.Produtos WHERE id_produto=@id_produto)
		BEGIN
				RAISERROR('ID de PRODUTO nao existe no banco de dados',16,1)
		END
--Tratamento do TIPO	
	ELSE IF @tipo = 'E'
		BEGIN
			IF EXISTS (SELECT 1 FROM DBM.Pessoa_fisica WHERE id_pessoa=@id_pessoa AND id_cpf IS not null)
				BEGIN
					RAISERROR('Uma pessoa fisica nao pode VENDER produtos',16,1)
				END
			ELSE IF EXISTS (SELECT 1 FROM DBM.Pessoa_juridica WHERE id_pessoa=@id_pessoa AND id_cnpj IS not null)
				BEGIN
				--Tratamento dos valores
				IF NOT EXISTS (SELECT 1 FROM DBM.Produtos WHERE id_produto=@id_produto AND preco_de_venda > @preco_unitario)
					BEGIN
						RAISERROR('preco de COMPRA maior do que o preco de VENDA nao permitido',16,1)
					END
				ELSE
					BEGIN
						INSERT INTO DBM.Movimentacao(id_pessoa,id_usuario,id_produto,tipo,quantidade_E_S,preco_unitario )
						VALUES (@id_pessoa,@id_usuario,@id_produto,@tipo,@quantidade_E_S,@preco_unitario)
						--Tratamento da quantidade	
						UPDATE DBM.Produtos SET quantidade = quantidade + @quantidade_E_S WHERE id_produto = @id_produto
					END	
				END
			ELSE 
				BEGIN
					RAISERROR('Pessoa nao cadastrada no cnpj, por favor realizar o cadastro',16,1)
				END
		END
	ELSE IF @tipo = 'S'
		BEGIN
			IF EXISTS (SELECT 1 FROM DBM.Pessoa_fisica WHERE id_pessoa=@id_pessoa AND id_cpf IS not null)
				BEGIN
				--Tratamento dos valores
				IF NOT EXISTS (SELECT 1 FROM DBM.Produtos WHERE id_produto=@id_produto AND preco_de_venda < @preco_unitario)
					BEGIN
						RAISERROR('preco de VENDA menor do que o preco de COMPRA, nao permitido',16,1)
					END
				ELSE
					BEGIN
					--Tratamento da quantidade
						IF EXISTS(SELECT 1 FROM DBM.Produtos WHERE quantidade - @quantidade_E_S < 0 AND id_produto = @id_produto )
							BEGIN
								RAISERROR('Quantidade no Estoque menor do que Quandidade da venda',16,1)
							END
						ELSE
							BEGIN
								INSERT INTO DBM.Movimentacao(id_pessoa,id_usuario,id_produto,tipo,quantidade_E_S,preco_unitario )
								VALUES (@id_pessoa,@id_usuario,@id_produto,@tipo,@quantidade_E_S,@preco_unitario)
								UPDATE DBM.Produtos SET quantidade = quantidade - @quantidade_E_S WHERE id_produto = @id_produto 

							END				
					END
				END
			ELSE IF EXISTS (SELECT 1 FROM DBM.Pessoa_juridica WHERE id_pessoa=@id_pessoa AND id_cnpj IS not null)
				BEGIN	
					RAISERROR('Uma pessoa Juridica nao pode COMPRAR produtos',16,1)
				END
			ELSE 
				BEGIN
					RAISERROR('Pessoa nao cadastrada no cpf, por favor realizar o cadastro',16,1)
				END
		END
	
END
GO

--execucoes adicionando valores
EXEC DBM.insert_pessoa @nome = 'João da Silva', @logradouro = 'Rua da Paz', @cidade = 'São Paulo', 
@estado = 'SP', @telefone = 11999999999, @email = 'joao.da.silva@email.com';
EXEC DBM.insert_pessoa @nome = 'rafa', @logradouro = 'Rua da raiva', @cidade = 'São Paulo', 
@estado = 'SP', @telefone = 11999999669, @email = 'rafa.da.raiva@email.com';
EXEC DBM.insert_pessoa @nome = 'renan', @logradouro = 'Rua da raiva', @cidade = 'São Paulo', 
@estado = 'SP', @telefone = 11999999669, @email = 'rafa.da.raiva@email.com';

INSERT INTO DBM.Pessoa_fisica(id_cpf,id_pessoa) VALUES		('1111222222',1);
INSERT INTO DBM.Pessoa_juridica(id_cnpj,id_pessoa) VALUES	('1111111111',2);

EXEC DBM.insert_produto @nome = 'Maça', @quantidade = 10, @preco_de_venda = 10.00;
EXEC DBM.insert_produto @nome = 'Ovos', @quantidade = 12, @preco_de_venda = 5.00;
EXEC DBM.insert_produto @nome = 'Carne', @quantidade = 1, @preco_de_venda = 20.00;
EXEC DBM.insert_produto @nome = 'Frango', @quantidade = 1, @preco_de_venda = 15.00;
EXEC DBM.insert_produto @nome = 'Peixe', @quantidade = 1, @preco_de_venda = 10.00;
EXEC DBM.insert_produto @nome = 'Salmão', @quantidade = 1, @preco_de_venda = 20.00;
EXEC DBM.insert_produto @nome = 'Atum', @quantidade = 1, @preco_de_venda = 15.00;
EXEC DBM.insert_produto @nome = 'Caranguejo', @quantidade = 1, @preco_de_venda = 10.00;
EXEC DBM.insert_produto @nome = 'Cerveja', @quantidade = 6, @preco_de_venda = 5.00;
EXEC DBM.insert_produto @nome = 'Vinho', @quantidade = 3, @preco_de_venda = 10.00;

EXEC DBM.insert_usuario @logon = 'admin1', @senha = '123';
EXEC DBM.insert_usuario @logon = 'admin2', @senha = '123';


EXEC DBM.insert_movimentacao @id_pessoa = 2, @id_usuario = 1, 
@id_produto = 5, @tipo = 'E', @quantidade_E_S = 1, @preco_unitario = 7.00;

EXEC DBM.insert_movimentacao @id_pessoa = 1, @id_usuario = 2, 
@id_produto = 2, @tipo = 'E', @quantidade_E_S = 1, @preco_unitario = 12.00;
EXEC DBM.insert_movimentacao @id_pessoa = 2, @id_usuario = 1, 
@id_produto = 4, @tipo = 'S', @quantidade_E_S = 1, @preco_unitario = 12.00;

EXEC DBM.insert_movimentacao @id_pessoa = 1, @id_usuario = 2, 
@id_produto = 7, @tipo = 'S', @quantidade_E_S = 1, @preco_unitario = 40.00;

EXEC DBM.insert_movimentacao @id_pessoa = 3, @id_usuario = 1, 
@id_produto = 1, @tipo = 'S', @quantidade_E_S = 1, @preco_unitario = 12.00;


DELETE FROM DBM.Movimentacao WHERE id_pessoa = 1 AND id_pessoa =2

--Recomecar
DROP PROCEDURE DBM.insert_pessoa;
DROP PROCEDURE DBM.insert_usuario;
DROP PROCEDURE DBM.insert_produto;
DROP PROCEDURE DBM.insert_movimentacao;