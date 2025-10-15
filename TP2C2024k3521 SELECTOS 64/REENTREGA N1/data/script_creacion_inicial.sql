CREATE SCHEMA SELECTOS
GO
------------------------- PROCEDURES DE MIGRACION ------------------------------------------------
CREATE PROCEDURE MigrarProvincia
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
GO

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
GO

CREATE PROCEDURE MigrarAlmacen
AS
BEGIN
    BEGIN TRANSACTION;
    INSERT INTO SELECTOS.Almacen(almacen_id, almacen_localidad,almacen_provincia,almacen_calle, almacen_nro_calle, almacen_costo_dia_al)
    SELECT DISTINCT m.almacen_codigo, l.localidad_id,p.provincia_id, m.almacen_calle, m.almacen_nro_calle, m.almacen_costo_dia_al 
    FROM gd_esquema.Maestra m 
    LEFT JOIN SELECTOS.localidad l on m.almacen_localidad = l.localidad_nombre
    LEFT JOIN SELECTOS.provincia p on p.provincia_nombre = m.almacen_provincia
    WHERE p.provincia_id = l.localidad_provincia
    COMMIT TRANSACTION;
END;
GO

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
GO

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
GO

CREATE PROCEDURE MigrarFactura
AS
BEGIN
    BEGIN TRANSACTION;

    -- Selecciona datos de factura y vendedor basados en el identificador común de publicación
    INSERT INTO SELECTOS.Factura(factura_vendedor, factura_numero, factura_fecha, factura_total)
    SELECT DISTINCT 
        v.vendedor_id,
        f.FACTURA_NUMERO,
        f.FACTURA_FECHA,
        f.FACTURA_TOTAL
    FROM 
        gd_esquema.Maestra m
    LEFT JOIN 
        gd_esquema.Maestra f ON m.PUBLICACION_CODIGO = f.PUBLICACION_CODIGO AND f.FACTURA_NUMERO IS NOT NULL
    LEFT JOIN 
        SELECTOS.Vendedor v ON 
            (m.VENDEDOR_CUIT = v.vendedor_cuit OR 
             m.VENDEDOR_RAZON_SOCIAL = v.vendedor_razon_social OR 
             m.VENDEDOR_MAIL = v.vendedor_mail)
    WHERE 
        m.PUBLICACION_CODIGO IS NOT NULL
        AND v.vendedor_id IS NOT NULL;

    COMMIT TRANSACTION;
END;
GO

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
GO

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
GO

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
GO

