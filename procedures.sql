
drop procedure MigrarMarca

ALTER PROCEDURE MigrarProvincia
AS
BEGIN
    BEGIN TRANSACTION;
    INSERT INTO SELECTOS.Provincia(provincia_nombre)
        SELECT DISTINCT VEN_USUARIO_DOMICILIO_PROVINCIA
        FROM gd_esquema.Maestra m
        WHERE m.VEN_USUARIO_DOMICILIO_PROVINCIA IS NOT NULL
    union 
    SELECT DISTINCT ALMACEN_PROVINCIA
        FROM gd_esquema.Maestra m
        WHERE m.ALMACEN_PROVINCIA IS NOT NULL and m.ALMACEN_PROVINCIA not in (select PROVINCIA_nombre from SELECTOS.PROVINCIA)
    union
    SELECT DISTINCT CLI_USUARIO_DOMICILIO_PROVINCIA
        FROM gd_esquema.Maestra m
        WHERE m.CLI_USUARIO_DOMICILIO_PROVINCIA IS NOT NULL and m.CLI_USUARIO_DOMICILIO_PROVINCIA not in (select PROVINCIA_nombre from SELECTOS.PROVINCIA)
    COMMIT TRANSACTION;
END;

exec MigrarProvincia
select * from SELECTOS.Localidad
CREATE PROCEDURE MigrarLocalidad
AS
BEGIN
    BEGIN TRANSACTION;
    INSERT INTO SELECTOS.Localidad(localidad_nombre, localidad_provincia)
        SELECT DISTINCT VEN_USUARIO_DOMICILIO_LOCALIDAD,
                        p1.provincia_id
        FROM gd_esquema.Maestra m
        LEFT JOIN SELECTOS.provincia p1 on p1.provincia_nombre = m.VEN_USUARIO_DOMICILIO_PROVINCIA  
        WHERE m.VEN_USUARIO_DOMICILIO_LOCALIDAD IS NOT NULL
    union 
    SELECT DISTINCT ALMACEN_Localidad,
                    p1.provincia_id
        FROM gd_esquema.Maestra m
        LEFT JOIN SELECTOS.provincia p1 on p1.provincia_nombre = m.ALMACEN_PROVINCIA
        WHERE m.ALMACEN_Localidad IS NOT NULL 
        AND m.ALMACEN_Localidad NOT IN (select localidad_nombre from SELECTOS.Localidad)
        AND p1.provincia_id not in (select localidad_provincia from SELECTOS.Localidad)
    union
    SELECT DISTINCT CLI_USUARIO_DOMICILIO_LOCALIDAD,
                    p1.provincia_id
        FROM gd_esquema.Maestra m
        LEFT JOIN SELECTOS.provincia p1 on p1.provincia_nombre = m.CLI_USUARIO_DOMICILIO_PROVINCIA
        WHERE m.CLI_USUARIO_DOMICILIO_LOCALIDAD IS NOT NULL 
        AND m.CLI_USUARIO_DOMICILIO_LOCALIDAD NOT IN (select localidad_nombre from SELECTOS.Localidad)
        AND p1.provincia_id not in (select localidad_provincia from SELECTOS.Localidad)
   COMMIT TRANSACTION;
END;

exec migrarLocalidad

CREATE PROCEDURE MigrarAlmacen
AS
BEGIN
    BEGIN TRANSACTION;
    INSERT INTO SELECTOS.Almacen(almacen_id, almacen_localidad,almacen_calle, almacen_nro_calle, almacen_costo_dia_al)
    SELECT m.almacen_codigo, l.localidad_id, m.almacen_calle, m.almacen_nro_calle, m.almacen_costo_dia_al 
    FROM gd_esquema.Maestra m 
    LEFT JOIN SELECTOS.localidad l on m.almacen_localidad = l.localidad_nombre
    LEFT JOIN SELECTOS.provincia p on p.provincia_nombre = m.almacen_provincia
    WHERE p.provincia_id = l.localidad_provincia
    COMMIT TRANSACTION;
END;
 
EXEC migrarAlmacen

select * from SELECTOS.almacen

