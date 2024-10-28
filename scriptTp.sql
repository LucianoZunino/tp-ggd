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
 DROP TABLE IF EXISTS SELECTOS.DetalleVenta;
 DROP TABLE IF EXISTS SELECTOS.Envio;
 DROP TABLE IF EXISTS SELECTOS.Pago;
 DROP TABLE IF EXISTS SELECTOS.MediosPago;
 DROP TABLE IF EXISTS SELECTOS.DetallePago;
 DROP TABLE IF EXISTS SELECTOS.Venta;
 DROP TABLE IF EXISTS SELECTOS.DetalleFactura;
 DROP TABLE IF EXISTS SELECTOS.Publicacion;
 DROP TABLE IF EXISTS SELECTOS.Domicilio;
 DROP TABLE IF EXISTS SELECTOS.Concepto;
 DROP TABLE IF EXISTS SELECTOS.Producto;
 DROP TABLE IF EXISTS SELECTOS.Marca;
 DROP TABLE IF EXISTS SELECTOS.Modelo;
 DROP TABLE IF EXISTS SELECTOS.SubRubro;
 DROP TABLE IF EXISTS SELECTOS.Rubro;
 DROP TABLE IF EXISTS SELECTOS.Cliente;
 DROP TABLE IF EXISTS SELECTOS.Factura;
 DROP TABLE IF EXISTS SELECTOS.Vendedor;
 DROP TABLE IF EXISTS SELECTOS.Usuario;
 DROP TABLE IF EXISTS SELECTOS.Almacen;
 DROP TABLE IF EXISTS SELECTOS.Localidad;
 DROP TABLE IF EXISTS SELECTOS.Provincia;
 DROP TABLE IF EXISTS SELECTOS.TipoMedioDePago;
 DROP TABLE IF EXISTS SELECTOS.TipoEnvio;
COMMIT TRANSACTION;
END;

exec EliminarTodo

exec CrearTablas

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
        localidad_nombre varchar(50),
        foreign key (localidad_provincia) references SELECTOS.Provincia(provincia_id)
    );

    create table SELECTOS.Almacen (
        almacen_id int PRIMARY KEY,
        almacen_localidad int,
        almacen_nro_calle decimal(9,2),
        almacen_costo_dia_al decimal (9,2),
        almacen_calle varchar(100),
        foreign key (almacen_localidad) references SELECTOS.Localidad(localidad_id)
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
        modelo_codigo decimal(18,0) PRIMARY KEY  IDENTITY(1,1),
        modelo_descripcion varchar(50)
    );

    create table SELECTOS.Marca(
        marca_id int PRIMARY KEY  IDENTITY(1,1),
        producto_marca varchar(50)
    );

    create table SELECTOS.Producto(
        producto_id int PRIMARY KEY  IDENTITY(1,1),
        sub_rubro_rubro_id int, -- agregado
        producto_sub_rubro int,
        producto_mod_codigo decimal(18,0),
        producto_marca_codigo int,
        producto_descripcion varchar(50),
        producto_precio decimal(18,2),
        foreign key (sub_rubro_rubro_id) references SELECTOS.Rubro(rubro_id), -- agregado
        foreign key (producto_sub_rubro)  references SELECTOS.SubRubro(sub_rubro_id),
        foreign key (producto_mod_codigo) references SELECTOS.Modelo(modelo_codigo),
        foreign key (producto_marca_codigo) references SELECTOS.Marca(marca_id)
    );

    create table SELECTOS.Concepto(
        concepto_id int PRIMARY KEY  IDENTITY(1,1),
        concepto_tipo varchar(50),
        concepto_precio_unitario decimal(18,2)
    );

    CREATE TABLE SELECTOS.Domicilio (
        domicilio_id int PRIMARY KEY  IDENTITY(1,1),
        domicilio_localidad int,
        domicilio_provincia int,
        domicilio_usuario int,
        domicilio_piso decimal(18,0),
        domicilio_depto varchar(50),
        domicilio_calle varchar(50),
        domicilio_nro_calle decimal(18,0),
        domicilio_cp varchar(50),
        foreign key  (domicilio_localidad) references SELECTOS.Localidad(localidad_id),
        foreign key (domicilio_provincia) references SELECTOS.Provincia(provincia_id),
        foreign key (domicilio_usuario) references SELECTOS.Usuario(usuario_id)
    );

    CREATE TABLE SELECTOS.Publicacion(
        publicacion_id decimal(18,0) PRIMARY KEY  IDENTITY(1,1),
        publicacion_vendedor  int,
        publicacion_producto  int,
        publicacion_almacen  int,
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
        detalle_factura_subtotal  decimal(18,2)
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
        detalle_pago_nro_tarjeta varchar(50),
        detalle_pago_venc_tarjeta smalldatetime,
        detalle_pago_cant_cuotas decimal(18,2)
    );

    create table SELECTOS.TipoMedioDePago(
        tipo_medio_de_pago_id int PRIMARY KEY  IDENTITY(1,1),
        pago_tipo_medio_pago varchar(50)
    );

    CREATE TABLE SELECTOS.MediosPago(
        medio_pago_id int PRIMARY KEY  IDENTITY(1,1),
        medio_pago_tipo_medio_pago_id int,
        pago_medio_pago varchar(50),
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
        envio_tipo varchar(50)
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








