CREATE TABLE CLIENTES(
    codCliente INTEGER PRIMARY KEY,
    dni VARCHAR(9),
    nombre VARCHAR(20),
    direccion VARCHAR(30),
    tipoCliente VARCHAR(1) CHECK (tipoCliente IN ('A', 'B', 'C')),
    comunidadAutonoma VARCHAR(30)
);





CREATE TABLE SUCURSAL (
    codSucursal INTEGER PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    comunidadAutonoma VARCHAR(30) NOT NULL,
    director VARCHAR(10),
    FOREIGN KEY (codCliente) REFERENCES CLIENTES(codCliente),

    CONSTRAINT uq_sucursal_director UNIQUE (director)  -- R4
);

CREATE TABLE EMPLEADO (
    codEmpleado             VARCHAR(10) PRIMARY KEY,
    DNI                     VARCHAR(15) NOT NULL,
    nombre                  VARCHAR(100) NOT NULL,
    direccion               VARCHAR(200),
    codSucursal             VARCHAR(10) NOT NULL, -- R5
    fechaComienzoContrato   DATE NOT NULL,
    salario                 DECIMAL(10, 2) NOT NULL,

    CONSTRAINT uq_empleado_dni UNIQUE (DNI), -- R1
    CONSTRAINT fk_empleado_sucursal FOREIGN KEY (codSucursal) 
        REFERENCES SUCURSAL(codSucursal) -- R7
);












/* AL FINAL de la creacion de tablas */
ALTER TABLE SUCURSAL
    ADD CONSTRAINT fk_sucursal_director FOREIGN KEY (director)
        REFERENCES EMPLEADO(codEmpleado); -- R3