CREATE PROCEDURE MigrarUsuario
AS
BEGIN
    BEGIN TRANSACTION;
        --primero para cli_usuario
        INSERT INTO SELECTOS.Usuario(usuario_nombre, usuario_pass, usuario_fecha_creacion)
        SELECT DISTINCT CLI_USUARIO_NOMBRE, CLI_USUARIO_PASS, CLI_USUARIO_FECHA_CREACION
        FROM gd_esquema.Maestra m
        WHERE m.CLI_USUARIO_NOMBRE IS NOT NULL
    
        --despues para ven_usuario
        INSERT INTO SELECTOS.Usuario(usuario_nombre, usuario_pass, usuario_fecha_creacion)
        SELECT DISTINCT VEN_USUARIO_NOMBRE, VEN_USUARIO_PASS, VEN_USUARIO_FECHA_CREACION
        FROM gd_esquema.Maestra m
        WHERE m.VEN_USUARIO_NOMBRE IS NOT NULL;
    COMMIT TRANSACTION;
END;


CREATE PROCEDURE MigrarVendedor
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Vendedor(vendedor_usuario, vendedor_cuit, vendedor_mail, vendedor_razon_social)
        SELECT DISTINCT u.usuario_id, m.VENDEDOR_CUIT, m.VENDEDOR_MAIL, m.VENDEDOR_RAZON_SOCIAL
        FROM gd_esquema.Maestra m 
            LEFT JOIN SELECTOS.Usuario AS u
                ON m.VEN_USUARIO_NOMBRE = usuario_nombre
                AND  m.VEN_USUARIO_PASS= usuario_pass
                AND m.VEN_USUARIO_FECHA_CREACION = usuario_fecha_creacion
        WHERE m.VENDEDOR_CUIT IS NOT NULL
    COMMIT TRANSACTION;
END;


CREATE PROCEDURE MigrarCliente
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Cliente(cliente_usuario, cliente_nombre, cliente_apellido, cliente_fecha_nac, cliente_mail, cliente_dni)
        SELECT DISTINCT u.usuario_id, m.CLIENTE_NOMBRE, m.CLIENTE_APELLIDO, m.CLIENTE_FECHA_NAC, m.CLIENTE_MAIL, m.CLIENTE_DNI
        FROM gd_esquema.Maestra m 
            JOIN SELECTOS.Usuario AS u
                ON m.CLI_USUARIO_NOMBRE = usuario_nombre
                AND m.CLI_USUARIO_PASS = usuario_pass
                AND m.CLI_USUARIO_FECHA_CREACION = usuario_fecha_creacion
        WHERE u.usuario_id IS NOT NULL
    COMMIT TRANSACTION;
END;

CREATE PROCEDURE MigrarRubro
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Rubro(rubro_descripcion)
        SELECT DISTINCT m.PRODUCTO_RUBRO_DESCRIPCION
        FROM gd_esquema.Maestra m
        WHERE m.PRODUCTO_RUBRO_DESCRIPCION IS NOT NULL
    COMMIT TRANSACTION;
END;

CREATE PROCEDURE MigrarSubRubro
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.SubRubro(sub_rubro_nombre)
        SELECT DISTINCT m.PRODUCTO_SUB_RUBRO
        FROM gd_esquema.Maestra m
        WHERE m.PRODUCTO_SUB_RUBRO IS NOT NULL
    COMMIT TRANSACTION;
END;

CREATE PROCEDURE MigrarModelo
AS
BEGIN
    BEGIN TRANSACTION;
    
    INSERT INTO SELECTOS.Marca (modelo_codigo, modelo_descripcion)
    SELECT DISTINCT m.PRODUCTO_MOD_CODIGO, m.PRODUCTO_MOD_DESCRIPCION
    FROM gd_esquema.Maestra m
    WHERE m.PRODUCTO_MOD_CODIGO IS NOT NULL 
      AND m.PRODUCTO_MOD_DESCRIPCION IS NOT NULL;
    
    COMMIT TRANSACTION;
END;

CREATE PROCEDURE MigrarMarca
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Marca(producto_marca)
        SELECT DISTINCT producto_marca
        FROM gd_esquema.Maestra m
        WHERE m.PRODUCTO_MARCA IS NOT NULL
    COMMIT TRANSACTION;
END;