CREATE PROCEDURE MigrarModelo
AS
BEGIN
    BEGIN TRANSACTION;
    
    INSERT INTO SELECTOS.Modelo(modelo_codigo, modelo_descripcion)
    SELECT DISTINCT m.PRODUCTO_MOD_CODIGO, m.PRODUCTO_MOD_DESCRIPCION
    FROM gd_esquema.Maestra m
    WHERE m.PRODUCTO_MOD_CODIGO IS NOT NULL 
    
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarMarca
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Marca(marca_descripcion)
        SELECT DISTINCT m.PRODUCTO_MARCA
        FROM gd_esquema.Maestra m
        WHERE m.PRODUCTO_MARCA IS NOT NULL
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarProducto
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Producto(producto_rubro, producto_sub_rubro, producto_mod_codigo, producto_marca_codigo,
                        producto_descripcion, producto_precio)
        SELECT DISTINCT r.rubro_id, sr.sub_rubro_id, mo.modelo_codigo, marca.marca_id, m.PRODUCTO_DESCRIPCION, m.PRODUCTO_PRECIO
        FROM gd_esquema.Maestra m
            JOIN SELECTOS.SubRubro AS sr
            ON PRODUCTO_SUB_RUBRO = sub_rubro_nombre
                JOIN SELECTOS.Rubro AS r
                ON PRODUCTO_RUBRO_DESCRIPCION = rubro_descripcion
                    JOIN SELECTOS.Marca AS marca
                    ON PRODUCTO_MARCA = marca_descripcion
					JOIN SELECTOS.Modelo AS mo
					ON PRODUCTO_MOD_DESCRIPCION = modelo_descripcion
        WHERE m.PRODUCTO_CODIGO IS NOT NULL
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarConcepto
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.Concepto(concepto_tipo)
		SELECT DISTINCT	m.FACTURA_DET_TIPO
		FROM gd_esquema.Maestra m
		WHERE m.FACTURA_DET_TIPO IS NOT NULL
	COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarDomicilio
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Domicilio(domicilio_localidad,domicilio_usuario,domicilio_piso,domicilio_depto,domicilio_calle,domicilio_nro_calle,domicilio_cp)
        SELECT DISTINCT l.localidad_id,u.usuario_id,m.VEN_USUARIO_DOMICILIO_PISO,VEN_USUARIO_DOMICILIO_DEPTO,VEN_USUARIO_DOMICILIO_CALLE,
                        VEN_USUARIO_DOMICILIO_NRO_CALLE,VEN_USUARIO_DOMICILIO_CP
        FROM gd_esquema.Maestra m 
             JOIN SELECTOS.Usuario AS u
                ON m.VEN_USUARIO_NOMBRE = usuario_nombre
                AND  m.VEN_USUARIO_PASS= usuario_pass
                AND m.VEN_USUARIO_FECHA_CREACION = usuario_fecha_creacion
                 /*JOIN SELECTOS.Localidad as l
                    on l.localidad_nombre = m.VEN_USUARIO_DOMICILIO_LOCALIDAD
                    join SELECTOS.Provincia as p 
                        on m.VEN_USUARIO_DOMICILIO_PROVINCIA = p.provincia_nombre*/
					JOIN SELECTOS.Provincia p on m.VEN_USUARIO_DOMICILIO_PROVINCIA = p.provincia_nombre
					JOIN SELECTOS.Localidad l on m.VEN_USUARIO_DOMICILIO_LOCALIDAD = l.localidad_nombre and
					l.localidad_provincia = p.provincia_id
        WHERE m.VEN_USUARIO_DOMICILIO_CALLE IS NOT NULL
        Union
        SELECT DISTINCT l.localidad_id,u.usuario_id,m.CLI_USUARIO_DOMICILIO_PISO,CLI_USUARIO_DOMICILIO_DEPTO,CLI_USUARIO_DOMICILIO_CALLE,
                        CLI_USUARIO_DOMICILIO_NRO_CALLE,CLI_USUARIO_DOMICILIO_CP
        FROM gd_esquema.Maestra m 
             JOIN SELECTOS.Usuario AS u
                ON m.CLI_USUARIO_NOMBRE = usuario_nombre
                AND  m.CLI_USUARIO_PASS= usuario_pass
                AND m.CLI_USUARIO_FECHA_CREACION = usuario_fecha_creacion
                 /*JOIN SELECTOS.Localidad as l
                    on l.localidad_nombre = m.CLI_USUARIO_DOMICILIO_LOCALIDAD
                    join SELECTOS.Provincia as p 
                        on m.CLI_USUARIO_DOMICILIO_PROVINCIA = p.provincia_nombre*/
				JOIN SELECTOS.Provincia p on m.CLI_USUARIO_DOMICILIO_PROVINCIA = p.provincia_nombre
					JOIN SELECTOS.Localidad l on m.CLI_USUARIO_DOMICILIO_LOCALIDAD = l.localidad_nombre and
					l.localidad_provincia = p.provincia_id
        WHERE m.CLI_USUARIO_DOMICILIO_CALLE IS NOT NULL 
		order by usuario_id
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarPublicacion
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.Publicacion(publicacion_id,publicacion_vendedor,publicacion_producto,publicacion_almacen,
										publicacion_descripcion,publicacion_fecha,publicacion_fecha_v,publicacion_precio,
										publicacion_costo,publicacion_porc_venta,publicacion_stock_cantidad)
		SELECT DISTINCT
			m.PUBLICACION_CODIGO,
			v.vendedor_id,
			p.producto_id,
			a.almacen_id,
			m.PUBLICACION_DESCRIPCION,
			m.PUBLICACION_FECHA,
			m.PUBLICACION_FECHA_V,
			m.PUBLICACION_PRECIO,
			m.PUBLICACION_COSTO,
			m.PUBLICACION_PORC_VENTA,
			m.PUBLICACION_STOCK
		FROM gd_esquema.Maestra m
		JOIN SELECTOS.Vendedor v ON 
			m.VENDEDOR_CUIT = v.vendedor_cuit and
			m.VENDEDOR_MAIL = v.vendedor_mail and
			m.VENDEDOR_RAZON_SOCIAL = v.vendedor_razon_social
		JOIN SELECTOS.Producto p ON
			m.PRODUCTO_DESCRIPCION = p.producto_descripcion and
			m.PRODUCTO_PRECIO = p.producto_precio and
			m.PRODUCTO_MOD_CODIGO = p.producto_mod_codigo
		JOIN SELECTOS.Almacen a ON
			a.almacen_id = m.ALMACEN_CODIGO
		WHERE m.PUBLICACION_CODIGO IS NOT NULL
	COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarDetalleFactura
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.DetalleFactura(detalle_factura_id, detalle_factura_concepto_id, detalle_factura_publicacion, detalle_factura_cantidad, detalle_factura_subtotal, detalle_factura_precio)
        SELECT f.factura_id, c.concepto_id, m.publicacion_codigo, m.FACTURA_DET_CANTIDAD, m.FACTURA_DET_SUBTOTAL, m.FACTURA_DET_PRECIO
        FROM gd_esquema.Maestra m
			JOIN SELECTOS.Concepto AS c
                    ON FACTURA_DET_TIPO = c.concepto_tipo
            JOIN SELECTOS.Factura AS f
                ON m.FACTURA_NUMERO = f.factura_numero
        where m.FACTURA_DET_TIPO is not null
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarVenta
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Venta(venta_cliente,venta_codigo,venta_fecha,venta_total)
        SELECT DISTINCT c.cliente_id, m.VENTA_CODIGO, m.VENTA_FECHA, m.VENTA_TOTAL
        FROM gd_esquema.Maestra m
            JOIN SELECTOS.Cliente c
                ON m.CLIENTE_NOMBRE = c.cliente_nombre AND
                m.CLIENTE_APELLIDO = c.cliente_apellido AND
                m.CLIENTE_FECHA_NAC = c.cliente_fecha_nac AND
                m.CLIENTE_MAIL = c.cliente_mail AND
                m.CLIENTE_DNI = c.cliente_dni
        WHERE m.VENTA_CODIGO is not null
    COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE MigrarDetallePago
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.DetallePago(detalle_pago_nro_tarjeta,detalle_pago_venc_tarjeta,detalle_pago_cant_cuotas)
        SELECT DISTINCT m.PAGO_NRO_TARJETA, m.PAGO_FECHA_VENC_TARJETA, m.PAGO_CANT_CUOTAS
        FROM gd_esquema.Maestra m
        WHERE m.PAGO_NRO_TARJETA IS NOT NULL
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarTipoMedioDePago
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.TipoMedioDePago(pago_tipo_medio_pago)
        SELECT DISTINCT m.PAGO_TIPO_MEDIO_PAGO
        FROM gd_esquema.Maestra m
        WHERE m.PAGO_TIPO_MEDIO_PAGO IS NOT NULL
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarMediosPago
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.MediosPago(medio_pago_tipo_medio_pago_id, pago_medio_pago)
        SELECT DISTINCT tmp.tipo_medio_de_pago_id, m.PAGO_MEDIO_PAGO
        FROM gd_esquema.Maestra m
        JOIN SELECTOS.TipoMedioDePago tmp
            ON m.PAGO_TIPO_MEDIO_PAGO = tmp.pago_tipo_medio_pago
        WHERE m.PAGO_MEDIO_PAGO IS NOT NULL
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE MigrarPago
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Pago(pago_medio_pago,pago_venta,pago_fecha,pago_importe)
        SELECT DISTINCT mp.medio_pago_id, v.venta_id, m.PAGO_FECHA, m.PAGO_IMPORTE
        FROM gd_esquema.Maestra m
        JOIN SELECTOS.MediosPago mp ON m.PAGO_MEDIO_PAGO = mp.pago_medio_pago
        JOIN SELECTOS.Venta v ON m.VENTA_CODIGO = v.venta_codigo
        WHERE m.PAGO_FECHA is not null and m.PAGO_IMPORTE is not null
    COMMIT TRANSACTION;
