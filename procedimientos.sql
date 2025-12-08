/* Practica 4: actualizacion (procedimeintos)
*/

CREATE OR REPLACE FUNCTION get_nodo_destino(p_ca IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
    IF p_ca IN ('Castilla-León', 'Castilla-La Mancha', 'Aragón', 'Madrid', 'La Rioja') THEN 
        RETURN 'perro1';
    ELSIF p_ca IN ('Cataluña', 'Baleares', 'País Valenciano', 'Murcia') THEN 
        RETURN 'perro2';
    ELSIF p_ca IN ('Galicia', 'Asturias', 'Cantabria', 'País Vasco', 'Navarra') THEN 
        RETURN 'perro3';
    ELSIF p_ca IN ('Andalucía', 'Extremadura', 'Canarias', 'Ceuta', 'Melilla') THEN 
        RETURN 'perro4';
    ELSE 
        RETURN 'ERROR';
    END IF;
END;
/
/* === ALTAS === */

CREATE OR REPLACE PROCEDURE alta_cliente (
    p_codCliente VARCHAR2, 
    p_dni VARCHAR2, 
    p_nombre VARCHAR2, 
    p_direccion VARCHAR2, 
    p_tipo VARCHAR2, 
    p_ca VARCHAR2
) IS
    v_nodo VARCHAR2(10);
BEGIN
    -- Calculo de a qué nodo va
    v_nodo := get_nodo_destino(p_ca);

    -- Insertar en el sitio correcto
    IF v_nodo = 'perro1' THEN
        INSERT INTO perro1.CLIENTES VALUES (p_codCliente, p_dni, p_nombre, p_direccion, p_tipo, p_ca);
    ELSIF v_nodo = 'perro2' THEN
        INSERT INTO perro2.CLIENTES VALUES (p_codCliente, p_dni, p_nombre, p_direccion, p_tipo, p_ca);
    ELSIF v_nodo = 'perro3' THEN
        INSERT INTO perro3.CLIENTES VALUES (p_codCliente, p_dni, p_nombre, p_direccion, p_tipo, p_ca);
    ELSIF v_nodo = 'perro4' THEN
        INSERT INTO perro4.CLIENTES VALUES (p_codCliente, p_dni, p_nombre, p_direccion, p_tipo, p_ca);
    ELSE
        RAISE_APPLICATION_ERROR(-20301, 'Error: Comunidad Autónoma desconocida.');
    END IF;
    
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20302, 'Error: El cliente ya existe.');
END;
/

CREATE OR REPLACE PROCEDURE alta_empleado (
    p_codEmpleado VARCHAR2, 
    p_dni VARCHAR2, 
    p_nombre VARCHAR2, 
    p_direccion VARCHAR2, 
    p_codSucursal VARCHAR2, 
    p_fechaInicio DATE, 
    p_salario NUMBER
) IS
    v_ca_sucursal VARCHAR2(50);
    v_nodo        VARCHAR2(10);
BEGIN
    -- Buscamos la CCAA de la sucursal en la VISTA GLOBAL
    BEGIN
        SELECT comunidadAutonoma INTO v_ca_sucursal
        FROM V_SUCURSALES
        WHERE codSucursal = p_codSucursal;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20101, 'Error: La sucursal destino no existe.');
    END;

    -- Calculamos el nodo
    v_nodo := get_nodo_destino(v_ca_sucursal);

    -- Insertamos el empleado en el mismo nodo que su sucursal
    IF v_nodo = 'perro1' THEN
        INSERT INTO perro1.EMPLEADOS VALUES (p_codEmpleado, p_dni, p_nombre, p_direccion, p_codSucursal, p_fechaInicio, p_salario);
    ELSIF v_nodo = 'perro2' THEN
        INSERT INTO perro2.EMPLEADOS VALUES (p_codEmpleado, p_dni, p_nombre, p_direccion, p_codSucursal, p_fechaInicio, p_salario);
    ELSIF v_nodo = 'perro3' THEN
        INSERT INTO perro3.EMPLEADOS VALUES (p_codEmpleado, p_dni, p_nombre, p_direccion, p_codSucursal, p_fechaInicio, p_salario);
    ELSIF v_nodo = 'perro4' THEN
        INSERT INTO perro4.EMPLEADOS VALUES (p_codEmpleado, p_dni, p_nombre, p_direccion, p_codSucursal, p_fechaInicio, p_salario);
    END IF;

    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE alta_actualiza_solicitud (
    p_codVino VARCHAR2, 
    p_codSucursal VARCHAR2, 
    p_codCliente VARCHAR2,
    p_fecha DATE, 
    p_cantidad NUMBER
) IS
    v_ca_sucursal VARCHAR2(50);
    v_nodo        VARCHAR2(10);
    v_existe      NUMBER;