--Producto,concepto, domicilio, publicacion, detalleFactura, venta



CREATE PROCEDURE MigrarDetallePago
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELEECTOS.DetallePago(detalle_pago_nro_tarjeta,detalle_pago_venc_tarjeta,detalle_pago_cant_cuotas)
        SELECT DISTINCT m.PAGO_NRO_TARJETA, m.PAGO_FECHA_VENC_TARJETA, m.PAGO_CANT_CUOTAS
        FROM gd_esquema.Maestra m
        WHERE 
    COMMIT TRANSACTION;
END;

CREATE PROCEDURE MigrarTipoMedioDePago
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.TipoMedioPago(pago_tipo_medio_pago)
        SELECT DISTINCT m.PAGO_TIPO_MEDIO_PAGO
        FROM gd_esquema.Maestra m
        WHERE m.PAGO_TIPO_MEDIO_PAGO IS NOT NULL
    COMMIT TRANSACTION;
END;

CREATE PROCEDURE MigrarMediosPago
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.MediosPago(pago_medio_pago,medio_pago_tipo_medio_pago_id)
        SELECT DISTINCT m.PAGO_MEDIO_PAGO, tmp.pago_tipo_medio_pago
        FROM gd_esquema.Maestra m
        LEFT JOIN SELECTOS.TipoMedioDePago tmp
            ON m.PAGO_TIPO_MEDIO_PAGO = tmp.pago_tipo_medio_pago
        WHERE m.PAGO_MEDIO_PAGO IS NOT NULL
    COMMIT TRANSACTION;
END;


CREATE PROCEDURE MigrarTipoEnvio
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.TipoEnvio(envio_tipo)
        SELECT DISTINCT m.ENVIO_TIPO
        FROM gd_esquema.Maestra m
        where m.ENVIO_TIPO is not null
    COMMIT TRANSACTION;
END;



CREATE PROCEDURE MigrarFactura
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Factura(factura_vendedor,factura_numero,factura_fecha,factura_total)
        SELECT DISTINCT v.asasa,m.FACTURA_NUMERO,m.FACTURA_FECHA,
        FROM gd_esquema.Maestra m
        join SELECTOS.Vendedor as v on
           m.
    COMMIT TRANSACTION;
END;


CREATE PROCEDURE MigrarDetalleFactura -- falta concepto y factura para seguir
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.DetalleFactura(detalle_factura_id, detalle_factura_concepto_id, detalle_factura_publicacion, detalle_factura_cantidad, detalle_factur)
        SELECT DISTINCT 
        FROM gd_esquema.Maestra m
        where m. is not null
    COMMIT TRANSACTION;
END;

/*

   CREATE TABLE SELECTOS.DetalleFactura(
        detalle_factura_id  int,
        detalle_factura_concepto_id  int, 
        detalle_factura_publicacion  decimal(18,0),
        detalle_factura_cantidad decimal(18,0),
        detalle_factura_subtotal  decimal(18,2)
        PRIMARY KEY (detalle_factura_id, detalle_factura_concepto_id),
        FOREIGN KEY (detalle_factura_id) REFERENCES SELECTOS.Factura(factura_id),
        FOREIGN KEY (detalle_factura_concepto_id) REFERENCES SELECTOS.Concepto(concepto_id)
    );

*/


DetalleVenta
Envio
-- Pago -> haciendo
-- MediosPago
-- DetallePago -> haciendo
Venta
DetalleFactura -> necesita concepto y factura (me quede aca- Mauro)
Publicacion
Domicilio
Concepto
Producto
--Marca
--Modelo
--SubRubro
--Rubro
--Cliente
Factura -> intentando
--Vendedor
--Usuario 
--Almacen -> Haciendo
--Localidad
-- Provincia
-- TipoMedioDePago
--TipoEnvio

select l1.localidad_nombre, l1.localidad_provincia, l2.localidad_nombre, l2.localidad_provincia from SELECTOS.localidad l1
 join SELECTOS.localidad l2 on l2.localidad_nombre = l1.localidad_nombre and l1.localidad_id < l2.localidad_id
 group by l1.localidad_nombre, l1.localidad_provincia
 order by l1.localidad_nombre

select * from 
(16918 rows affected)