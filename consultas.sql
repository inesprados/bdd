SELECT DISTINCT C.nombre, C.direccion, S.nombre, S.ciudad 
FROM V_CLIENTES C, V_SUCURSALES S, V_VINOS V, V_SOLICITUD SO
WHERE SO.CodCliente = C.CodCliente 
  AND SO.CodSucursal = S.CodSucursal 
  AND SO.CodVino = V.CodVino
  AND (C.comunidadAutonoma = 'Andalucía' OR C.comunidadAutonoma = 'Castilla-La Mancha') 
  AND V.marca = 'Tablas de Daimiel' 
  AND SO.fechaSolicitud BETWEEN TO_DATE('01/01/2025', 'DD/MM/YYYY') 
                            AND TO_DATE('01/09/2025', 'DD/MM/YYYY');


SELECT V.marca, V.anioCosecha, SUM(SO.cantidadSolicitada) 
FROM V_VINOS V, V_SOLICITUD SO, V_CLIENTES C
WHERE V.codProductor = '&codProductor'      
  AND V.codVino = SO.codVino                
  AND SO.codCliente = C.codCliente          
  AND C.comunidadAutonoma IN ('Baleares', 'Extremadura', 'País Valenciano')
GROUP BY V.marca, V.anioCosecha;

SELECT C.nombre, C.tipoCliente, SUM(SO.cantidadSolicitada)
FROM V_CLIENTES C, V_SOLICITUD SO, V_VINOS V
WHERE SO.CodSucursal = '&codSucursal'      
  AND SO.CodVino = V.CodVino 
  AND SO.CodCliente = C.CodCliente 
  AND V.denominacionOrigen IN ('Rioja', 'Albariño')
GROUP BY C.nombre, C.tipoCliente;