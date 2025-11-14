CREATE TABLE CLIENTES(
    codCliente VARCHAR(15) PRIMARY KEY,
    dni VARCHAR(9) NOT NULL UNIQUE,
    nombre VARCHAR(20) NOT NULL,
    direccion VARCHAR(30) NOT NULL,
    tipoCliente VARCHAR(1) CHECK (tipoCliente IN ('A', 'B', 'C')) NOT NULL,
    comunidadAutonoma VARCHAR(30) NOT NULL
);

CREATE TABLE PRODUCTORES(
    codProductor VARCHAR(15) PRIMARY KEY,
    dni VARCHAR(9) NOT NULL UNIQUE,
    nombre VARCHAR(20) NOT NULL,
    direccion VARCHAR(30) NOT NULL
);

CREATE TABLE VINOS(
    codVino VARCHAR(15) PRIMARY KEY,
    codProductor VARCHAR(15) NOT NULL,
    marca VARCHAR(20) NOT NULL,
    anioCosecha DATE NOT NULL,
    denominacionOrigen VARCHAR(30) NOT NULL,
    graduacion DOUBLE NOT NULL,
    viniedoProcedencia VARCHAR(30) NOT NULL,
    comunidadAutonoma VARCHAR(30) NOT NULL,
    cantidadProducida INTEGER NOT NULL CHECK (cantidadProducidad>=0),
    cantidadStock INTEGER NOT NULL CHECK (cantidadStock>=0 AND cantidadStock <= cantidadProducida),
    CONSTRAINT fk_productor FOREIGN KEY (codProductor)
        REFERENCES PRODUCTORES(codProductor)
);