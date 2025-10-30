------------------ CREACIÓN DE BBDD -------------------

-- Cambiar al contexto master
USE master;
GO

-- Eliminar la base
IF DB_ID('COM5600_G04') IS NOT NULL
BEGIN
	DROP DATABASE COM5600_G04;
	   PRINT 'Base de datos COM5600_G04 Borrada.';
END	
GO

-- Creo la base
IF DB_ID('COM5600_G04') IS NULL
BEGIN
    CREATE DATABASE COM5600_G04 COLLATE Latin1_General_CI_AS;
	    PRINT 'Base de datos COM5600_G04 Creada.';
END	
GO

-- Cambiar al contexto COM5600_G04
USE COM5600_G04;
GO

------------------ CREACIÓN DE TABLAS -------------------
-- Cree las entidades y relaciones. Incluya restricciones y claves --

------------- Consorcio ----------
IF OBJECT_ID('Administracion') IS NULL
BEGIN
	CREATE TABLE Administracion 
	(
		Id_Administracion int IDENTITY(1,1) PRIMARY KEY,
		Razon_Social varchar(100),
		CUIT varchar(20),
		Direccion varchar(100),
		Telefono varchar(20),
		Email varchar(100),
		Cuenta_Deposito varchar(22),
	);
END

IF OBJECT_ID('Consorcio') IS NULL
BEGIN
	CREATE TABLE Consorcio 
	(
		Id_Consorcio int IDENTITY(1,1) PRIMARY KEY,
		Id_Administracion int,
		Nombre varchar(100),
		Domicilio varchar(100),
		Cant_unidades smallint,
		MetrosCuadrados int,
		Precio_Cochera decimal(9,2),
		Precio_Baulera decimal(9,2),
		CONSTRAINT FK_Consorcio_Administracion FOREIGN KEY (Id_Administracion) REFERENCES Administracion(Id_Administracion),
	);
END

IF OBJECT_ID('Proovedores') IS NULL
BEGIN
	CREATE TABLE Proovedores 
		(
			Id_Proovedor int IDENTITY(1,1) PRIMARY KEY,
			Nombre_Gasto varchar(30),
			Descripcion varchar(50),
			Cuenta varchar(30),
			Id_Consorcio int,
			CONSTRAINT FK_Proovedores_Consorcio FOREIGN KEY (Id_Consorcio) REFERENCES Consorcio(Id_Consorcio),
		);
END

IF OBJECT_ID('Estado_Financiero') IS NULL
BEGIN
	CREATE TABLE Estado_Financiero 
	(
		Id_Estado_Financiero int IDENTITY(1,1) PRIMARY KEY,
		Id_Consorcio int,
		Saldo_Anterior decimal(10,2),
		Periodo datetime,
		Ingreso_Exp_Termino decimal(10,2),
		Ingreso_Exp_Adeudada decimal(10,2),
		Ingreso_Exp_Adelantada decimal(10,2),
		Egresos_Mes decimal(10,2),
		Saldo_Cierre decimal(10,2),
		CONSTRAINT FK_Estado_Financiero_Consorcio FOREIGN KEY (Id_Consorcio) REFERENCES Consorcio(Id_Consorcio),
	);
END

-------------Gastos Ordinarios ----------

IF OBJECT_ID('Tipo_Gasto') IS NULL
BEGIN
	CREATE TABLE Tipo_Gasto
	(
	Id_Tipo_Gasto int IDENTITY(1,1) PRIMARY KEY,
	Nombre varchar(50),
	);
END


IF OBJECT_ID('Gasto_Ordinario') IS NULL
BEGIN
	CREATE TABLE Gasto_Ordinario 
	(
		Id_gasto int IDENTITY(1,1) PRIMARY KEY,
		Id_Consorcio int,
		Id_Tipo_Gasto int,
		Fecha date,
		Importe_Total decimal(10,2),
		Descripcion varchar(50),
		CONSTRAINT FK_Gasto_Ordinario_Consorcio FOREIGN KEY (Id_Consorcio) REFERENCES Consorcio(Id_Consorcio),
		CONSTRAINT FK_Gasto_Ordinario_Tipo_Gasto FOREIGN KEY (Id_Tipo_Gasto) REFERENCES Tipo_Gasto(Id_Tipo_Gasto),
	);
