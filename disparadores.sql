
CREATE OR REPLACE TRIGGER trigger_ControlarSalario
BEFORE UPDATE OF salario ON EMPLEADOS
FOR EACH ROW
BEGIN
    IF :NEW.salario < OLD.salario THEN
        RAISE_APPLICATION_ERROR(-20006, 'No se puedo disminuir el salario de un empleado');
    END IF;
END;
/

/**PREGUNTAR SI HACE FALTA**/
CREATE OR REPLACE TRIGGER trigger_validarDNI
BEFORE INSERT OR UPDATE OF DNI ON CLIENTES 
FOR EACH ROW
DECLARE
    cnt_dni number;
BEGIN
    IF inserting then
        select dni into cnt_dni from CLIENTES WHERE dni = :new.dni;
        IF cnt_dni > 0 THEN
            RAISE_APPLICATION_ERROR(-2001, 'Ese DNI ya está registrado');
        END IF;
END;
/

CREATE OR REPLACE TRIGGER trigger_validarEliminacionProductor
BEFORE DELETE ON PRODUCTORES
FOR EACH ROW
DECLARE
    cnt_suministro number;
BEGIN
    select cantidadSuministrada
END;
/