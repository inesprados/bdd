CREATE TABLE CLIENTES(
    codCliente INTEGER PRIMARY KEY,
    dni VARCHAR(9),
    nombre VARCHAR(20),
    direccion VARCHAR(30),
    tipoCliente VARCHAR(1) CHECK (tipoCliente IN ('A', 'B', 'C')),
    comunidadAutonoma VARCHAR(30)
);