BEGIN
    -- Buscamos dónde está la sucursal (porque SOLICITUD se guarda con la sucursal)
    BEGIN
        SELECT comunidadAutonoma INTO v_ca_sucursal
        FROM V_SUCURSALES WHERE codSucursal = p_codSucursal;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20401, 'Sucursal no encontrada');
    END;
    
    v_nodo := get_nodo_destino(v_ca_sucursal);

    -- Verificamos si ya existe la solicitud en la VISTA GLOBAL
    SELECT COUNT(*) INTO v_existe
    FROM V_SOLICITUD
    WHERE codVino = p_codVino AND codSucursal = p_codSucursal 
      AND codCliente = p_codCliente AND fechaSolicitud = p_fecha;

    -- Lógica UPDATE o INSERT direccionada al nodo correcto
    IF v_existe > 0 THEN
        -- UPDATE 
        IF v_nodo = 'perro1' THEN
            UPDATE perro1.SOLICITUD SET cantidadSolicitada = cantidadSolicitada + p_cantidad
            WHERE codVino = p_codVino AND codSucursal = p_codSucursal AND codCliente = p_codCliente AND fechaSolicitud = p_fecha;
        ELSIF v_nodo = 'perro2' THEN
            UPDATE perro2.SOLICITUD SET cantidadSolicitada = cantidadSolicitada + p_cantidad
            WHERE codVino = p_codVino AND codSucursal = p_codSucursal AND codCliente = p_codCliente AND fechaSolicitud = p_fecha;
        ELSIF v_nodo = 'perro3' THEN
             UPDATE perro3.SOLICITUD SET cantidadSolicitada = cantidadSolicitada + p_cantidad
             WHERE codVino = p_codVino AND codSucursal = p_codSucursal AND codCliente = p_codCliente AND fechaSolicitud = p_fecha;
        ELSIF v_nodo = 'perro4' THEN
             UPDATE perro4.SOLICITUD SET cantidadSolicitada = cantidadSolicitada + p_cantidad
             WHERE codVino = p_codVino AND codSucursal = p_codSucursal AND codCliente = p_codCliente AND fechaSolicitud = p_fecha;
        END IF;
    ELSE
        -- INSERT
        IF v_nodo = 'perro1' THEN INSERT INTO perro1.SOLICITUD VALUES (p_codVino, p_codCliente, p_codSucursal, p_fecha, p_cantidad);
        ELSIF v_nodo = 'perro2' THEN INSERT INTO perro2.SOLICITUD VALUES (p_codVino, p_codCliente, p_codSucursal, p_fecha, p_cantidad);
        ELSIF v_nodo = 'perro3' THEN INSERT INTO perro3.SOLICITUD VALUES (p_codVino, p_codCliente, p_codSucursal, p_fecha, p_cantidad);
        ELSIF v_nodo = 'perro4' THEN INSERT INTO perro4.SOLICITUD VALUES (p_codVino, p_codCliente, p_codSucursal, p_fecha, p_cantidad);
        END IF;
    END IF;
    
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE alta_pedido (
    p_suc_solicitante VARCHAR2, 
    p_suc_solicitada VARCHAR2, 
    p_codVino VARCHAR2, 
    p_fecha DATE, 
    p_cantidad NUMBER
) IS
    v_ca_solicitante VARCHAR2(50);
    v_nodo           VARCHAR2(10);
