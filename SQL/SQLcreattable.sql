USE Loja
go

CREATE SCHEMA DBM
go
--sequencia
CREATE SEQUENCE sequencia
START WITH 1
INCREMENT BY 1
MAXVALUE 100
MINVALUE 1;
DROP SEQUENCE sequencia;
--Pessoa
CREATE TABLE DBM.Pessoa
(id_pessoa int PRIMARY KEY,
nome varchar(50) not null,
logradouro varchar(50) not null,
cidade varchar(20) not null,
estado varchar(3) not null,
telefone varchar(11),
email varchar(35)
);
GO

--Pessoa Fisica e Juridica
CREATE TABLE DBM.Pessoa_fisica
(id_cpf int not null,
id_pessoa int not null
CONSTRAINT PK_Pessoa_fisica PRIMARY KEY (id_cpf),
CONSTRAINT FK_Pessoa_f		FOREIGN KEY (id_pessoa)
REFERENCES DBM.Pessoa
);
GO
CREATE TABLE DBM.Pessoa_juridica
(id_cnpj int not null,
id_pessoa int not null,
CONSTRAINT PK_Pessoa_juridica PRIMARY KEY (id_cnpj),
CONSTRAINT FK_Pessoa_j		FOREIGN KEY (id_pessoa)
REFERENCES DBM.Pessoa
);
GO

--Produtos e Usuarios 
CREATE TABLE DBM.Produtos
(id_produto int IDENTITY(1,1) PRIMARY KEY,
nome varchar(50) not null,
quantidade int not null,
preco_de_venda decimal(18,2) not null
);
GO

CREATE TABLE DBM.Usuario 
(id_usuario int IDENTITY(1,1) PRIMARY KEY,
logon varchar(10) not null,
senha varchar(50) not null
);
GO
--Criado as Movimentacoes de E e S "Entrada" e "Saida"

CREATE TABLE DBM.Movimentacao
(id_movimentacao int IDENTITY(1,1) not null,
id_pessoa int not null,
id_usuario int not null,
id_produto int not null,
tipo varchar(1) not null,
quantidade_E_S int not null,
preco_unitario decimal(18,2) not null,

CONSTRAINT CK_Tipo CHECK (tipo IN ('S', 'E')),
CONSTRAINT PK_id_movimentacao	PRIMARY KEY (id_movimentacao),
CONSTRAINT FK_id_Pessoa_M		FOREIGN KEY (id_pessoa)  REFERENCES DBM.Pessoa,
CONSTRAINT FK_id_usuario_M		FOREIGN KEY (id_usuario) REFERENCES DBM.Usuario,
CONSTRAINT FK_id_produto_M		FOREIGN KEY (id_produto) REFERENCES DBM.Produtos
);
GO
-- PROCEDIMENTO 2
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--STORED PROCEDURE 
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
						IF EXISTS(SELECT 1 FROM DBM.Produtos WHERE quantidade - @quantidade_E_S < 0)
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
@id_produto = 4, @tipo = 'E', @quantidade_E_S = 1, @preco_unitario = 12.00;
EXEC DBM.insert_movimentacao @id_pessoa = 1, @id_usuario = 2, 
@id_produto = 2, @tipo = 'E', @quantidade_E_S = 1, @preco_unitario = 12.00;
EXEC DBM.insert_movimentacao @id_pessoa = 2, @id_usuario = 1, 
@id_produto = 4, @tipo = 'S', @quantidade_E_S = 1, @preco_unitario = 12.00;
EXEC DBM.insert_movimentacao @id_pessoa = 1, @id_usuario = 2, 
@id_produto = 3, @tipo = 'S', @quantidade_E_S = 1, @preco_unitario = 25.00;
EXEC DBM.insert_movimentacao @id_pessoa = 3, @id_usuario = 1, 
@id_produto = 1, @tipo = 'S', @quantidade_E_S = 1, @preco_unitario = 12.00;


DELETE FROM DBM.Movimentacao WHERE id_pessoa = 1 AND id_pessoa =2

--Recomecar
DROP PROCEDURE DBM.insert_pessoa;
DROP PROCEDURE DBM.insert_usuario;
DROP PROCEDURE DBM.insert_produto;
DROP PROCEDURE DBM.insert_movimentacao;
--Recomecar
DROP TABLE	DBM.Movimentacao
DROP TABLE	DBM.Pessoa
DROP TABLE	DBM.Pessoa_fisica
DROP TABLE	DBM.Pessoa_juridica
DROP TABLE	DBM.Produtos
DROP TABLE	DBM.Usuario



