


CREATE FUNCTION SELECTOS.nro_cuatrimestre (@mes INT)
	RETURNS INT
	AS
	BEGIN
		DECLARE @cuatrimestre INT;

    
		IF @mes BETWEEN 1 AND 4
			SET @cuatrimestre = 1; 
		ELSE IF @mes BETWEEN 5 AND 8
			SET @cuatrimestre = 2;  
		ELSE IF @mes BETWEEN 9 AND 12
			SET @cuatrimestre = 3;  
		ELSE
			SET @cuatrimestre = NULL;  

		RETURN @cuatrimestre;
	END;
GO

/*STORE PROCEDURES - MIGRACION TRANSACCIONAL - BI*/


CREATE PROCEDURE MigrarMarcaBI
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_Marca(marca_nombre)
        SELECT DISTINCT m.marca_descripcion
        FROM SELECTOS.Marca m
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE MigrarSubRubroBI
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_SubRubro(sub_rubro_nombre)
        SELECT DISTINCT sr.sub_rubro_nombre
        FROM SELECTOS.SubRubro sr
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE MigrarRubroBI
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_Rubro(rubro_descripcion)
        SELECT DISTINCT r.rubro_descripcion
        FROM SELECTOS.Rubro r
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE MigrarTipoMedioDePagoBI
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_TipoMedioDePago(tipo_medio_pago_nombre)
        SELECT DISTINCT tp.pago_tipo_medio_pago
        FROM SELECTOS.TipoMedioDePago tp
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE CrearRangoHorario
AS
BEGIN
    INSERT INTO SELECTOS.BI_RangoHorario (rango_horario_inicio, rango_horario_fin)
    VALUES 
         ('00:00:00', '06:00:00'),
        ('06:00:00', '12:00:00'),
        ('12:00:00', '18:00:00'),
        ('18:00:00', '23:59:59');
END
GO

CREATE FUNCTION SELECTOS.obtenerRango (@fecha SMALLDATETIME)
RETURNS INT
AS
BEGIN
    DECLARE @hora TIME = CAST(@fecha AS TIME);

    RETURN (
        SELECT TOP 1 rango_horario_id
        FROM SELECTOS.BI_RangoHorario
        WHERE @hora >= rango_horario_inicio AND @hora < rango_horario_fin
    );
END;
GO

CREATE PROCEDURE CrearRangosEtarios
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_RangoEtario(rango_etario_inicio,rango_etario_fin)
        VALUES
		(NULL,25),
		(25,35),
		(35,50),
		(50,null)
	COMMIT TRANSACTION;
END
GO

