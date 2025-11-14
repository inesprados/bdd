CREATE TABLE CLIENTES(
    codCliente VARCHAR(15) PRIMARY KEY,
    dni VARCHAR(9) NOT NULL UNIQUE,
    nombre VARCHAR(20) NOT NULL,
    direccion VARCHAR(30) NOT NULL,
    tipoCliente VARCHAR(1) CHECK (tipoCliente IN ('A', 'B', 'C')) NOT NULL,
    comunidadAutonoma VARCHAR(30) NOT NULL
);

CREATE TABLE SUCURSALES (
    codSucursal INTEGER PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    comunidadAutonoma VARCHAR(30) NOT NULL,
    director VARCHAR(10),
    codCliente VARCHAR(15),

    CONSTRAINT uq_sucursales_director UNIQUE (director)  -- R4
    CONSTRAINT fk_sucursal_cliente FOREIGN KEY (codCliente)
        REFERENCES CLIENTES(codCliente) 
);

CREATE TABLE EMPLEADOS (
    codEmpleado             VARCHAR(10) PRIMARY KEY,
    DNI                     VARCHAR(15) NOT NULL,
    nombre                  VARCHAR(100) NOT NULL,
    direccion               VARCHAR(200),
    codSucursal             VARCHAR(10) NOT NULL, -- R5
    fechaComienzoContrato   DATE NOT NULL,
    salario                 DECIMAL(10, 2) NOT NULL,

    CONSTRAINT uq_empleado_dni UNIQUE (DNI), -- R1
    CONSTRAINT fk_empleado_sucursal FOREIGN KEY (codSucursal) 
        REFERENCES SUCURSALES(codSucursal) -- R7
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

    cantidadStock INTEGER NOT NULL,
    CONSTRAINT fk_productor FOREIGN KEY (codProductor)
        REFERENCES PRODUCTORES(codProductor)
    CONSTRAINT chk_stock CHECK (cantidadStock >= 0 AND cantidadStock <= cantidadProducida) -- R14
);

/* AL FINAL de la creacion de tablas */
ALTER TABLE SUCURSALES
    ADD CONSTRAINT fk_sucursales_director FOREIGN KEY (director)
        REFERENCES EMPLEADOS(codEmpleado); -- R3
