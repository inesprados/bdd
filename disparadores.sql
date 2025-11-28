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
END;
/

CREATE OR REPLACE TRIGGER trg_ControlarSalario
BEFORE UPDATE OF salario ON EMPLEADOS
FOR EACH ROW
BEGIN
    IF :NEW.salario < OLD.salario THEN
        RAISE_APPLICATION_ERROR(-20006, 'No se puedo disminuir el salario de un empleado');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_check_delegacion_suministro
BEFORE INSERT OR UPDATE ON SUMINISTRO
FOR EACH ROW
DECLARE
    v_ca_cliente    CLIENTES.comunidadAutonoma%TYPE;
    v_ca_sucursal   SUCURSALES.comunidadAutonoma%TYPE;
    v_del_cliente   VARCHAR2(10);
    v_del_sucursal  VARCHAR2(10);

BEGIN
    -- CCAA del Cliente
    SELECT comunidadAutonoma INTO v_ca_cliente
    FROM CLIENTES
    WHERE codCliente = :NEW.codCliente;

    -- CCAA de la Sucursal
    SELECT comunidadAutonoma INTO v_ca_sucursal
    FROM SUCURSALES
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
    FROM SUCURSALES WHERE codSucursal = :NEW.codSucursalSolicitante;

    SELECT comunidadAutonoma INTO v_ca_solicitada 
    FROM SUCURSALES WHERE codSucursal = :NEW.codSucursalSolicitada;

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
    FROM SUCURSALES 
    WHERE codSucursal = :NEW.codSucursalSolicitante;

    -- Obtenemos la comunidad autonoma de la sucursal solicitada
    SELECT comunidadAutonoma INTO ca_solicitada
    FROM SUCURSALES 
    WHERE codSucursal = :NEW.codSucursalSolicitada;

    --Obtenemos la comunidad autonoma del vino
    SELECT comunidadAutonoma INTO ca_vino
    FROM VINOS 
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

--Disparador para validar la fecha del pedido de una sucursal S1 a otra S2 de un determinado vino y teniendo en cuenta las delegaciones
CREATE OR REPLACE TRIGGER trg_validarFechaPedido
BEFORE INSERT OR UPDATE ON PEDIDO
FOR EACH ROW
DECLARE
    v_ultima_fecha_sucursal   DATE;
    v_ultima_fecha_solicitud_cliente   DATE;
BEGIN
    -- Última fecha de suministro para esta sucursal
    SELECT MAX(fechaPedido) INTO v_ultima_fecha_sucursal
    FROM PEDIDO
    WHERE codSucursalSolicitante = :NEW.codSucursalSolicitante   --S1 
        AND codSucursalSolicitada = :NEW:codSucursalSolicitada   --S2
        AND codVino = :NEW.codVino;

    -- Si la sucursal ya tiene suministros, validamos la fecha
    IF v_ultima_fecha_sucursal IS NOT NULL THEN
        IF :NEW.fechaPedido < v_ultima_fecha THEN
            RAISE_APPLICATION_ERROR(-20020, 'Error: La fecha del nuevo suministro (' || 
                                    TO_CHAR(:NEW.fechaPedido, 'DD-MM-YYYY') || 
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

--Disparador 21. La fecha de pedido de un vino de una sucursal S1 a otra S2, tiene que ser posterior a
la última fecha de solicitud de suministro de ese mismo vino recibida enS1 por un
cliente. Por ejemplo, si un cliente de Andalucía solicita suministro de vino de Rioja a
la sucursal S1 en fecha F, y esa solicitud es la última que S1 ha recibido de vino de
Rioja, el pedido de S1 a la sucursal de la delegación de Madrid correspondiente tiene
que ser de fecha posterior a F.



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