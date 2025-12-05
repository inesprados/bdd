/*
    Asignación de privilegios para perro1(Madrid), perro2(Barcelona), perro3(LaCoruña) y perro4(Granada)
*/
/* SCRIPT DE PRIVILEGIOS
   Ejecutar conectado como el dueño de las tablas (ej. perro1)
   para dar permiso a los otros tres.
*/

-- 1. CLIENTES
GRANT SELECT, INSERT, UPDATE, DELETE ON CLIENTES TO perro1, perro2, perro3, perro4;

-- 2. SUCURSALES
GRANT SELECT, INSERT, UPDATE, DELETE ON SUCURSALES TO perro1, perro2, perro3, perro4;

-- 3. EMPLEADOS
GRANT SELECT, INSERT, UPDATE, DELETE ON EMPLEADOS TO perro1, perro2, perro3, perro4;

-- 4. VINOS
GRANT SELECT, INSERT, UPDATE, DELETE ON VINOS TO perro1, perro2, perro3, perro4;

-- 5. PRODUCTORES (Replicada, todos deben poder ver la copia local de los otros si fuera necesario)
GRANT SELECT, INSERT, UPDATE, DELETE ON PRODUCTORES TO perro1, perro2, perro3, perro4;

-- 6. SOLICITUD
GRANT SELECT, INSERT, UPDATE, DELETE ON SOLICITUD TO perro1, perro2, perro3, perro4;

-- 7. SUMINISTRO
GRANT SELECT, INSERT, UPDATE, DELETE ON SUMINISTRO TO perro1, perro2, perro3, perro4;

-- 8. PEDIDO
GRANT SELECT, INSERT, UPDATE, DELETE ON PEDIDO TO perro1, perro2, perro3, perro4;

-- 9. TABLAS AUXILIARES (Para los triggers R18 y R20)
GRANT SELECT, INSERT, UPDATE, DELETE ON CONTROL_STOCK TO perro1, perro2, perro3, perro4;
GRANT SELECT, INSERT, UPDATE, DELETE ON CONTROL_FECHAS_PEDIDO TO perro1, perro2, perro3, perro4;

COMMIT;