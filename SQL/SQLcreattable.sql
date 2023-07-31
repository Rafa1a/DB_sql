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
CONSTRAINT PK_Pessoa_fisica PRIMARY KEY (id_pessoa),
CONSTRAINT FK_Pessoa_f		FOREIGN KEY (id_pessoa)
REFERENCES DBM.Pessoa
);
GO
CREATE TABLE DBM.Pessoa_juridica
(id_cnpj int not null,
id_pessoa int not null,
CONSTRAINT PK_Pessoa_juridica PRIMARY KEY (id_pessoa),
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
--Recomecar
DROP TABLE	DBM.Movimentacao
DROP TABLE	DBM.Pessoa
DROP TABLE	DBM.Pessoa_fisica
DROP TABLE	DBM.Pessoa_juridica
DROP TABLE	DBM.Produtos
DROP TABLE	DBM.Usuario