END


IF OBJECT_ID('Gasto_Administracion') IS NULL
BEGIN
	CREATE TABLE Gasto_Administracion
	(
		Id_gasto int PRIMARY KEY,
		Nro_Factura int,
		CONSTRAINT FK_Gasto_Administracion_Gasto_Ordinario FOREIGN KEY (Id_gasto) REFERENCES Gasto_Ordinario(Id_gasto),
	);
END


IF OBJECT_ID('Gasto_Seguro') IS NULL
BEGIN
	CREATE TABLE Gasto_Seguro
	(
		Id_gasto int PRIMARY KEY,
		Nro_Factura int,
		NombreSeguro varchar(50),
		CONSTRAINT FK_Gasto_Seguro_Gasto_Ordinario FOREIGN KEY (Id_gasto) REFERENCES Gasto_Ordinario(Id_gasto),
	);
END


IF OBJECT_ID('Gasto_General') IS NULL
BEGIN
	CREATE TABLE Gasto_General
	(
		Id_gasto int PRIMARY KEY,
		Descripcion varchar(100),
		Nombre_Responsable varchar(60),
		Nro_factura varchar(50),
		CONSTRAINT FK_Gasto_General_Gasto_Ordinario FOREIGN KEY (Id_gasto) REFERENCES Gasto_Ordinario(Id_gasto),
	);
END


IF OBJECT_ID('Empresa_Limpieza') IS NULL
BEGIN
	CREATE TABLE Empresa_Limpieza
	(
		Id_gasto int PRIMARY KEY,
		Nombre_Empresa varchar(50),
		Nro_factura int,
		CONSTRAINT FK_Empresa_Limpieza_Gasto_Ordinario FOREIGN KEY (Id_gasto) REFERENCES Gasto_Ordinario(Id_gasto),
	);
END


IF OBJECT_ID('Gasto_Mantenimiento') IS NULL
BEGIN
	CREATE TABLE Gasto_Mantenimiento
	(
		Id_gasto int PRIMARY KEY,
		CBU varchar(22),
		CONSTRAINT FK_Gasto_Mantenimiento_Gasto_Ordinario FOREIGN KEY (Id_gasto) REFERENCES Gasto_Ordinario(Id_gasto),
	);
END

IF OBJECT_ID('Empleado_Limpieza') IS NULL
BEGIN
	CREATE TABLE Empleado_Limpieza
	(
		Id_gasto int PRIMARY KEY,
		Sueldo decimal(10,2),
		Factura_Productos decimal(10,2),
		CONSTRAINT FK_Empleado_Limpieza_Gasto_Ordinario FOREIGN KEY (Id_gasto) REFERENCES Gasto_Ordinario(Id_gasto),
	);
END


IF OBJECT_ID('Tipo_Servicio') IS NULL
BEGIN
	CREATE TABLE Tipo_Servicio
	(
		Id_Tipo_Servicio int IDENTITY(1,1) PRIMARY KEY,
		Nombre varchar(50),
	);
END

IF OBJECT_ID('Gasto_Servicio_Publico') IS NULL
BEGIN
	CREATE TABLE Gasto_Servicio_Publico
	(
		Id_gasto int PRIMARY KEY,
		Id_Tipo_Servicio int,
		Nombre_Empresa varchar(50),
		Nro_Factura int,
		CONSTRAINT FK_Gasto_Servicio_Publico_Gasto_Ordinario FOREIGN KEY (Id_gasto) REFERENCES Gasto_Ordinario(Id_gasto),
		CONSTRAINT FK_Gasto_Servicio_Publico_Tipo_Servicio FOREIGN KEY (Id_Tipo_Servicio) REFERENCES Tipo_Servicio(Id_Tipo_Servicio),
	);
