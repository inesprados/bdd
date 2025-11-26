










CREATE OR REPLACE TRIGGER trg_check_delegacion_suministro
BEFORE INSERT OR UPDATE ON SUMINISTRO
FOR EACH ROW
DECLARE
    v_ca_cliente    CLIENTES.comunidadAutonoma%TYPE;
    v_ca_sucursal   SUCURSALES.comunidadAutonoma%TYPE;
    v_del_cliente   VARCHAR2(10);
    v_del_sucursal  VARCHAR2(10);

    /* Mapeo de la comunidadAutonoma a delegación
     */
    FUNCTION get_delegacion(p_ca IN VARCHAR2) RETURN VARCHAR2 IS
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
        RAISE_APPLICATION_ERROR(-20009, 'Error R9: El cliente (' || v_ca_cliente || ' - Del: ' || v_del_cliente || 
                                    ') no puede operar con la sucursal (' || v_ca_sucursal || ' - Del: ' || v_del_sucursal || ').');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error R9: El cliente ' || :NEW.codCliente || ' o la sucursal ' || :NEW.codSucursal || ' no existen.');
END;
/

-- Disparador para verificar que la fecha de un suministro sea igual o posterior a la del ultimo suministro
CREATE OR REPLACE TRIGGER trg_check_fecha_suministro
BEFORE INSERT OR UPDATE OF fechaPedido ON SUMINISTRO
FOR EACH ROW
DECLARE
    v_ultima_fecha   DATE;
BEGIN
    -- Última fecha de suministro para este cliente
    SELECT MAX(fechaPedido) INTO v_ultima_fecha
    FROM SUMINISTRO
    WHERE codCliente = :NEW.codCliente;

    -- Si el cliente ya tiene suministros, validamos la fecha
    IF v_ultima_fecha IS NOT NULL THEN
        IF :NEW.fechaPedido < v_ultima_fecha THEN
            RAISE_APPLICATION_ERROR(-20010, 'Error R10: La fecha del nuevo suministro (' || 
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