BEGIN
    -- Buscamos dónde está la sucursal solicitante (origen del pedido)
    BEGIN
        SELECT comunidadAutonoma INTO v_ca_solicitante
        FROM V_SUCURSALES WHERE codSucursal = p_suc_solicitante;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20501, 'Sucursal solicitante no encontrada');
    END;

    v_nodo := get_nodo_destino(v_ca_solicitante);

    -- Insertamos (Deben saltar los triggers asociados a las restricciones R18, R19, R20, R21)
    IF v_nodo = 'perro1' THEN
        INSERT INTO perro1.PEDIDO VALUES (p_suc_solicitante, p_suc_solicitada, p_codVino, p_fecha, p_cantidad);
    ELSIF v_nodo = 'perro2' THEN
        INSERT INTO perro2.PEDIDO VALUES (p_suc_solicitante, p_suc_solicitada, p_codVino, p_fecha, p_cantidad);
    ELSIF v_nodo = 'perro3' THEN
        INSERT INTO perro3.PEDIDO VALUES (p_suc_solicitante, p_suc_solicitada, p_codVino, p_fecha, p_cantidad);
    ELSIF v_nodo = 'perro4' THEN
        INSERT INTO perro4.PEDIDO VALUES (p_suc_solicitante, p_suc_solicitada, p_codVino, p_fecha, p_cantidad);
    END IF;

    COMMIT;
EXCEPTION
    -- Capturamos los errores de nuestros triggers
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20500, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE alta_productor (
    p_cod VARCHAR2, 
    p_dni VARCHAR2, 
    p_nom VARCHAR2, 
    p_dir VARCHAR2
) IS
BEGIN
    INSERT INTO perro1.PRODUCTORES VALUES (p_cod, p_dni, p_nom, p_dir);
    INSERT INTO perro2.PRODUCTORES VALUES (p_cod, p_dni, p_nom, p_dir);
    INSERT INTO perro3.PRODUCTORES VALUES (p_cod, p_dni, p_nom, p_dir);
    INSERT INTO perro4.PRODUCTORES VALUES (p_cod, p_dni, p_nom, p_dir);
    
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE alta_sucursal (
    p_codSucursal VARCHAR2, 
    p_nombre VARCHAR2, 
    p_ciudad VARCHAR2,
    p_comunidadAutonoma VARCHAR2, 
    p_codEmpleado VARCHAR2 DEFAULT NULL
) IS
    v_count NUMBER;
    v_nodo  VARCHAR2(20);
BEGIN
    SELECT count(*) INTO v_count FROM SUCURSALES
    WHERE codSucursal = p_codSucursal;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Ya existe una sucursal con ese codigo ' || p_codSucursal);
    END IF;

    IF p_codEmpleado IS NOT NULL THEN
        SELECT count(*) INTO v_count FROM EMPLEADOS
        WHERE codEmpleado = p_codEmpleado;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20030, 'El empleado ' || p_codEmpleado || ' no está registrado');
        END IF;
    END IF;

    -- Calculamos el nodo
    v_nodo := get_nodo_destino(p_comunidadAutonoma);

 -- Insertamos la sucursal en el mismo nodo 
    IF v_nodo = 'perro1' THEN
        INSERT INTO perro1.SUCURSALES VALUES (p_codSucursal, p_nombre, p_ciudad, p_comunidadAutonoma, p_codEmpleado, NULL);
    ELSIF v_nodo = 'perro2' THEN
        INSERT INTO perro2.SUCURSALES VALUES (p_codSucursal, p_nombre, p_ciudad, p_comunidadAutonoma, p_codEmpleado, NULL);
    ELSIF v_nodo = 'perro3' THEN
        INSERT INTO perro3.SUCURSALES VALUES (p_codSucursal, p_nombre, p_ciudad, p_comunidadAutonoma, p_codEmpleado, NULL);
    ELSIF v_nodo = 'perro4' THEN
        INSERT INTO perro4.SUCURSALES VALUES (p_codSucursal, p_nombre, p_ciudad, p_comunidadAutonoma, p_codEmpleado, NULL);
    END IF;

    COMMIT;


END;
/