END;
GO

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
GO

CREATE PROCEDURE MigrarEnvio
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.Envio(envio_venta, envio_domicilio_id, envio_tipo_id, envio_fecha_programada, envio_hora_inicio, envio_hora_fin_inicio, envio_fecha_entrega, envio_costo)
        SELECT DISTINCT v.venta_id, 
                        d.domicilio_id, 
                        t.tipo_envio_id, 
                        m.ENVIO_FECHA_PROGAMADA,
                        m.ENVIO_HORA_INICIO,
                        m.ENVIO_HORA_FIN_INICIO,
                        m.ENVIO_FECHA_ENTREGA,
                        m.ENVIO_COSTO
        FROM gd_esquema.maestra m
        JOIN SELECTOS.venta v on m.VENTA_CODIGO = v.venta_codigo
        JOIN SELECTOS.Domicilio d ON 
		m.CLI_USUARIO_DOMICILIO_CALLE = d.domicilio_calle
		AND m.CLI_USUARIO_DOMICILIO_NRO_CALLE = d.domicilio_nro_calle
		AND m.CLI_USUARIO_DOMICILIO_DEPTO = d.domicilio_depto
		AND m.CLI_USUARIO_DOMICILIO_CP = d.domicilio_cp
		AND m.CLI_USUARIO_DOMICILIO_LOCALIDAD = 
       (SELECT l.localidad_nombre 
        FROM SELECTOS.Localidad l 
        WHERE l.localidad_id = d.domicilio_localidad)
		AND m.CLI_USUARIO_DOMICILIO_PROVINCIA = (SELECT pr.provincia_nombre from SELECTOS.Provincia pr JOIN SELECTOS.Localidad lo ON
			localidad_provincia = provincia_id where localidad_id = d.domicilio_localidad)
        JOIN SELECTOS.TipoEnvio t on t.envio_tipo =  m.ENVIO_TIPO

        where m.ENVIO_TIPO is not null

    COMMIT TRANSACTION;