END

-------------Gastos Extraordinarios ----------

IF OBJECT_ID('Tipo_Pago_Extraordinario') IS NULL
BEGIN
	CREATE TABLE Tipo_Pago_Extraordinario
	(
		Id_tipo_pago int IDENTITY(1,1) PRIMARY KEY, 
		Nombre varchar(50),
	);
END

IF OBJECT_ID('Gasto_Extraordinario') IS NULL
BEGIN
	CREATE TABLE Gasto_Extraordinario 
	(
		Id_gasto int IDENTITY(1,1) PRIMARY KEY,
		Id_Consorcio int,
		Id_tipo_pago int,
		detalle_trabajo varchar(120),
		Nro_Cuotas_Actual smallint not null,
		Total_Cuotas smallint,
		Importe decimal(10,2),
		Fecha date,
		CONSTRAINT FK_Gasto_Extraordinario_Consorcio FOREIGN KEY (Id_Consorcio) REFERENCES Consorcio(Id_Consorcio),
		CONSTRAINT FK_Gasto_Extraordinario_Tipo_Pago FOREIGN KEY (Id_tipo_pago) REFERENCES Tipo_Pago_Extraordinario(Id_tipo_pago),
	);
END

-------------Unidad Funcional ----------------

IF OBJECT_ID('Unidad_Funcional') IS NULL
BEGIN
	CREATE TABLE Unidad_Funcional
	(
		NroUF int IDENTITY(1,1) PRIMARY KEY,
		Id_Consorcio int,
		Piso varchar(5),
		Departamento varchar(5),
		Coeficiente decimal(5,2),
		M2_UF smallint,
		Baulera bit,
		Cochera bit,
		M2_Baulera tinyint,
		M2_Cochera tinyint,
		CONSTRAINT FK_Unidad_Funcional_Consorcio FOREIGN KEY (Id_Consorcio) REFERENCES Consorcio(Id_Consorcio),
	);
END


IF OBJECT_ID('TipoRelacionPersonaUnidad') IS NULL
BEGIN
	CREATE TABLE TipoRelacionPersonaUnidad
	(
		ID_Tipo_Relacion_P_U int IDENTITY(1,1) PRIMARY KEY,
		Nombre varchar(50),
	);
END


IF OBJECT_ID('Persona') IS NULL
BEGIN
	CREATE TABLE Persona
	(
		Id_Persona int IDENTITY(1,1) PRIMARY KEY,
		DNI varchar(15) NOT NULL UNIQUE, --mirar esto 
		Nombre varchar(80),
		Apellido varchar(80),
		Email varchar(100),
		Telefono varchar(20),
	);
END


IF OBJECT_ID('Unidad_Persona') IS NULL
BEGIN
	CREATE TABLE Unidad_Persona
	(
		ID_U_P int IDENTITY(1,1) PRIMARY KEY,
		Id_Personas int,
		NroUF int,
		Id_TipoRelacion int,
		Fecha_Inicio datetime,
		Fecha_Fin datetime NULL,
		CbuCvu varchar(22) NOT NULL,
		CONSTRAINT FK_Unidad_Persona_TipoRelacionPersonaUnidad FOREIGN KEY (Id_TipoRelacion) REFERENCES TipoRelacionPersonaUnidad(ID_Tipo_Relacion_P_U),
		CONSTRAINT FK_Unidad_Persona_Unidad_Funcional FOREIGN KEY (NroUF) REFERENCES Unidad_Funcional(NroUF),
		CONSTRAINT FK_Unidad_Persona_Persona FOREIGN KEY (Id_Personas) REFERENCES Persona(Id_Persona),
	);
END

------------- Liquidacion Mensual-------------