CREATE OR REPLACE PROCEDURE alta_vino (
    p_codVino VARCHAR2,
    p_marca VARCHAR2, 
    p_anioCosecha DATE,
    p_denominacionOrigen VARCHAR2 DEFAULT NULL, 
    p_graduacion DOUBLE, 
    p_viniedoProcedencia VARCHAR2,
    p_comunidadAutonoma VARCHAR2, 
    p_cantidadProducida INTEGER, 
    p_codProductor VARCHAR2
) IS
    v_count NUMBER;
    v_nodo  VARCHAR2(20);
BEGIN
    SELECT count(*) INTO v_count FROM VINOS
    WHERE codVino = p_codVino;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Ya existe un vino con ese codigo ' || p_codVino);
    END IF;

    SELECT count(*) INTO v_count FROM PRODUCTORES
    WHERE codProductor = p_codProductor;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'No tenemos a ese productor registrado ' || p_codProductor);
    END IF;

    IF p_cantidadProducidad <= 0 THEN
            RAISE_APPLICATION_ERROR(-20030, 'No se puede registrar un vino sin producción inicial ' || p_cantidadProducida);
    END IF;

    IF p_graduacion < 0 THEN
            RAISE_APPLICATION_ERROR(-20030, 'La graduacion de un vino no puede ser negativa ' || p_graduacion);
    END IF;

    IF p_anioCosecha > SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20030, 'El año de cosecha no puede ser del futuro ' || p_anioCosecha);
    END IF;


    v_nodo := get_nodo_destino(p_comunidadAutonoma);

    IF v_nodo = 'perro1' THEN
        INSERT INTO perro1.VINOS VALUES (p_codVino, p_codProductor, p_marca, p_anioCosecha, p_denominacionOrigen, p_graduacion, 
                                        p_viniedoProcedencia, p_comunidadAutonoma, p_cantidadProducida, p_cantidadProducida);
    ELSIF v_nodo = 'perro2' THEN
        INSERT INTO perro2.VINOS VALUES (p_codVino, p_codProductor, p_marca, p_anioCosecha, p_denominacionOrigen, p_graduacion, 
                                        p_viniedoProcedencia, p_comunidadAutonoma, p_cantidadProducida, p_cantidadProducida);
    ELSIF v_nodo = 'perro3' THEN
        INSERT INTO perro3.VINOS VALUES (p_codVino, p_codProductor, p_marca, p_anioCosecha, p_denominacionOrigen, p_graduacion, 
                                        p_viniedoProcedencia, p_comunidadAutonoma, p_cantidadProducida, p_cantidadProducida);
    ELSIF v_nodo = 'perro4' THEN
        INSERT INTO perro4.VINOS VALUES (p_codVino, p_codProductor, p_marca, p_anioCosecha, p_denominacionOrigen, p_graduacion, 
                                        p_viniedoProcedencia, p_comunidadAutonoma, p_cantidadProducida, p_cantidadProducida);
    END IF;

    COMMIT;

    
END;
/


/* === BAJAS === */
CREATE OR REPLACE PROCEDURE baja_empleado (
    p_codEmpleado VARCHAR2
) IS
    v_codSucursal_trabajo VARCHAR2(10); -- Donde trabaja (para localizarlo)
    v_codSucursal_dirige  VARCHAR2(10); -- La que dirige (si es director)
    v_ca_sucursal         VARCHAR2(50);
    v_nodo_empleado       VARCHAR2(10);
    v_nodo_director       VARCHAR2(10);