END; 
GO

CREATE PROCEDURE MigrarDetalleVenta
AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO SELECTOS.DetalleVenta(detalle_venta_publicacion, detalle_venta_venta_id, detalle_venta_cantidad,
                                         detalle_venta_subtotal, detalle_venta_precio)
        SELECT DISTINCT m.PUBLICACION_CODIGO, v.venta_id, m.VENTA_DET_CANT, m.VENTA_DET_SUB_TOTAL, m.VENTA_DET_PRECIO
        FROM gd_esquema.Maestra AS m
            JOIN SELECTOS.Venta AS v
                ON m.VENTA_CODIGO = v.venta_codigo
        where (m.PUBLICACION_CODIGO is not null) AND (m.VENTA_CODIGO is not null)
    COMMIT TRANSACTION;
END;
GO
--------------------------------- CREATE DE TABLAS---------------------------------------
CREATE PROCEDURE CrearTablas
AS
BEGIN
    BEGIN TRANSACTION;
    create table SELECTOS.Provincia(
        provincia_id int PRIMARY KEY  IDENTITY(1,1),
        provincia_nombre varchar(50)
    );

    create table SELECTOS.Localidad(
        localidad_id int PRIMARY KEY  IDENTITY(1,1),
        localidad_provincia int,
        localidad_nombre nvarchar(50),
        foreign key (localidad_provincia) references SELECTOS.Provincia(provincia_id)
    );

    create table SELECTOS.Almacen (
        almacen_id decimal(18,0) PRIMARY KEY,
        almacen_localidad int,
		almacen_provincia int,
        almacen_nro_calle decimal(9,2),
        almacen_costo_dia_al decimal (9,2),
        almacen_calle varchar(100),
        foreign key (almacen_localidad) references SELECTOS.Localidad(localidad_id),
		foreign key (almacen_provincia) references SELECTOS.Provincia(provincia_id)
    );

    create table SELECTOS.Usuario(
        usuario_id int PRIMARY KEY  IDENTITY(1,1),
        usuario_nombre varchar(100),
        usuario_pass varchar(100),
        usuario_fecha_creacion smalldatetime
    );

    create table SELECTOS.Vendedor(
        vendedor_id int PRIMARY KEY  IDENTITY(1,1),
        vendedor_usuario int,
        vendedor_cuit varchar(50),
        vendedor_mail varchar(50),
        vendedor_razon_social varchar(50),
        foreign key (vendedor_usuario) references SELECTOS.Usuario(usuario_id)
    );

    CREATE TABLE SELECTOS.Factura(
        factura_id int PRIMARY KEY  IDENTITY(1,1),
        factura_vendedor int,
        factura_numero decimal(18,0),
        factura_fecha smalldatetime,
        factura_total decimal(18,2),
        foreign key (factura_vendedor) references SELECTOS.Vendedor(vendedor_id)
    );

    create table SELECTOS.Cliente(
        cliente_id int PRIMARY KEY  IDENTITY(1,1),
        cliente_usuario int,
        cliente_nombre varchar(50),
        cliente_apellido varchar(50),
        cliente_fecha_nac smalldatetime,
        cliente_mail varchar(50),
        cliente_dni decimal(18,0),
        foreign key (cliente_usuario) references SELECTOS.Usuario(usuario_id)
    );


    CREATE TABLE SELECTOS.Rubro (
        rubro_id int PRIMARY KEY IDENTITY(1,1),
        rubro_descripcion varchar(50)
    );

    create table SELECTOS.SubRubro(
        sub_rubro_id int PRIMARY KEY  IDENTITY(1,1),
    --    sub_rubro_rubro_id int,
        sub_rubro_nombre varchar(50)
    --    foreign key (sub_rubro_rubro_id) references SELECTOS.Rubro(rubro_id)
    );

    create table SELECTOS.Modelo(
        modelo_codigo decimal(18,0) PRIMARY KEY,
        modelo_descripcion nvarchar(50)
    );

    create table SELECTOS.Marca(
        marca_id int PRIMARY KEY  IDENTITY(1,1),
        marca_descripcion nvarchar(50)
    );

    create table SELECTOS.Producto(
        producto_id int PRIMARY KEY  IDENTITY(1,1),
        producto_rubro int, -- agregado
        producto_sub_rubro int,
        producto_mod_codigo decimal(18,0),
        producto_marca_codigo int,
        producto_descripcion varchar(50),
        producto_precio decimal(18,2),
        foreign key (producto_rubro) references SELECTOS.Rubro(rubro_id), -- agregado
        foreign key (producto_sub_rubro)  references SELECTOS.SubRubro(sub_rubro_id),
        foreign key (producto_mod_codigo) references SELECTOS.Modelo(modelo_codigo),
        foreign key (producto_marca_codigo) references SELECTOS.Marca(marca_id)
    );

    create table SELECTOS.Concepto(
        concepto_id int PRIMARY KEY  IDENTITY(1,1),
        concepto_tipo varchar(50)
    );

    CREATE TABLE SELECTOS.Domicilio (
        domicilio_id int PRIMARY KEY  IDENTITY(1,1),
        domicilio_localidad int,
        --domicilio_provincia int,
        domicilio_usuario int,
        domicilio_piso decimal(18,0),
        domicilio_depto nvarchar(50),
        domicilio_calle nvarchar(50),
        domicilio_nro_calle decimal(18,0),
        domicilio_cp nvarchar(50),
        foreign key  (domicilio_localidad) references SELECTOS.Localidad(localidad_id),
       -- foreign key (domicilio_provincia) references SELECTOS.Provincia(provincia_id),
        foreign key (domicilio_usuario) references SELECTOS.Usuario(usuario_id)
    );

    CREATE TABLE SELECTOS.Publicacion(
        publicacion_id decimal(18,0) PRIMARY KEY,
        publicacion_vendedor  int,
        publicacion_producto  int,
        publicacion_almacen  decimal(18,0),
        publicacion_descripcion  varchar(100),
        publicacion_fecha smalldatetime,
        publicacion_fecha_v  smalldatetime,
        publicacion_precio  decimal(9,2),
        publicacion_costo  decimal(18,2),
        publicacion_porc_venta decimal(3,2),
        publicacion_stock_cantidad decimal(19,2),
        foreign key (publicacion_vendedor) references SELECTOS.Vendedor(vendedor_id),
        foreign key (publicacion_producto) references SELECTOS.Producto(producto_id),
        foreign key (publicacion_almacen) references SELECTOS.Almacen(almacen_id)
    );

    CREATE TABLE SELECTOS.DetalleFactura(
        detalle_factura_id  int,
        detalle_factura_concepto_id  int, 
        detalle_factura_publicacion  decimal(18,0),
        detalle_factura_cantidad decimal(18,0),
        detalle_factura_subtotal  decimal(18,2),
		detalle_factura_precio decimal(18,2)
        PRIMARY KEY (detalle_factura_id, detalle_factura_concepto_id),
        FOREIGN KEY (detalle_factura_id) REFERENCES SELECTOS.Factura(factura_id),
        FOREIGN KEY (detalle_factura_concepto_id) REFERENCES SELECTOS.Concepto(concepto_id)
    );

    CREATE TABLE SELECTOS.Venta(
        venta_id int PRIMARY KEY  IDENTITY(1,1),
        venta_cliente int,
        venta_codigo decimal(18,0),
        venta_fecha smalldatetime,
        venta_total decimal(18,2),
        foreign key (venta_cliente) references SELECTOS.Cliente(cliente_id)
    );

    CREATE TABLE SELECTOS.DetallePago(
        detalle_pago_id int PRIMARY KEY  IDENTITY(1,1),
        detalle_pago_nro_tarjeta nvarchar(50),
        detalle_pago_venc_tarjeta smalldatetime,
        detalle_pago_cant_cuotas decimal(18,2)
    );

    create table SELECTOS.TipoMedioDePago(
        tipo_medio_de_pago_id int PRIMARY KEY  IDENTITY(1,1),
        pago_tipo_medio_pago nvarchar(50)
    );

    CREATE TABLE SELECTOS.MediosPago(
        medio_pago_id int PRIMARY KEY  IDENTITY(1,1),
        medio_pago_tipo_medio_pago_id int,
        pago_medio_pago nvarchar(50),
        foreign key (medio_pago_tipo_medio_pago_id) references SELECTOS.TipoMedioDePago(tipo_medio_de_pago_id)
    );

    CREATE TABLE SELECTOS.Pago(
        pago_id int PRIMARY KEY  IDENTITY(1,1),
        pago_medio_pago int,
        pago_venta int,
        pago_fecha smalldatetime,
        pago_importe decimal(18,2),
        foreign key (pago_medio_pago) references SELECTOS.MediosPago(medio_pago_id),
        foreign key (pago_venta) references SELECTOS.Venta(venta_id)
    );


    create table SELECTOS.TipoEnvio(
        tipo_envio_id int PRIMARY KEY  IDENTITY(1,1),
        envio_tipo nvarchar(50)
    );

    create table SELECTOS.Envio(
        envio_id int PRIMARY KEY  IDENTITY(1,1),
        envio_venta int,
        envio_domicilio_id int,
        envio_tipo_id int,
        envio_fecha_programada smalldatetime,
        envio_hora_inicio decimal(18,2),
        envio_hora_fin_inicio decimal(18,2),
        envio_fecha_entrega smalldatetime,
        envio_costo decimal(18,2),
        foreign key (envio_venta) references SELECTOS.Venta(venta_id),
        foreign key (envio_domicilio_id) references SELECTOS.Domicilio(domicilio_id),
        foreign key (envio_tipo_id) references SELECTOS.TipoEnvio(tipo_envio_id)   
    ); -- VER DIAGRAMA

    create table SELECTOS.DetalleVenta(
        detalle_venta_id int PRIMARY KEY  IDENTITY(1,1),
        detalle_venta_publicacion decimal(18,0),
        detalle_venta_venta_id int,
        detalle_venta_cantidad decimal(18,0),
        detalle_venta_subtotal decimal(18,2),
        detalle_venta_precio decimal(18,2),
        foreign key (detalle_venta_publicacion) references SELECTOS.Publicacion(publicacion_id),
        foreign key (detalle_venta_venta_id) references SELECTOS.Venta(venta_id)
    );
    COMMIT TRANSACTION;
