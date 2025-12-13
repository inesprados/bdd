-- Funcion auxiliar para obtener la delegacion a partir de la comunidad autonoma
/* Mapeo de la comunidadAutonoma a delegación*/

CREATE OR REPLACE FUNCTION get_delegacion(p_ca IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
    IF p_ca IN ('Castilla-León', 'Castilla-La Mancha', 'Aragón', 'Madrid', 'La Rioja') THEN
        RETURN 'CENTRO';
    ELSIF p_ca IN ('Cataluña', 'Baleares', 'País Valenciano', 'Murcia') THEN
        RETURN 'LEVANTE';
    ELSIF p_ca IN ('Galicia', 'Asturias', 'Cantabria', 'País Vasco', 'Navarra') THEN
        RETURN 'NORTE';
    ELSIF p_ca IN ('Andalucía', 'Extremadura', 'Canarias', 'Ceuta', 'Melilla') THEN
        RETURN 'SUR';
    ELSE
        RETURN 'INVALIDA';
    END IF;
END;
/


-- R3: El director de una sucursal es empleado de la compañía (no tiene que ser empleado de la sucursal)
CREATE OR REPLACE TRIGGER trg_check_director_global
BEFORE INSERT OR UPDATE OF director ON SUCURSALES
FOR EACH ROW
WHEN (NEW.director IS NOT NULL)
DECLARE
    v_existe NUMBER;
BEGIN
    -- Buscamos al empleado en la VISTA GLOBAL (Cualquier nodo)
    SELECT COUNT(*) INTO v_existe
    FROM V_EMPLEADOS
    WHERE codEmpleado = :NEW.director;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20040, 'Error: El empleado ' || :NEW.director || ' no existe en ninguna delegación.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_ControlarSalario
BEFORE UPDATE OF salario ON EMPLEADOS
FOR EACH ROW
BEGIN
    IF :NEW.salario < :OLD.salario THEN
        RAISE_APPLICATION_ERROR(-20006, 'No se puedo disminuir el salario de un empleado');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_check_delegacion_suministro
BEFORE INSERT OR UPDATE ON SOLICITUD
FOR EACH ROW
DECLARE
    v_ca_cliente    CLIENTES.comunidadAutonoma%TYPE;
    v_ca_sucursal   SUCURSALES.comunidadAutonoma%TYPE;
    v_del_cliente   VARCHAR2(10);
    v_del_sucursal  VARCHAR2(10);

BEGIN
    -- CCAA del Cliente
    SELECT comunidadAutonoma INTO v_ca_cliente
    FROM V_CLIENTES
    WHERE codCliente = :NEW.codCliente;

    -- CCAA de la Sucursal
    SELECT comunidadAutonoma INTO v_ca_sucursal
    FROM V_SUCURSALES
    WHERE codSucursal = :NEW.codSucursal;

    -- Mapeo
    v_del_cliente  := get_delegacion(v_ca_cliente);
    v_del_sucursal := get_delegacion(v_ca_sucursal);

    -- Validacion de delegacion
    IF v_del_cliente != v_del_sucursal THEN
        RAISE_APPLICATION_ERROR(-20009, 'Error: El cliente (' || v_ca_cliente || ' - Del: ' || v_del_cliente || 
                                    ') no puede operar con la sucursal (' || v_ca_sucursal || ' - Del: ' || v_del_sucursal || ').');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error R9: El cliente ' || :NEW.codCliente || ' o la sucursal ' || :NEW.codSucursal || ' no existen.');
END;
/

-- Disparador para verificar que la fecha de un suministro sea igual o posterior a la del ultimo suministro
CREATE OR REPLACE TRIGGER trg_check_fecha_suministro
BEFORE INSERT OR UPDATE ON SOLICITUD
FOR EACH ROW
DECLARE
    v_ultima_fecha   DATE;
BEGIN
    -- Última fecha de suministro para este cliente
    SELECT MAX(fechaSolicitud) INTO v_ultima_fecha
    FROM SOLICITUD
    WHERE codCliente = :NEW.codCliente;

    -- Si el cliente ya tiene suministros, validamos la fecha
    IF v_ultima_fecha IS NOT NULL THEN
        IF :NEW.fechaSolicitud < v_ultima_fecha THEN
            RAISE_APPLICATION_ERROR(-20010, 'Error: La fecha del nuevo suministro (' || 
                                    TO_CHAR(:NEW.fechaSolicitud, 'DD-MM-YYYY') || 
                                    ') no puede ser anterior al último suministro existente (' || 
                                    TO_CHAR(v_ultima_fecha, 'DD-MM-YYYY') || ').');
        END IF;
    END IF;
    /*
     En el caso v_ultima_fecha sea NULL (quiere decir que es su primer suministro), 
     se permite la inserción.
    */
END;
/

-- Disparador para comprobar que no haya solicitudes de clientes pendientes para este vino
CREATE OR REPLACE TRIGGER trg_borrar_vino
BEFORE DELETE ON VINOS
FOR EACH ROW
DECLARE
    v_total_solicitud  NUMBER := 0;
    v_total_suministro NUMBER := 0;
    v_total_pedido     NUMBER := 0;
BEGIN
    --Verificar si clientes lo han solicitado
    SELECT COUNT(*) INTO v_total_solicitud
    FROM SOLICITUD
    WHERE codVino = :OLD.codVino;

    -- Verificar si hay stock/suministros en sucursales
    SELECT COUNT(*) INTO v_total_suministro
    FROM SUMINISTRO
    WHERE codVino = :OLD.codVino;

    -- Verificar si hay pedidos entre sucursales
    SELECT COUNT(*) INTO v_total_pedido
    FROM PEDIDO
    WHERE codVino = :OLD.codVino;

    IF (v_total_solicitud + v_total_suministro + v_total_pedido) > 0 THEN
        RAISE_APPLICATION_ERROR(-20015, 'Error: No se puede borrar el vino. Existen registros asociados en Solicitudes (' || v_total_solicitud || '), Suministros (' || v_total_suministro || ') o Pedidos (' || v_total_pedido || ').');
    END IF;
END;
/

-- Disparador para poder eliminar un productor siempre que su produccion de vinos sea cero
CREATE OR REPLACE TRIGGER trg_validarEliminacionProductor
BEFORE DELETE ON PRODUCTORES
FOR EACH ROW
DECLARE
    cnt_suministro number;
BEGIN
    SELECT COUNT(*) INTO cnt_suministro 
    FROM SUMINISTRO WHERE codVino IN(
        SELECT codVino
        FROM VINOS
        WHERE codProductor = :OLD.codProductor
    );
    IF cnt_suministro > 0 THEN
        RAISE_APPLICATION_ERROR(-20016, 'No se puede eliminar a este productor');
    END IF;
END;
/

-- Disparador para que una sucursal no pueda hacer pedidos a otra de la misma delegación
CREATE OR REPLACE TRIGGER trg_pedido_delegacion
BEFORE INSERT OR UPDATE ON PEDIDO
FOR EACH ROW
DECLARE
    v_ca_solicitante SUCURSALES.comunidadAutonoma%TYPE;
    v_ca_solicitada  SUCURSALES.comunidadAutonoma%TYPE;
BEGIN
    SELECT comunidadAutonoma INTO v_ca_solicitante 
    FROM V_SUCURSALES WHERE codSucursal = :NEW.codSucursalSolicitante;

    SELECT comunidadAutonoma INTO v_ca_solicitada 
    FROM V_SUCURSALES WHERE codSucursal = :NEW.codSucursalSolicitada;

    -- DISTINTAS delegaciones
    IF get_delegacion(v_ca_solicitante) = get_delegacion(v_ca_solicitada) THEN
        RAISE_APPLICATION_ERROR(-20017, 'Error: No se pueden hacer pedidos dentro de la misma delegación.');
    END IF;
END;
/



--Disparador para que una sucursal solicite a cualquier sucursal de la delegación correspondiente del vino
CREATE OR REPLACE TRIGGER trg_controlarPedidosEntreSucursales
BEFORE INSERT ON PEDIDO
FOR EACH ROW
DECLARE
    ca_solicitante  SUCURSALES.comunidadAutonoma%TYPE;
    ca_solicitada   SUCURSALES.comunidadAutonoma%TYPE;
    ca_vino         VINOS.comunidadAutonoma%TYPE;

BEGIN

    --Primero obtenemos la comunidad del solicitante
    SELECT comunidadAutonoma INTO ca_solicitante
    FROM V_SUCURSALES 
    WHERE codSucursal = :NEW.codSucursalSolicitante;

    -- Obtenemos la comunidad autonoma de la sucursal solicitada
    SELECT comunidadAutonoma INTO ca_solicitada
    FROM V_SUCURSALES 
    WHERE codSucursal = :NEW.codSucursalSolicitada;

    --Obtenemos la comunidad autonoma del vino
    SELECT comunidadAutonoma INTO ca_vino
    FROM V_VINOS 
    WHERE codVino = :NEW.codVino;

    --CASO 1: el vino pertenece a la misma delegacion
    IF get_delegacion(ca_solicitante) = get_delegacion(ca_vino) THEN
            RAISE_APPLICATION_ERROR(-20019, 'No hace falta pedirlo a otra sucursal, tú puedes administrarlo');
    END IF ;

    --Averiguamos la delegación que puede distribuir el vino
    IF get_delegacion(ca_solicitada) != get_delegacion(ca_vino) THEN
            RAISE_APPLICATION_ERROR(-20019, 'La sucursal a la que intenta solicitar el vino no puede distribuirlo');
    END IF;
END;
/


/* 
    Disparadores asociados a la restriccion 18 (no superar el total solicitado por los clientes)
*/

-- Disparador para actualizar el total solicitado y pedido.
CREATE OR REPLACE TRIGGER trg_actualizar_techo
AFTER INSERT OR UPDATE ON SOLICITUD
FOR EACH ROW
BEGIN
    -- Intentamos actualizar sumando la cantidad nueva
    UPDATE CONTROL_STOCK
    SET totalSolicitadoCli = totalSolicitadoCli + :NEW.cantidadSolicitada
    WHERE codSucursal = :NEW.codSucursal 
      AND codVino = :NEW.codVino;

    -- No encontramos nada (porque es el primer dato), insertamos la fila
    IF SQL%ROWCOUNT = 0 THEN
        INSERT INTO CONTROL_STOCK (codSucursal, codVino, totalSolicitadoCli, totalPedidoSuc)
        VALUES (:NEW.codSucursal, :NEW.codVino, :NEW.cantidadSolicitada, 0);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_validacion_pedido
BEFORE INSERT OR UPDATE ON PEDIDO
FOR EACH ROW
DECLARE
    v_techo_maximo   NUMBER := 0;
    v_consumo_actual NUMBER := 0;
BEGIN
    -- Obtenemos los contadores de la tabla auxiliar
    BEGIN
        SELECT totalSolicitadoCli, totalPedidoSuc
            INTO v_techo_maximo, v_consumo_actual
        FROM CONTROL_STOCK
            WHERE codSucursal = :NEW.codSucursalSolicitante 
                AND codVino = :NEW.codVino;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si no hay registro en CONTROL_STOCK, es que NO hay solicitudes previas.
            -- Por tanto, el techo es 0.
            v_techo_maximo := 0;
            v_consumo_actual := 0;
    END;

    -- Verificamos que: Lo acumulado + lo nuevo supera al techo
    IF (v_consumo_actual + :NEW.cantidadPedida) > v_techo_maximo THEN
        RAISE_APPLICATION_ERROR(-20018, 'Error: Límite excedido. Los clientes solo han pedido ' || v_techo_maximo || 
                                        ' unidades, pero la sucursal intenta acumular ' || (v_consumo_actual + :NEW.cantidadPedida));
    END IF;

    -- ACTUALIZAR: Si pasa el control, sumamos el pedido al contador
    UPDATE CONTROL_STOCK
    SET totalPedidoSuc = totalPedidoSuc + :NEW.cantidadPedida
    WHERE codSucursal = :NEW.codSucursalSolicitante 
      AND codVino = :NEW.codVino;

END;
/

/* 
    Disparadores asociados a la restriccion 20 
*/

CREATE OR REPLACE TRIGGER trg_actualizar_ultima_fecha_pedido
AFTER INSERT OR UPDATE ON PEDIDO
FOR EACH ROW
BEGIN
    -- Intentamos actualizar si ya existe el registro
    UPDATE CONTROL_FECHAS_PEDIDOS
    SET ultimaFechaPedido = :NEW.fechaPedido
    WHERE codSucursalSolicitante = :NEW.codSucursalSolicitante
      AND codSucursalSolicitada  = :NEW.codSucursalSolicitada
      AND codVino                = :NEW.codVino;

    -- Si no se actualizó nada, insertamos el registro
    IF SQL%ROWCOUNT = 0 THEN
        INSERT INTO CONTROL_FECHAS_PEDIDOS
            (codSucursalSolicitante, codSucursalSolicitada, codVino, ultimaFechaPedido)
        VALUES
            (:NEW.codSucursalSolicitante, :NEW.codSucursalSolicitada, :NEW.codVino, :NEW.fechaPedido);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_validar_ultima_fecha_pedido
BEFORE INSERT OR UPDATE ON PEDIDO
FOR EACH ROW
DECLARE
    v_ultima_fecha DATE;
BEGIN
    BEGIN
        SELECT ultimaFechaPedido
        INTO v_ultima_fecha
        FROM CONTROL_FECHAS_PEDIDOS
        WHERE codSucursalSolicitante = :NEW.codSucursalSolicitante
          AND codSucursalSolicitada  = :NEW.codSucursalSolicitada
          AND codVino                = :NEW.codVino;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_ultima_fecha := NULL; -- No hay pedidos previos
    END;

    -- Validación de la regla 20
    IF v_ultima_fecha IS NOT NULL AND :NEW.fechaPedido <= v_ultima_fecha THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'Error: La fecha del pedido debe ser posterior al último pedido entre estas sucursales del mismo vino. ' ||
            'Última fecha registrada: ' || TO_CHAR(v_ultima_fecha, 'DD/MM/YYYY')
        );
    END IF;
END;
/


/* 
    Disparadores asociados a la restriccion 21
*/

CREATE OR REPLACE TRIGGER trg_validarFechaSuministro
BEFORE INSERT OR UPDATE ON PEDIDO
FOR EACH ROW
DECLARE
    v_ultima_fecha_pedido   DATE;
BEGIN
    -- Buscamos la fecha de la última solicitud del cliente para ese vino
    SELECT MAX(fechaSolicitud) INTO v_ultima_fecha_pedido
    FROM SOLICITUD 
    WHERE codSucursal = :NEW.codSucursalSolicitante 
      AND codVino = :NEW.codVino;

    IF v_ultima_fecha_pedido IS NOT NULL THEN
        -- CLAVE: Usamos < (menor estricto) para que NO falle si las fechas son iguales.
        IF :NEW.fechaPedido < v_ultima_fecha_pedido THEN
            RAISE_APPLICATION_ERROR(
                -20021,
                'Error R21: La fecha del pedido (' || TO_CHAR(:NEW.fechaPedido,'DD-MM-YYYY') || 
                ') no puede ser anterior a la solicitud del cliente (' || 
                TO_CHAR(v_ultima_fecha_pedido,'DD-MM-YYYY') || ').'
            );
        END IF;
    END IF;
END;
/