BEGIN
    -- LOCALIZAR AL EMPLEADO (sucursal donde trabaja)
    BEGIN
        SELECT codSucursal INTO v_codSucursal_trabajo
        FROM V_EMPLEADOS
        WHERE codEmpleado = p_codEmpleado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Error: El empleado no existe.');
    END;

    -- CALCULAR NODO DEL EMPLEADO 
    SELECT comunidadAutonoma INTO v_ca_sucursal
    FROM V_SUCURSALES WHERE codSucursal = v_codSucursal_trabajo;
    
    v_nodo_empleado := get_nodo_destino(v_ca_sucursal);

    -- GESTIÓN DE DIRECTOR
    -- Buscamos en la vista global si su código aparece en la columna 'director'
    BEGIN
        SELECT codSucursal INTO v_codSucursal_dirige
        FROM V_SUCURSALES
        WHERE director = p_codEmpleado;
        
        -- Si encontramos algo, calculamos dónde está esa sucursal
        SELECT comunidadAutonoma INTO v_ca_sucursal
        FROM V_SUCURSALES WHERE codSucursal = v_codSucursal_dirige;
        
        v_nodo_director := get_nodo_destino(v_ca_sucursal);

        -- Ponemos a NULL el campo director en el nodo correspondiente
        IF v_nodo_director = 'perro1' THEN
            UPDATE perro1.SUCURSALES SET director = NULL WHERE director = p_codEmpleado;
        ELSIF v_nodo_director = 'perro2' THEN
            UPDATE perro2.SUCURSALES SET director = NULL WHERE director = p_codEmpleado;
        ELSIF v_nodo_director = 'perro3' THEN
            UPDATE perro3.SUCURSALES SET director = NULL WHERE director = p_codEmpleado;
        ELSIF v_nodo_director = 'perro4' THEN
            UPDATE perro4.SUCURSALES SET director = NULL WHERE director = p_codEmpleado;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- No es director, no hacemos nada y continuamos.
    END;

    -- BORRAR EMPLEADO 
    IF v_nodo_empleado = 'perro1' THEN
        DELETE FROM perro1.EMPLEADOS WHERE codEmpleado = p_codEmpleado;
    ELSIF v_nodo_empleado = 'perro2' THEN
        DELETE FROM perro2.EMPLEADOS WHERE codEmpleado = p_codEmpleado;
    ELSIF v_nodo_empleado = 'perro3' THEN
        DELETE FROM perro3.EMPLEADOS WHERE codEmpleado = p_codEmpleado;
    ELSIF v_nodo_empleado = 'perro4' THEN
        DELETE FROM perro4.EMPLEADOS WHERE codEmpleado = p_codEmpleado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20103, 'Error al dar de baja al empleado: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE baja_vino (
    p_codVino VARCHAR2
) IS
    v_nodo          VARCHAR2(20);
    v_cantidadStock INTEGER;
    v_comunidadAutonoma VARCHAR2(30);
BEGIN
    --LOCALIZAR VINO
    BEGIN
        SELECT cantidadStock, comunidadAutonoma INTO v_cantidadStock, v_comunidadAutonoma
        FROM V_VINOS
        WHERE codVino = p_codVino;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Error: El vino no existe.');
    END;

    IF v_cantidadStock > 0 THEN
            RAISE_APPLICATION_ERROR(-20103, 'Error: El vino no se puede eliminar pues queda stock.');
    END IF;


    v_nodo := get_nodo_destino(v_comunidadAutonoma);

    -- BORRAR VINO 
    IF v_nodo = 'perro1' THEN
        DELETE FROM perro1.VINOS WHERE codVino = p_codVino;
    ELSIF v_nodo = 'perro2' THEN
        DELETE FROM perro2.VINOS WHERE codVino = p_codVino;
    ELSIF v_nodo = 'perro3' THEN
        DELETE FROM perro3.VINOS WHERE codVino = p_codVino;
    ELSIF v_nodo = 'perro4' THEN
        DELETE FROM perro4.VINOS WHERE codVino = p_codVino;
    END IF;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20104,
            'Error interno: No se pudo eliminar el vino en el nodo correspondiente.');
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
        RAISE_APPLICATION_ERROR(-20105, 'Error al dar de baja el vino: ' || SQLERRM); 
END;
/







/* === MODIFICACIONES === */
CREATE OR REPLACE PROCEDURE modificar_salario (
    p_codEmpleado VARCHAR2, 
    p_nuevoSalario NUMBER
) IS
    v_codSucursal VARCHAR2(10);
    v_ca_sucursal VARCHAR2(50);
    v_nodo        VARCHAR2(10);