IF OBJECT_ID('Liquidacion_Mensual') IS NULL
BEGIN
	CREATE TABLE Liquidacion_Mensual
	(
		Id_Liquidacion_Mensual int IDENTITY(1,1) PRIMARY KEY,
		Id_Consorcio int,
		Periodo datetime,
		Fecha_Emision datetime,
		Fecha_Vencimiento1 datetime,
		Fecha_Vencimiento2 datetime,
		Total_Gasto_Ordinarios decimal(10,2),
		Total_Gasto_Extraordinarios decimal(10,2),
		CONSTRAINT FK_Liquidacion_Mensual_Consorcio FOREIGN KEY (Id_Consorcio) REFERENCES Consorcio(Id_Consorcio),
	);
END


IF OBJECT_ID('Detalle_Expensa_UF') IS NULL
BEGIN
	CREATE TABLE Detalle_Expensa_UF
	(
		Id_Detalle_Expensa int IDENTITY(1,1) PRIMARY KEY,
		Id_Expensa int,
		NroUf int,
		Saldo_Anterior decimal(9,2),
		Pagos_Recibidos_Mes decimal(9,2),
		Deuda decimal(9,2),
		Interes_Por_Mora decimal(9,2),
		Importe_Ordinario_Prorrateado decimal(9,2),
		Importe_Extraordinario_Prorrateado decimal(9,2),
		Total_A_Pagar decimal(9,2),
		CONSTRAINT FK_Detalle_Expensa_UF_Liquidacion_Mensual FOREIGN KEY (Id_Expensa) REFERENCES Liquidacion_Mensual(Id_Liquidacion_Mensual),
		CONSTRAINT FK_Detalle_Expensa_UF_Unidad_Funcional FOREIGN KEY (NroUf) REFERENCES Unidad_Funcional(NroUf),
	);
END

IF OBJECT_ID('Forma_De_Pago') IS NULL
BEGIN

	CREATE TABLE Forma_De_Pago 
	(
		Id_Forma_De_Pago int IDENTITY(1,1) PRIMARY KEY,
		Nombre varchar(50),
	);
END


IF OBJECT_ID('Pago') IS NULL
BEGIN
	CREATE TABLE Pago 
	(
		Id_Pago int IDENTITY(1,1) PRIMARY KEY,
		Id_Forma_De_Pago int,
		Fecha datetime,
		Cuenta_Origen varchar(22) NOT NULL,
		Importe decimal(9,2),
		Es_Pago_Asociado bit,
		CONSTRAINT FK_Pago__Forma_De_Pago FOREIGN KEY (Id_Forma_De_Pago) REFERENCES Forma_De_Pago(Id_Forma_De_Pago),
	);
END


IF OBJECT_ID('Tipo_ingreso') IS NULL
BEGIN
	CREATE TABLE Tipo_ingreso 
	(
		Id_Tipo_Ingreso int IDENTITY(1,1) PRIMARY KEY,
		Nombre varchar(50),
	);
END

IF OBJECT_ID('Detalle_Pago') IS NULL
BEGIN
	CREATE TABLE Detalle_Pago 
	(
		Id_Detalle_Pago int IDENTITY(1,1) PRIMARY KEY,
		Id_Pago int,
		Id_Detalle_Expensa int,
		Id_Tipo_Ingreso int,
		Importe_Usado decimal(10,2),	
		CONSTRAINT FK_Detalle_Pago__Pago FOREIGN KEY (Id_Pago) REFERENCES Pago(Id_Pago),
		CONSTRAINT FK_Detalle_Pago__Detalle_Expensa_UF FOREIGN KEY (Id_Detalle_Expensa) REFERENCES Detalle_Expensa_UF(Id_Detalle_Expensa),
		CONSTRAINT FK_Detalle_Pago__Tipo_ingreso FOREIGN KEY (Id_Tipo_Ingreso) REFERENCES Tipo_ingreso(Id_Tipo_Ingreso),
	);
END

------------------- Mora ---------------------

IF OBJECT_ID('Mora') IS NULL
BEGIN
	CREATE TABLE Mora
	(
	Id_Mora int IDENTITY(1,1) PRIMARY KEY,
	Porcentajes_Interes decimal(5,2),
	Dias_Desde_Vencimiento int,
	);
END

