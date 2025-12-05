CREATE TABLE CLIENTES(
    codCliente          VARCHAR(10) PRIMARY KEY,
    DNI                 VARCHAR(9) NOT NULL,
    nombre              VARCHAR(100) NOT NULL,
    direccion           VARCHAR(200) NOT NULL,
    tipoCliente         VARCHAR(1) CHECK (tipoCliente IN ('A', 'B', 'C')) NOT NULL,
    comunidadAutonoma   VARCHAR(30) NOT NULL,

    CONSTRAINT uq_cliente_dni UNIQUE (DNI)
);

CREATE TABLE SUCURSALES (
    codSucursal         VARCHAR(10) PRIMARY KEY,
    nombre              VARCHAR(100) NOT NULL,
    ciudad              VARCHAR(50) NOT NULL,
    comunidadAutonoma   VARCHAR(30) NOT NULL,
    director            VARCHAR(10),
    codCliente          VARCHAR(10),

    CONSTRAINT uq_sucursales_director UNIQUE (director)  -- R4
    CONSTRAINT fk_sucursal_cliente FOREIGN KEY (codCliente)
        REFERENCES CLIENTES(codCliente) 
);

CREATE TABLE EMPLEADOS (
    codEmpleado             VARCHAR(10) PRIMARY KEY,
    DNI                     VARCHAR(9) NOT NULL,
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
    codProductor        VARCHAR(10) PRIMARY KEY,
    DNI                 VARCHAR(9) NOT NULL,
    nombre              VARCHAR(100) NOT NULL,
    direccion           VARCHAR(200) NOT NULL,

    CONSTRAINT uq_productores_dni UNIQUE (DNI)
);

CREATE TABLE VINOS(
    codVino             VARCHAR(10) PRIMARY KEY,
    codProductor        VARCHAR(10) NOT NULL,
    marca               VARCHAR(20) NOT NULL,
    anioCosecha         DATE NOT NULL,
    denominacionOrigen  VARCHAR(30) NOT NULL,
    graduacion          DOUBLE NOT NULL,
    viniedoProcedencia  VARCHAR(30) NOT NULL,
    comunidadAutonoma   VARCHAR(30) NOT NULL,
    cantidadProducida   INTEGER NOT NULL CHECK (cantidadProducidad>=0),
    cantidadStock       INTEGER NOT NULL,

    CONSTRAINT fk_productor FOREIGN KEY (codProductor)
        REFERENCES PRODUCTORES(codProductor)
    CONSTRAINT chk_stock CHECK (cantidadStock >= 0 AND cantidadStock <= cantidadProducida) -- R14
);

CREATE TABLE SUMINISTRO (
    codSucursal         VARCHAR(10),
    codVino             VARCHAR(10),
    fechaPedido         DATE,
    cantidadSolicitada  INT NOT NULL,

    CONSTRAINT pk_suministro PRIMARY KEY (codSucursal, codVino, fechaPedido), -- R2
    CONSTRAINT fk_suministro_sucursal FOREIGN KEY (codSucursal)
        REFERENCES SUCURSALES(codSucursal), -- R2
    CONSTRAINT fk_suministro_vino FOREIGN KEY (codVino)
        REFERENCES VINOS(codVino) -- R11
);

CREATE TABLE PEDIDO (
    codSucursalSolicitante  VARCHAR(10),
    codSucursalSolicitada   VARCHAR(10),
    codVino                 VARCHAR(10),
    fechaPedido             DATE,
    cantidadPedida          INT NOT NULL,

    CONSTRAINT pk_pedido PRIMARY KEY (codSucursalSolicitante, codSucursalSolicitada, codVino, fechaPedido),
    CONSTRAINT fk_pedido_solicitante FOREIGN KEY (codSucursalSolicitante)
        REFERENCES SUCURSALES(codSucursal), -- R2
    CONSTRAINT fk_pedido_solicitada FOREIGN KEY (codSucursalSolicitada)
        REFERENCES SUCURSALES(codSucursal), -- R2
    CONSTRAINT fk_pedido_vino FOREIGN KEY (codVino)
        REFERENCES VINOS(codVino) -- R2
);

CREATE TABLE SOLICITUD {
    codVino                 VARCHAR(10),
    codCliente              VARCHAR(10),
    codSucursal             VARCHAR(10),
    fechaSolicitud             DATE,
    cantidadSolicitada      INT NOT NULL,

    CONSTRAINT pk_solicita PRIMARY KEY (codVino, codSucursal, codCliente, fechaSolicitud),
    CONSTRAINT fk_solicitud_vino FOREIGN KEY (codVino)
        REFERENCES VINOS(codVino) -- R2
    CONSTRAINT fk_solicita_sucursal FOREIGN KEY (codSucursal)
        REFERENCES SUCURSALES(codSucursal), -- R2
    CONSTRAINT fk_solicita_cliente FOREIGN KEY (codCliente)
        REFERENCES SUCURSALES(codCliente), -- R2
};

ALTER TABLE SUCURSALES
    ADD CONSTRAINT fk_sucursales_director FOREIGN KEY (director)
        REFERENCES EMPLEADOS(codEmpleado); -- R3


CREATE TABLE CONTROL_STOCK (
    codSucursal         VARCHAR(10) NOT NULL,
    codVino             VARCHAR(10) NOT NULL,
    totalSolicitadoCli  INT DEFAULT 0, -- Límite máximo
    totalPedidoSuc      INT DEFAULT 0, -- Consumo actual

    CONSTRAINT pk_control PRIMARY KEY (codSucursal, codVino),
    CONSTRAINT fk_control_suc FOREIGN KEY (codSucursal) REFERENCES SUCURSALES(codSucursal),
    CONSTRAINT fk_control_vin FOREIGN KEY (codVino) REFERENCES VINOS(codVino)
);

CREATE TABLE CONTROL_FECHAS_PEDIDOS{
    codSucursalSolicitante  VARCHAR(10),
    codSucursalSolicitada   VARCHAR(10),
    codVino                 VARCHAR(10),
    ultimaFechaPedido       DATE,

    CONSTRAINT pk_control_fecha PRIMARY KEY (codSucursalSolicitante, codSucursalSolicitada, codVino),
};