BEGIN
    -- LOCALIZAR AL EMPLEADO
    BEGIN
        SELECT codSucursal INTO v_codSucursal
        FROM V_EMPLEADOS
        WHERE codEmpleado = p_codEmpleado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Error: El empleado no existe.');
    END;

    -- CALCULAR NODO DESTINO
    SELECT comunidadAutonoma INTO v_ca_sucursal
    FROM V_SUCURSALES WHERE codSucursal = v_codSucursal;
    
    v_nodo := get_nodo_destino(v_ca_sucursal);

    -- EJECUTAR UPDATE (El Trigger asociado a R6 saltará aquí si se viola la regla)
    IF v_nodo = 'perro1' THEN
        UPDATE perro1.EMPLEADOS SET salario = p_nuevoSalario WHERE codEmpleado = p_codEmpleado;
    ELSIF v_nodo = 'perro2' THEN
        UPDATE perro2.EMPLEADOS SET salario = p_nuevoSalario WHERE codEmpleado = p_codEmpleado;
    ELSIF v_nodo = 'perro3' THEN
        UPDATE perro3.EMPLEADOS SET salario = p_nuevoSalario WHERE codEmpleado = p_codEmpleado;
    ELSIF v_nodo = 'perro4' THEN
        UPDATE perro4.EMPLEADOS SET salario = p_nuevoSalario WHERE codEmpleado = p_codEmpleado;
    END IF;

    -- Validar que se actualizó algo 
    IF SQL%ROWCOUNT = 0 THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20104, 'Error: No se pudo actualizar el salario (Fila no encontrada en el nodo esperado).');
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -20006 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Operación cancelada: El nuevo salario es inferior al actual.');
        ELSE
            RAISE;
        END IF;
END;
/


CREATE OR REPLACE PROCEDURE trasladar_empleado (
    p_codEmpleado VARCHAR2, 
    p_codSucursalNueva VARCHAR2,
    p_direccionNueva VARCHAR2 DEFAULT NULL
) IS
    v_codSucursal VARCHAR2(10);
    v_ca_sucursalNueva VARCHAR2(50);
    v_nodo        VARCHAR2(10);
    v_fechaInicio   DATE;
    v_sueldo        DECIMAL;
BEGIN
    -- LOCALIZAR AL EMPLEADO
    BEGIN
        SELECT codSucursal INTO v_codSucursal
        FROM V_EMPLEADOS
        WHERE codEmpleado = p_codEmpleado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Error: El empleado no existe.');
    END;

    -- LOCALIZAR NUEVA SUCURSAL
    BEGIN
        SELECT codSucursal INTO v_codSucursal
        FROM V_SUCURSALES
        WHERE codSucursal = p_codSucursalNueva;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Error: La nueva sucursal no existe.');
    END;


    -- CALCULAR NODO DESTINO
    SELECT comunidadAutonoma INTO v_ca_sucursalNueva
    FROM V_SUCURSALES WHERE codSucursal = p_codSucursalNueva;
    
    v_nodo := get_nodo_destino(v_ca_sucursalNueva);


    IF v_nodo = 'perro1' THEN
        UPDATE perro1.EMPLEADOS SET codSucursal = p_CodSucursalNueva, direccion = p_direccionNueva WHERE codEmpleado = p_codEmpleado;
    ELSIF v_nodo = 'perro2' THEN
        UPDATE perro2.EMPLEADOS SET codSucursal = p_CodSucursalNueva, direccion = p_direccionNueva WHERE codEmpleado = p_codEmpleado;
    ELSIF v_nodo = 'perro3' THEN
        UPDATE perro3.EMPLEADOS SET codSucursal = p_CodSucursalNueva, direccion = p_direccionNueva WHERE codEmpleado = p_codEmpleado;
    ELSIF v_nodo = 'perro4' THEN
        UPDATE perro4.EMPLEADOS SET codSucursal = p_CodSucursalNueva, direccion = p_direccionNueva WHERE codEmpleado = p_codEmpleado;
    END IF;

    -- Validar que se actualizó algo 
    IF SQL%ROWCOUNT = 0 THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20104, 'Error: No se pudo cambiar al empleado de sucursal.');
    END IF;

    COMMIT;

END;
/
