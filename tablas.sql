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