/*funcion para asignar rango_etario*/
CREATE FUNCTION SELECTOS.fn_ObtenerRangoEtario(@cliente_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @edad INT;
    DECLARE @rango_id INT;

    -- Calcular la edad del cliente (sin considerar si ya cumpli� a�os)
    SELECT @edad = DATEDIFF(YEAR, c.cliente_fecha_nac, GETDATE())
    FROM SELECTOS.Cliente c
    WHERE cliente_id = @cliente_id;

    -- Buscar el rango correspondiente seg�n la edad
    SELECT @rango_id = rango_etario_id
    FROM SELECTOS.BI_RangoEtario
    WHERE (@edad >= ISNULL(rango_etario_inicio, 0)) 
      AND (@edad < ISNULL(rango_etario_fin, @edad + 1))

    RETURN @rango_id;
END;
go

CREATE PROCEDURE MigrarUbicacionesBI
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_Ubicacion(localidad_nombre,provincia_nombre)
        SELECT DISTINCT  l.localidad_nombre, pr.provincia_nombre
        FROM SELECTOS.Localidad l JOIN SELECTOS.Provincia pr ON l.localidad_provincia = pr.provincia_id
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE MigrarTiempoBI
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_Tiempo(tiempo_anio,tiempo_cuatrimestre,tiempo_mes)
        SELECT DISTINCT	
			year(env.envio_fecha_programada),
			SELECTOS.nro_cuatrimestre(month(env.envio_fecha_programada)),
			month(env.envio_fecha_programada)
        FROM SELECTOS.Envio env
		UNION
		SELECT DISTINCT
			year(env2.envio_fecha_entrega),
			SELECTOS.nro_cuatrimestre(month(env2.envio_fecha_entrega)),
			month(env2.envio_fecha_entrega)
		FROM SELECTOS.Envio env2
		UNION
		SELECT DISTINCT
			year(ve.venta_fecha),
			SELECTOS.nro_cuatrimestre(month(ve.venta_fecha)),
			month(ve.venta_fecha)
		FROM SELECTOS.Venta ve
		UNION
		SELECT DISTINCT
			year(pb.publicacion_fecha),
			SELECTOS.nro_cuatrimestre(month(pb.publicacion_fecha)),
			month(pb.publicacion_fecha)
		FROM SELECTOS.Publicacion pb
		UNION
		SELECT DISTINCT
			year(pb2.publicacion_fecha_v),
			SELECTOS.nro_cuatrimestre(month(pb2.publicacion_fecha_v)),
			month(pb2.publicacion_fecha_v)
		FROM SELECTOS.Publicacion pb2
		UNION
		SELECT DISTINCT
			year(f.factura_fecha),
			SELECTOS.nro_cuatrimestre(month(f.factura_fecha)),
			month(f.factura_fecha)
		FROM SELECTOS.Factura f
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE MigrarConceptoBI
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_Concepto(concepto_nombre)
        SELECT DISTINCT c.concepto_tipo
        FROM SELECTOS.Concepto c
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE MigrarPublicaciones
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_Publicaciones(tiempo_id,marca_id,sub_rubro_id,publicaciones_diferencias,publicaciones_cantidad,publicaciones_stock_total)
		SELECT
			tm.tiempo_id,
			m2.marca_id,
			sr2.sub_rubro_id,
			SUM(DATEDIFF(DAY,p.publicacion_fecha,p.publicacion_fecha_v)),
			count(p.publicacion_id),
			sum(p.publicacion_stock_cantidad)
		FROM SELECTOS.Publicacion p
		JOIN SELECTOS.Producto pr ON publicacion_producto = producto_id
		JOIN SELECTOS.SubRubro sr ON producto_sub_rubro = sub_rubro_id
		JOIN SELECTOS.BI_Tiempo tm ON
		tm.tiempo_anio = year(p.publicacion_fecha) and
		tm.tiempo_mes = month(p.publicacion_fecha) and
		tm.tiempo_cuatrimestre = SELECTOS.nro_cuatrimestre(month(p.publicacion_fecha))
		JOIN SELECTOS.Marca m1 ON pr.producto_marca_codigo = m1.marca_id
		jOIN SELECTOS.BI_Marca m2 ON m1.marca_descripcion = m2.marca_nombre
		JOIN SELECTOS.BI_SubRubro sr2 ON sr.sub_rubro_nombre = sr2.sub_rubro_nombre 
		GROUP BY tm.tiempo_id, m2.marca_id, sr2.sub_rubro_id
	COMMIT TRANSACTION;
END
GO
--103454
CREATE PROCEDURE MigrarVentas
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_Ventas(tiempo_id ,
			ubicacion_almacen_id ,
			ubicacion_cliente_id ,
			rango_horario_id,
			rubro_id ,
			tipo_medio_de_pago_id ,
			rango_etario_id ,
			ventas_importe ,
			ventas_cantidad,
			ventas_importe_cuotas,
			ventas_cantidad_cuotas)
		SELECT
			tm.tiempo_id,
			ub2.ubicacion_id,
			ub.ubicacion_id,
			rngh.rango_horario_id,
			rubrbi.rubro_id,
			tmpabi.tipo_medio_de_pago_id,
			rng.rango_etario_id,
			sum(dv.detalle_venta_subtotal),
			count(distinct v.venta_id),
			sum(IIF(tmpabi.tipo_medio_pago_nombre LIKE '%Tarjeta%',dv.detalle_venta_subtotal,0)),
			count(distinct IIF(tmpabi.tipo_medio_pago_nombre LIKE '%Tarjeta%',v.venta_id,NULL))
		FROM SELECTOS.DetalleVenta dv JOIN
		SELECTOS.Venta v ON dv.detalle_venta_venta_id = v.venta_id
		JOIN SELECTOS.BI_Tiempo tm ON
		tm.tiempo_anio = year(v.venta_fecha) and
		tm.tiempo_mes = month(v.venta_fecha) and
		tm.tiempo_cuatrimestre = SELECTOS.nro_cuatrimestre(month(v.venta_fecha))
		JOIN SELECTOS.Envio env ON env.envio_venta = v.venta_id
		JOIN SELECTOS.BI_Ubicacion ub ON
		ub.localidad_nombre = (select localidad_nombre from SELECTOS.Localidad l JOIN SELECTOS.Domicilio d
		ON l.localidad_id = d.domicilio_localidad where d.domicilio_id = env.envio_domicilio_id) and
		ub.provincia_nombre = (select provincia_nombre from SELECTOS.Provincia p JOIN SELECTOS.Localidad l2 ON
		l2.localidad_provincia = p.provincia_id JOIN SELECTOS.Domicilio d2 ON l2.localidad_id = d2.domicilio_localidad WHERE
		d2.domicilio_id = env.envio_domicilio_id)
		JOIN SELECTOS.Publicacion pb ON dv.detalle_venta_publicacion = pb.publicacion_id
		JOIN SELECTOS.PAGO pg ON pg.pago_venta = v.venta_id
		JOIN SELECTOS.MediosPago mp ON pg.pago_medio_pago = mp.medio_pago_id
		JOIN SELECTOS.TipoMedioDePago tmpa on tmpa.tipo_medio_de_pago_id = mp.medio_pago_tipo_medio_pago_id 
		JOIN SELECTOS.BI_TipoMedioDePago tmpabi ON tmpa.pago_tipo_medio_pago = tmpabi.tipo_medio_pago_nombre
		JOIN SELECTOS.Cliente cl ON cl.cliente_id = v.venta_cliente 
		JOIN SELECTOS.Producto p ON pb.publicacion_producto = p.producto_id
		join selectos.Rubro rubr ON rubr.rubro_id = p.producto_rubro
		JOIN SELECTOS.BI_Rubro rubrbi ON rubrbi.rubro_descripcion = rubr.rubro_descripcion 
		JOIN SELECTOS.BI_RangoEtario rng ON rng.rango_etario_id = SELECTOS.fn_ObtenerRangoEtario(cl.cliente_id)
		--UBICACION ALMACEN
		--JOIN SELECTOS.Publicacion ON publicacion_id = detalle_venta_publicacion
		JOIN SELECTOS.Almacen alm ON pb.publicacion_almacen = alm.almacen_id 
		JOIN SELECTOS.BI_Ubicacion ub2 ON
		ub2.localidad_nombre = (select localidad_nombre from SELECTOS.Localidad l where l.localidad_id = alm.almacen_localidad) and
		ub2.provincia_nombre = (select provincia_nombre from SELECTOS.Provincia p where p.provincia_id = alm.almacen_provincia)
		--RANGO_HORARIO
		JOIN SELECTOS.BI_RangoHorario rngh on rngh.rango_horario_id = SELECTOS.obtenerRango(v.venta_fecha)
		GROUP BY tm.tiempo_id, ub2.ubicacion_id,
			ub.ubicacion_id,
			rngh.rango_horario_id,rubrbi.rubro_id,tmpabi.tipo_medio_de_pago_id,rng.rango_etario_id
		
			
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE MigrarFacturasVendedor 
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_FacturasVendedor(tiempo_id, ubicacion_id, concepto_id, ventas_importe, ventas_cantidad)
		SELECT tm.tiempo_id, ub.ubicacion_id, 
		c.concepto_id, 
		isnull(sum(df.detalle_factura_subtotal),0), 
		count(df.detalle_factura_id)
		FROM SELECTOS.DetalleFactura df
		JOIN SELECTOS.Factura f on f.factura_id = df.detalle_factura_id
		JOIN SELECTOS.BI_Tiempo tm ON
		tm.tiempo_anio = year(f.factura_fecha) and
		tm.tiempo_mes = month(f.factura_fecha) and
		tm.tiempo_cuatrimestre = SELECTOS.nro_cuatrimestre(month(f.factura_fecha))
		JOIN SELECTOS.BI_Concepto c ON c.concepto_nombre = (select concepto_tipo from SELECTOS.Concepto where concepto_id = df.detalle_factura_concepto_id)
		LEFT JOIN SELECTOS.BI_Ubicacion ub
		ON ub.localidad_nombre = 
		(select localidad_nombre from SELECTOS.Localidad JOIN SELECTOS.Domicilio on localidad_id = domicilio_localidad JOIN SELECTOS.Usuario ON
		domicilio_usuario = usuario_id JOIN SELECTOS.Vendedor ON vendedor_usuario = usuario_id where vendedor_id = f.factura_vendedor)
		and ub.provincia_nombre = 
		(select provincia_nombre from SELECTOS.Provincia JOIN SELECTOS.Localidad ON localidad_provincia = provincia_id JOIN SELECTOS.Domicilio on localidad_id = domicilio_localidad JOIN SELECTOS.Usuario ON
		domicilio_usuario = usuario_id JOIN SELECTOS.Vendedor ON vendedor_usuario = usuario_id where vendedor_id = f.factura_vendedor)
		GROUP BY tm.tiempo_id, 
		ub.ubicacion_id,
		c.concepto_id
	COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE MigrarEnvios
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO SELECTOS.BI_Envios(ubicacion_almacen_id,ubicacion_cliente_id,tiempo_id,envios_concretados,envios_costos_totales,envios_totales)
        SELECT 
		ub2.ubicacion_id, 
		ub.ubicacion_id,
		tm.tiempo_id, 
		count(CASE WHEN CAST(env.envio_fecha_entrega as DATE) <= CAST(env.envio_fecha_programada as DATE) THEN envio_id ELSE NULL END), 
		isnull(sum(isnull(envio_costo,0)),0),
		count(envio_id)
        FROM SELECTOS.Envio env
		--UBICACION CLIENTE
		JOIN SELECTOS.BI_Ubicacion ub ON
		ub.localidad_nombre = (select localidad_nombre from SELECTOS.Localidad l JOIN SELECTOS.Domicilio d
		ON l.localidad_id = d.domicilio_localidad where d.domicilio_id = env.envio_domicilio_id) and
		ub.provincia_nombre = (select provincia_nombre from SELECTOS.Provincia p JOIN SELECTOS.Localidad l2 ON
		l2.localidad_provincia = p.provincia_id JOIN SELECTOS.Domicilio d2 ON l2.localidad_id = d2.domicilio_localidad WHERE
		d2.domicilio_id = env.envio_domicilio_id)
		--UBICACION ALMACEN
		JOIN SELECTOS.Venta ON env.envio_venta = venta_id
		JOIN SELECTOS.DetalleVenta ON detalle_venta_venta_id = venta_id
		JOIN SELECTOS.Publicacion ON publicacion_id = detalle_venta_publicacion
		JOIN SELECTOS.Almacen alm ON publicacion_almacen = alm.almacen_id 
		JOIN SELECTOS.BI_Ubicacion ub2 ON
		ub2.localidad_nombre = (select localidad_nombre from SELECTOS.Localidad l where l.localidad_id = alm.almacen_localidad) and
		ub2.provincia_nombre = (select provincia_nombre from SELECTOS.Provincia p where p.provincia_id = alm.almacen_provincia)
		--TIEMPO
		JOIN SELECTOS.BI_Tiempo tm ON 
		tm.tiempo_anio = year(env.envio_fecha_programada) and
		tm.tiempo_mes = month(env.envio_fecha_programada) and
		tm.tiempo_cuatrimestre = SELECTOS.nro_cuatrimestre(month(env.envio_fecha_programada))
		GROUP BY ub2.ubicacion_id,ub.ubicacion_id, tm.tiempo_id
		
	COMMIT TRANSACTION;
END
GO



/*CREACION TABLAS BI*/


CREATE PROCEDURE CrearTablasBI
AS
BEGIN
    BEGIN TRANSACTION;

/*************DIMENSIONES**************/

	CREATE TABLE SELECTOS.BI_Marca (
    marca_id INT PRIMARY KEY IDENTITY(1,1),
    marca_nombre nVARCHAR(50)
);

CREATE TABLE SELECTOS.BI_Ubicacion (
    ubicacion_id INT PRIMARY KEY IDENTITY(1,1),
    localidad_nombre NVARCHAR(50),
    provincia_nombre VARCHAR(50)
);

CREATE TABLE SELECTOS.BI_Tiempo (
    tiempo_id INT PRIMARY KEY IDENTITY(1,1),
    tiempo_anio INT,
    tiempo_cuatrimestre INT,
    tiempo_mes INT
);
/*
CREATE TABLE SELECTOS.BI_TipoEnvio (
    tipo_envio_id INT PRIMARY KEY IDENTITY(1,1),
    tipo_envio_nombre NVARCHAR(50)
);*/

CREATE TABLE SELECTOS.BI_Rubro (
    rubro_id INT PRIMARY KEY IDENTITY(1,1),
    rubro_descripcion VARCHAR(50)
);

CREATE TABLE SELECTOS.BI_SubRubro (
    sub_rubro_id INT PRIMARY KEY IDENTITY(1,1),
    sub_rubro_nombre VARCHAR(50)
);

CREATE TABLE SELECTOS.BI_RangoHorario (
    rango_horario_id INT PRIMARY KEY IDENTITY(1,1),
    rango_horario_inicio TIME,
    rango_horario_fin TIME
);

CREATE TABLE SELECTOS.BI_Concepto (
    concepto_id INT PRIMARY KEY IDENTITY(1,1),
    concepto_nombre VARCHAR(50)
);


CREATE TABLE SELECTOS.BI_RangoEtario (
    rango_etario_id INT PRIMARY KEY identity(1,1),
    rango_etario_inicio INT,
    rango_etario_fin INT
);

CREATE TABLE SELECTOS.BI_TipoMedioDePago (
    tipo_medio_de_pago_id INT PRIMARY KEY identity(1,1),
    tipo_medio_pago_nombre NVARCHAR(50)
);


/********************************************/
/*********HECHOS***********************/

CREATE TABLE SELECTOS.BI_Publicaciones (
    tiempo_id INT,
    marca_id INT,
    sub_rubro_id INT,
    publicaciones_diferencias INT,
    publicaciones_cantidad INT,
    publicaciones_stock_total DECIMAL(10, 2),
    PRIMARY KEY (tiempo_id, marca_id, sub_rubro_id),
    FOREIGN KEY (tiempo_id) REFERENCES SELECTOS.BI_Tiempo(tiempo_id),
    FOREIGN KEY (sub_rubro_id) REFERENCES SELECTOS.BI_SubRubro(sub_rubro_id),
	FOREIGN KEY (marca_id) REFERENCES SELECTOS.BI_Marca(marca_id)
);


CREATE TABLE SELECTOS.BI_Envios(
	ubicacion_almacen_id INT,
	ubicacion_cliente_id INT,
	tiempo_id INT,
    envios_concretados INT,
	envios_costos_totales decimal(18,2),
    envios_totales INT,
    PRIMARY KEY (ubicacion_almacen_id,ubicacion_cliente_id,tiempo_id),
    FOREIGN KEY (ubicacion_almacen_id) REFERENCES SELECTOS.BI_Ubicacion(ubicacion_id),
	FOREIGN KEY (ubicacion_cliente_id) REFERENCES SELECTOS.BI_Ubicacion(ubicacion_id),
	FOREIGN KEY (tiempo_id) REFERENCES SELECTOS.BI_Tiempo(tiempo_id)

)




CREATE TABLE SELECTOS.BI_Ventas (
    tiempo_id INT,
    ubicacion_almacen_id INT,
	ubicacion_cliente_id INT,
	rango_horario_id INT,
    rubro_id INT,
    tipo_medio_de_pago_id INT,
    rango_etario_id INT,
    ventas_importe DECIMAL(18, 2),
    ventas_cantidad INT,
	ventas_importe_cuotas DECIMAL(18,2),
	ventas_cantidad_cuotas INT,
	--ventas_nro_cuotas INT
    PRIMARY KEY (tiempo_id, ubicacion_almacen_id, ubicacion_cliente_id,rango_horario_id, rubro_id, tipo_medio_de_pago_id, rango_etario_id),
    FOREIGN KEY (tiempo_id) REFERENCES SELECTOS.BI_Tiempo(tiempo_id),
    FOREIGN KEY (ubicacion_almacen_id) REFERENCES SELECTOS.BI_Ubicacion(ubicacion_id),
	FOREIGN KEY (ubicacion_cliente_id) REFERENCES SELECTOS.BI_Ubicacion(ubicacion_id),
	FOREIGN KEY (rango_horario_id) REFERENCES SELECTOS.BI_RangoHorario(rango_horario_id),
    FOREIGN KEY (rubro_id) REFERENCES SELECTOS.BI_Rubro(rubro_id),
	FOREIGN KEY (tipo_medio_de_pago_id) REFERENCES SELECTOS.BI_TipoMedioDePago(tipo_medio_de_pago_id),
	FOREIGN KEY (rango_etario_id) REFERENCES SELECTOS.BI_RangoEtario(rango_etario_id)
);

CREATE TABLE SELECTOS.BI_FacturasVendedor (
    tiempo_id INT,
    ubicacion_id INT,
    concepto_id INT,
    ventas_importe DECIMAL(18, 2),
    ventas_cantidad INT,
    PRIMARY KEY (tiempo_id, ubicacion_id, concepto_id),
    FOREIGN KEY (tiempo_id) REFERENCES SELECTOS.BI_Tiempo(tiempo_id),
    FOREIGN KEY (ubicacion_id) REFERENCES SELECTOS.BI_Ubicacion(ubicacion_id),
    FOREIGN KEY (concepto_id) REFERENCES SELECTOS.BI_Concepto(concepto_id)
);








	COMMIT TRANSACTION;
END
GO




CREATE PROCEDURE correrMigracionBI
AS
BEGIN
	exec CrearTablasBI;
	BEGIN TRANSACTION;

	
	EXEC MigrarMarcaBI;
	EXEC MigrarSubRubroBI;
	EXEC MigrarRubroBI;
	EXEC MigrarTipoMedioDePagoBI;
	EXEC CrearRangosEtarios;
	EXEC CrearRangoHorario;
	EXEC MigrarUbicacionesBI;
	EXEC MigrarTiempoBI;
	EXEC MigrarConceptoBI;
	--EXEC MigrarVentasCliente;
	EXEC MigrarFacturasVendedor;
	--EXEC MigrarEnviosCostoBI;
	--EXEC MigrarEnviosCumplimientoBI;
	EXEC MigrarEnvios;
	EXEC MigrarVentas;
	EXEC MigrarPublicaciones;
	
	COMMIT TRANSACTION;
END;
GO





exec correrMigracionBI;
go

/*VISTAS*/

/*VISTA 1*/
CREATE VIEW SELECTOS.promedio_tiempo_publicacion_por_cuatrimestre AS
select s.sub_rubro_id rubro_id, s.sub_rubro_nombre rubro, t.tiempo_cuatrimestre cuatrimestre, t.tiempo_anio anio, isnull(avg(p.publicaciones_diferencias),0) promedio_de_tiempo
from SELECTOS.BI_Publicaciones p
	join SELECTOS.BI_tiempo t on t.tiempo_id = p.tiempo_id
	join SELECTOS.BI_SubRubro s on s.sub_rubro_id = p.sub_rubro_id
group by t.tiempo_anio, t.tiempo_cuatrimestre, s.sub_rubro_id, s.sub_rubro_nombre 
	
GO

/*VISTA 2*/
CREATE VIEW SELECTOS.promedio_stock_inicial AS
select p.marca_id marca_id , m.marca_nombre marca,  t.tiempo_anio anio, (sum(p.publicaciones_stock_total) / sum(p.publicaciones_cantidad)) promedio_stock
	from SELECTOS.BI_Publicaciones as p
	join SELECTOS.BI_tiempo t on  p.tiempo_id = t.tiempo_id
	join SELECTOS.BI_Marca m on p.marca_id = m.marca_id
group by p.marca_id, m.marca_nombre , t.tiempo_anio
GO

/*VISTA 3*/
CREATE VIEW SELECTOS.promedio_mensual AS
SELECT 	t.tiempo_anio,
	t.tiempo_mes,
	u.provincia_nombre,
	isnull(avg(v.ventas_importe),0) as [Promedio Ventas]
FROM SELECTOS.BI_Ventas v
	JOIN SELECTOS.BI_Tiempo t
		ON t.tiempo_id = v.tiempo_id
	JOIN SELECTOS.BI_Ubicacion u
		ON v.ubicacion_almacen_id = u.ubicacion_id
GROUP BY t.tiempo_anio,
	t.tiempo_mes,
	u.provincia_nombre

GO

/*VISTA 4*/
CREATE VIEW SELECTOS.rendimiento_rubros AS
SELECT	r.rubro_descripcion,
		t.tiempo_anio,
		t.tiempo_cuatrimestre,
		isnull(sum(v.ventas_cantidad),0) AS CantidadVentas
FROM SELECTOS.BI_Ventas v 
	JOIN SELECTOS.BI_Rubro r
		ON v.rubro_id = r.rubro_id
	JOIN SELECTOS.BI_Tiempo t
		ON v.tiempo_id = t.tiempo_id
	JOIN SELECTOS.BI_RangoEtario re
		ON v.rango_etario_id = re.rango_etario_id
	JOIN SELECTOS.BI_Ubicacion u
		ON v.ubicacion_cliente_id = u.ubicacion_id
where v.rubro_id in (select top 5 v1.rubro_id from selectos.bi_ventas v1
					join selectos.BI_tiempo t1 on t1.tiempo_id = v1.tiempo_id
					where t.tiempo_cuatrimestre = t1.tiempo_cuatrimestre and t.tiempo_anio = t1.tiempo_anio
					group by v1.rango_etario_id, v1.ubicacion_cliente_id, v1.rubro_id
					order by  sum(v1.ventas_cantidad) desc )
group by r.rubro_descripcion, t.tiempo_anio, t.tiempo_cuatrimestre

GO

/*VISTA 6*/
CREATE VIEW SELECTOS.pago_cuotas AS
select u.localidad_nombre, 
			t.tiempo_mes,
			t.tiempo_anio, 
			tmp.tipo_medio_pago_nombre, 
			sum(v.ventas_importe_cuotas) as importe_cuotas
from SELECTOS.BI_Ventas v
		join SELECTOS.BI_Ubicacion u on u.ubicacion_id =  v.ubicacion_cliente_id
		join SELECTOS.BI_TipoMedioDePago tmp on v.tipo_medio_de_pago_id = tmp.tipo_medio_de_pago_id
		join SELECTOS.BI_Tiempo t on t.tiempo_id = v.tiempo_id
where v.ubicacion_cliente_id in (select top 3 u.ubicacion_id
						from SELECTOS.BI_Ventas v1 
						join SELECTOS.BI_Tiempo t1 on v1.tiempo_id = t1.tiempo_id
						join SELECTOS.BI_Ubicacion u on v1.ubicacion_cliente_id = u.ubicacion_id 
						where t.tiempo_mes = t1.tiempo_mes and t.tiempo_anio = t1.tiempo_anio and v1.tipo_medio_de_pago_id = v.tipo_medio_de_pago_id
						group by  v1.tipo_medio_de_pago_id, u.ubicacion_id , t1.tiempo_mes, t1.tiempo_anio
						order by sum(v1.ventas_importe_cuotas) desc
						)
group by u.localidad_nombre, t.tiempo_mes, t.tiempo_anio, tmp.tipo_medio_pago_nombre, v.ubicacion_cliente_id, v.tipo_medio_de_pago_id
	
GO

/*VISTA 7*/
CREATE VIEW SELECTOS.porcentaje_cumplimiento_publ AS
SELECT
	t.tiempo_anio as anio,
	t.tiempo_mes as mes,
	u.provincia_nombre as provincia,
	sum(e.envios_concretados)/sum(e.envios_totales) * 100 as porcentaje_cumplimiento
FROM
	SELECTOS.BI_Envios e
	JOIN SELECTOS.BI_Ubicacion u on u.ubicacion_id = e.ubicacion_almacen_id
	JOIN SELECTOS.BI_tiempo t on  e.tiempo_id = t.tiempo_id
	group by t.tiempo_anio, t.tiempo_mes, u.provincia_nombre
GO

/*VISTA 8*/
CREATE VIEW SELECTOS.localidades_mayor_costo AS
SELECT TOP 5
	u.localidad_nombre,
	u.provincia_nombre,
	sum(e.envios_costos_totales)/sum(e.envios_totales) as costo_promedio
FROM 
	SELECTOS.BI_Envios e
	JOIN SELECTOS.BI_Ubicacion u on u.ubicacion_id = e.ubicacion_cliente_id
GROUP BY u.localidad_nombre, u.provincia_nombre
	
GO

/*VISTA 9*/
CREATE VIEW SELECTOS.porcentaje_facturacion AS
SELECT
	c.concepto_nombre,
	t.tiempo_mes,
	t.tiempo_anio,
	sum(ventas_importe)/(
		select sum(ventas_importe) FROM 
			SELECTOS.BI_FacturasVendedor f2
		JOIN SELECTOS.BI_Tiempo t2 on t2.tiempo_id = f2.tiempo_id
		where t2.tiempo_mes = t.tiempo_mes and t2.tiempo_anio = t.tiempo_anio
	) * 100 as porcentaje_facturacion
FROM 
	SELECTOS.BI_FacturasVendedor f
	JOIN SELECTOS.BI_Tiempo t on t.tiempo_id = f.tiempo_id
	JOIN SELECTOS.BI_Concepto c on c.concepto_id = f.concepto_id
GROUP BY c.concepto_nombre, t.tiempo_mes, t.tiempo_anio

GO

/*VISTA 10*/
CREATE VIEW SELECTOS.facturacion_provincia AS
SELECT
	u.provincia_nombre,
	t.tiempo_cuatrimestre,
	t.tiempo_anio,
	sum(f.ventas_importe) as monto_facturado
FROM SELECTOS.BI_FacturasVendedor f
	JOIN SELECTOS.BI_Ubicacion u on u.ubicacion_id = f.ubicacion_id
	JOIN SELECTOS.BI_Tiempo t on t.tiempo_id = f.tiempo_id
GROUP BY t.tiempo_anio, t.tiempo_cuatrimestre, u.provincia_nombre
	