END;
GO
--------------------------------ELIMINAR TODO-----------------------------
CREATE PROCEDURE EliminarTodo
AS
BEGIN
BEGIN TRANSACTION;    
    DELETE FROM SELECTOS.DetalleVenta;
    DELETE FROM SELECTOS.Envio;
    DELETE FROM SELECTOS.Pago;
    DELETE FROM SELECTOS.MediosPago;
    DELETE FROM SELECTOS.DetallePago;
    DELETE FROM SELECTOS.Venta;
    DELETE FROM SELECTOS.DetalleFactura;
    DELETE FROM SELECTOS.Publicacion;
    DELETE FROM SELECTOS.Domicilio;
    DELETE FROM SELECTOS.Concepto;
    DELETE FROM SELECTOS.Producto;
    DELETE FROM SELECTOS.Marca;
    DELETE FROM SELECTOS.Modelo;
    DELETE FROM SELECTOS.SubRubro;
    DELETE FROM SELECTOS.Rubro;
    DELETE FROM SELECTOS.Cliente;
    DELETE FROM SELECTOS.Factura;
    DELETE FROM SELECTOS.Vendedor;
    DELETE FROM SELECTOS.Usuario;
    DELETE FROM SELECTOS.Almacen;
    DELETE FROM SELECTOS.Localidad;
    DELETE FROM SELECTOS.Provincia;
    DELETE FROM SELECTOS.TipoMedioDePago;
    DELETE FROM SELECTOS.TipoEnvio;
    DROP TABLE  SELECTOS.DetalleVenta;
    DROP TABLE  SELECTOS.Envio;
    DROP TABLE  SELECTOS.Pago;
    DROP TABLE  SELECTOS.MediosPago;
    DROP TABLE  SELECTOS.DetallePago;
    DROP TABLE  SELECTOS.Venta;
    DROP TABLE  SELECTOS.DetalleFactura;
    DROP TABLE  SELECTOS.Publicacion;
    DROP TABLE  SELECTOS.Domicilio;
    DROP TABLE  SELECTOS.Concepto;
    DROP TABLE  SELECTOS.Producto;
    DROP TABLE  SELECTOS.Marca;
    DROP TABLE  SELECTOS.Modelo;
    DROP TABLE  SELECTOS.SubRubro;
    DROP TABLE  SELECTOS.Rubro;
    DROP TABLE  SELECTOS.Cliente;
    DROP TABLE  SELECTOS.Factura;
    DROP TABLE  SELECTOS.Vendedor;
    DROP TABLE  SELECTOS.Usuario;
    DROP TABLE  SELECTOS.Almacen;
    DROP TABLE  SELECTOS.Localidad;
    DROP TABLE  SELECTOS.Provincia;
    DROP TABLE  SELECTOS.TipoMedioDePago;
    DROP TABLE  SELECTOS.TipoEnvio;
    --dropeo procedures
    DROP PROCEDURE  MigrarProvincia;
    DROP PROCEDURE  MigrarLocalidad;
    DROP PROCEDURE  MigrarAlmacen;
    DROP PROCEDURE  MigrarUsuario;
    DROP PROCEDURE  MigrarVendedor;
    DROP PROCEDURE  MigrarCliente;
    DROP PROCEDURE  MigrarFactura;
    DROP PROCEDURE  MigrarRubro;
    DROP PROCEDURE  MigrarSubRubro;
    DROP PROCEDURE  MigrarModelo;
    DROP PROCEDURE  MigrarMarca;
    DROP PROCEDURE  MigrarProducto;
    DROP PROCEDURE  MigrarConcepto;
    DROP PROCEDURE  MigrarDomicilio;
    DROP PROCEDURE  MigrarPublicacion;
    DROP PROCEDURE  MigrarDetalleFactura;
    DROP PROCEDURE  MigrarVenta;
    DROP PROCEDURE  MigrarDetallePago;
    DROP PROCEDURE  MigrarTipoMedioDePago;
    DROP PROCEDURE  MigrarMediosPago;
    DROP PROCEDURE  MigrarPago;
    DROP PROCEDURE  MigrarTipoEnvio;
    DROP PROCEDURE  MigrarEnvio;
    DROP PROCEDURE  MigrarDetalleVenta;
COMMIT TRANSACTION;
END;
GO

--------------------------------EXEC GENERAL----------------------------------------
CREATE PROCEDURE correrMigracion
AS
BEGIN
	exec CrearTablas;
	BEGIN TRANSACTION;
	exec MigrarProvincia;
	exec MigrarLocalidad;
	exec MigrarAlmacen;
    exec MigrarUsuario;
    exec MigrarVendedor;
    exec MigrarCliente;
    exec MigrarFactura;
    exec MigrarRubro;
    exec MigrarSubRubro;
    exec MigrarModelo;
    exec MigrarMarca;
    exec MigrarProducto;
    exec MigrarConcepto;
    exec MigrarDomicilio;
    exec MigrarPublicacion;
    exec MigrarDetalleFactura;
    exec MigrarVenta;
    exec MigrarDetallePago;
    exec MigrarTipoMedioDePago;
    exec MigrarMediosPago;
    exec MigrarPago;
    exec MigrarTipoEnvio;
    exec MigrarEnvio;
    exec MigrarDetalleVenta;
	
	COMMIT TRANSACTION;
END;
GO


exec correrMigracion;
