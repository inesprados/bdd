# bdd

Para comprobar qué archivos han cambiado:
git status

Para añadir los archivos al commit
git add 

Para añadir un archivo concreto
git add archivo.txt

Para hacer el commit
git commit -m "Descripción del cambio"

Enviar los cambios al repositorio
git push origin main

Crear una rama nueva
git checkout -b nombre-de-tu-rama

Trabajas en esta rama, haces commits + push
git push origin nombre-de-tu-rama

Crear pull request
gh pr create

# Tabla de Códigos de Error (raise_application_error)

| Rango de Números        | Módulo / Práctica            | Descripción del Error |
|-------------------------|-------------------------------|------------------------|
| -20000                  | General                       | Error genérico no controlado. |
| -20001                  | General                       | "NO_DATA_FOUND (Objeto no encontrado, ej. cliente o sucursal)." |
| -20006                  | P3: Trigger (R6)              | El salario del empleado no puede disminuir. |
| -20009                  | P3: Trigger (R9)              | Cliente y Sucursal no pertenecen a la misma delegación. |
| -20010                  | P3: Trigger (R10)             | La fecha de suministro es anterior al último suministro del cliente. |
| -20015                  | P3: Trigger (R15)             | DELETE VINO fallido (total suministrado > 0). |
| -20016                  | P3: Trigger (R16)             | DELETE PRODUCTOR fallido (total suministrado de sus vinos > 0). |
| -20017                  | P3: Trigger (R17)             | INSERT PEDIDO fallido (pedido a la misma delegación). |
| -20019                  | P3: Trigger (R19)             | INSERT PEDIDO fallido (sucursal solicitada no distribuye ese vino). |
| -20021                  | P3: Trigger (R21)             | INSERT PEDIDO fallido (fecha de pedido no es posterior a la solicitud del cliente). |
| -20100 a -20199         | P4: Procedimientos (Empleado) | Errores en alta_empleado, baja_empleado, trasladar_empleado, etc. |
| -20200 a -20299         | P4: Procedimientos (Sucursal) | Errores en alta_sucursal, cambiar_director, etc. |
| -20300 a -20399         | P4: Procedimientos (Cliente)  | Errores en alta_cliente. |
| -20400 a -20499         | P4: Procedimientos (Suministro) | Errores en alta_actualiza_suministro, baja_suministro. P.ej., -20401: Stock insuficiente. |
| -20500 a -20599         | P4: Procedimientos (Pedido)   | Errores en alta_pedido, baja_pedido. P.ej., -20501: Error R18 (Cantidad excede), -20502: Error R20 (Fecha inválida). |
| -20600 a -20699         | P4: Procedimientos (Vino)     | Errores en alta_vino, baja_vino. |
| -20700 a -20799         | P4: Procedimientos (Productor) | Errores en alta_productor, baja_productor. |

