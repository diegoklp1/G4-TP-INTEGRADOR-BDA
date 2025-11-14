-- =========================================================
-- SCRIPT: 00_CreacionTablasyEstructuras.sql
-- PROPÓSITO: Crea la base de datos, sus tablas y todas las estructuras

-- Fecha de entrega:	07/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

------------------ CREACIÓN DE BBDD -------------------
-- Cambiar master
USE master;
GO

IF DB_ID('COM5600_G04') IS NOT NULL
BEGIN
    ALTER DATABASE COM5600_G04 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE COM5600_G04;

    PRINT 'Base de datos COM5600_G04 borrada correctamente.';
END
GO

-- Creo la base
IF DB_ID('COM5600_G04') IS NULL
BEGIN
    CREATE DATABASE COM5600_G04 
	    PRINT 'Base de datos COM5600_G04 Creada.';
END	
GO

-- Cambiar a COM5600_G04
USE COM5600_G04;
GO

/* ============================================================
   DROP de esquemas (solo si están vacíos)
   ============================================================ */
IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'negocio')
    DROP SCHEMA negocio;
GO

IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'gastos')
    DROP SCHEMA gastos;
GO

IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'unidades')
    DROP SCHEMA unidades;
GO

IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'liquidacion')
    DROP SCHEMA liquidacion;
GO

IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'pagos')
    DROP SCHEMA pagos;
GO

/* ============================================================
   CREATE de esquemas
   ============================================================ */

CREATE SCHEMA negocio;
GO

CREATE SCHEMA gastos;
GO

CREATE SCHEMA unidades;
GO

CREATE SCHEMA liquidacion;
GO

CREATE SCHEMA pagos;
GO

/* =========================================================
   TABLAS - ESQUEMA: negocio
   ========================================================= */

CREATE TABLE negocio.Administracion 
(
    Id_Administracion int IDENTITY(1,1) PRIMARY KEY,
    Razon_Social varchar(100),
    CUIT varchar(20),
    Direccion varchar(100),
    Telefono varchar(20),
    Email varchar(100),
    Cuenta_Deposito varchar(22),
    Precio_Cochera_Default decimal(9,2),
    Precio_Baulera_Default decimal(9,2)
);

CREATE TABLE negocio.Consorcio 
(
    Id_Consorcio int PRIMARY KEY,
    Id_Administracion int,
    Nombre varchar(100),
    Domicilio varchar(100),
    Cant_unidades smallint,
    MetrosCuadrados int,
    Precio_Cochera decimal(9,2),
    Precio_Baulera decimal(9,2),
    CONSTRAINT FK_Consorcio_Administracion FOREIGN KEY (Id_Administracion)
        REFERENCES negocio.Administracion(Id_Administracion)
);

CREATE TABLE negocio.Proveedor
(
    Id_Proveedor int IDENTITY(1,1) PRIMARY KEY,
    Id_Consorcio int,
    Nombre_Gasto varchar(60),
    Descripcion varchar(100),
    Cuenta varchar(50),
    CONSTRAINT FK_Proveedor_Consorcio FOREIGN KEY (Id_Consorcio)
        REFERENCES negocio.Consorcio(Id_Consorcio)
);

CREATE TABLE negocio.Estado_Financiero 
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
    CONSTRAINT FK_EF_Consorcio FOREIGN KEY (Id_Consorcio)
        REFERENCES negocio.Consorcio(Id_Consorcio)
);


/* =========================================================
   TABLAS - ESQUEMA: gastos
   ========================================================= */

CREATE TABLE gastos.Tipo_Pago_Extraordinario
(
    Id_tipo_pago int IDENTITY(1,1) PRIMARY KEY, 
    Nombre varchar(50)
);

CREATE TABLE gastos.Gasto_Extraordinario 
(
    Id_gasto int IDENTITY(1,1) PRIMARY KEY,
    Id_Consorcio int,
    Id_tipo_pago int,
    detalle_trabajo varchar(120),
    Nro_Cuotas_Actual smallint NULL,
    Total_Cuotas smallint NULL,
    Importe decimal(10,2),
    Fecha date,
    CONSTRAINT FK_GE_Consorcio FOREIGN KEY (Id_Consorcio)
        REFERENCES negocio.Consorcio(Id_Consorcio),
    CONSTRAINT FK_GE_TipoPago FOREIGN KEY (Id_tipo_pago)
        REFERENCES gastos.Tipo_Pago_Extraordinario(Id_tipo_pago)
);

CREATE TABLE gastos.Tipo_Gasto_Ordinario
(
    Id_Tipo_Gasto int IDENTITY(1,1) PRIMARY KEY,
    Nombre varchar(50)
);

CREATE TABLE gastos.Gasto_Ordinario 
(
    Id_gasto int IDENTITY(1,1) PRIMARY KEY,
    Id_Consorcio int,
    Id_Tipo_Gasto int,
    Fecha date,
    Importe_Total decimal(10,2),
    Descripcion varchar(50),
    CONSTRAINT FK_GO_Consorcio FOREIGN KEY (Id_Consorcio)
        REFERENCES negocio.Consorcio(Id_Consorcio),
    CONSTRAINT FK_GO_TipoGasto FOREIGN KEY (Id_Tipo_Gasto)
        REFERENCES gastos.Tipo_Gasto_Ordinario(Id_Tipo_Gasto)
);

CREATE TABLE gastos.Gasto_Administracion
(
    Id_gasto int PRIMARY KEY,
    Nro_Factura int,
    CONSTRAINT FK_GA_GO FOREIGN KEY (Id_gasto)
        REFERENCES gastos.Gasto_Ordinario(Id_gasto)
);

CREATE TABLE gastos.Gasto_Seguro
(
    Id_gasto int PRIMARY KEY,
    Nro_Factura int,
    NombreSeguro varchar(50),
    CONSTRAINT FK_GS_GO FOREIGN KEY (Id_gasto)
        REFERENCES gastos.Gasto_Ordinario(Id_gasto)
);

CREATE TABLE gastos.Gasto_General
(
    Id_gasto int PRIMARY KEY,
    Descripcion varchar(100),
    Nombre_Responsable varchar(60),
    Nro_factura decimal(10,2),
    CONSTRAINT FK_GG_GO FOREIGN KEY (Id_gasto)
        REFERENCES gastos.Gasto_Ordinario(Id_gasto)
);

CREATE TABLE gastos.Empresa_Limpieza
(
    Id_gasto int PRIMARY KEY,
    Nombre_Empresa varchar(50),
    Nro_factura int,
    CONSTRAINT FK_EL_GO FOREIGN KEY (Id_gasto)
        REFERENCES gastos.Gasto_Ordinario(Id_gasto)
);

CREATE TABLE gastos.Gasto_Mantenimiento
(
    Id_gasto int PRIMARY KEY,
    CBU varchar(22),
    CONSTRAINT FK_GM_GO FOREIGN KEY (Id_gasto)
        REFERENCES gastos.Gasto_Ordinario(Id_gasto)
);

CREATE TABLE gastos.Empleado_Limpieza
(
    Id_gasto int PRIMARY KEY,
    Sueldo decimal(10,2),
    Factura_Productos decimal(10,2),
    CONSTRAINT FK_EmplLimp_GO FOREIGN KEY (Id_gasto)
        REFERENCES gastos.Gasto_Ordinario(Id_gasto)
);

CREATE TABLE gastos.Tipo_Servicio
(
    Id_Tipo_Servicio int IDENTITY(1,1) PRIMARY KEY,
    Nombre varchar(50)
);

CREATE TABLE gastos.Gasto_Servicio_Publico
(
    Id_gasto int PRIMARY KEY,
    Id_Tipo_Servicio int,
    Nombre_Empresa varchar(50),
    Nro_Factura int,
    CONSTRAINT FK_GSP_GO FOREIGN KEY (Id_gasto)
        REFERENCES gastos.Gasto_Ordinario(Id_gasto),
    CONSTRAINT FK_GSP_TS FOREIGN KEY (Id_Tipo_Servicio)
        REFERENCES gastos.Tipo_Servicio(Id_Tipo_Servicio)
);


/* =========================================================
   TABLAS - ESQUEMA: unidades
   ========================================================= */

CREATE TABLE unidades.Unidad_Funcional
(
    Id_Consorcio int,
    NroUF VARCHAR(10),
    Piso varchar(5),
    Departamento varchar(2),
    Coeficiente decimal(5,2),
    M2_UF smallint,
    Baulera bit,
    Cochera bit,
    M2_Baulera tinyint,
    M2_Cochera tinyint,
    CONSTRAINT PK_UF PRIMARY KEY (Id_Consorcio, NroUF),
    CONSTRAINT FK_UF_Consorcio FOREIGN KEY (Id_Consorcio)
        REFERENCES negocio.Consorcio(Id_Consorcio)
);

CREATE TABLE unidades.TipoRelacionPersonaUnidad
(
    ID_Tipo_Relacion_P_U int IDENTITY(1,1) PRIMARY KEY,
    Nombre varchar(50)
);

CREATE TABLE unidades.Persona
(
    Id_Persona int IDENTITY(1,1) PRIMARY KEY,
    DNI varchar(15) NOT NULL UNIQUE,
    Nombre varchar(80),
    Apellido varchar(80),
    Email varchar(100),
    Telefono varchar(20),
    inquilino bit,
    Cbu_Cvu varchar(22) NOT NULL
);

CREATE TABLE unidades.Unidad_Persona
(
    ID_U_P int IDENTITY(1,1) PRIMARY KEY,
    Id_Consorcio int NOT NULL,
    NroUF VARCHAR(10),
    Id_Persona int,
    Id_TipoRelacion int,
    Fecha_Inicio date,
    Fecha_Fin date NULL,
    CONSTRAINT FK_UP_TipoRel FOREIGN KEY (Id_TipoRelacion)
        REFERENCES unidades.TipoRelacionPersonaUnidad(ID_Tipo_Relacion_P_U),
    CONSTRAINT FK_UP_UF FOREIGN KEY (Id_Consorcio, NroUF)
        REFERENCES unidades.Unidad_Funcional(Id_Consorcio, NroUF),
    CONSTRAINT FK_UP_Persona FOREIGN KEY (Id_Persona)
        REFERENCES unidades.Persona(Id_Persona)
);


/* =========================================================
   TABLAS - ESQUEMA: liquidacion
   ========================================================= */

CREATE TABLE liquidacion.Liquidacion_Mensual
(
    Id_Liquidacion_Mensual int IDENTITY(1,1) PRIMARY KEY,
    Id_Consorcio int,
    Periodo datetime,
    Fecha_Emision datetime,
    Fecha_Vencimiento1 datetime,
    Fecha_Vencimiento2 datetime,
    Total_Gasto_Ordinarios decimal(10,2),
    Total_Gasto_Extraordinarios decimal(10,2),
    CONSTRAINT FK_LM_Consorcio FOREIGN KEY (Id_Consorcio)
        REFERENCES negocio.Consorcio(Id_Consorcio)
);

CREATE TABLE liquidacion.Detalle_Expensa_UF
(
    Id_Detalle_Expensa int IDENTITY(1,1) PRIMARY KEY,
    Id_Expensa int,
    Id_Consorcio int,
    NroUF VARCHAR(10),
    Saldo_Anterior decimal(9,2),
    Pagos_Recibidos_Mes decimal(9,2),
    Deuda decimal(9,2),
    Interes_Por_Mora decimal(9,2),
    Importe_Ordinario_Prorrateado decimal(9,2),
    Importe_Extraordinario_Prorrateado decimal(9,2),
    Total_A_Pagar decimal(9,2),
    CONSTRAINT FK_DE_LM FOREIGN KEY (Id_Expensa) REFERENCES liquidacion.Liquidacion_Mensual(Id_Liquidacion_Mensual),
    CONSTRAINT FK_DE_UF FOREIGN KEY (Id_Consorcio, NroUF) REFERENCES unidades.Unidad_Funcional(Id_Consorcio, NroUF)
);

CREATE TABLE liquidacion.Mora
(
    Id_Mora int IDENTITY(1,1) PRIMARY KEY,
    Porcentajes_Interes decimal(5,2),
    Dias_Desde_Vencimiento int
);


/* =========================================================
   TABLAS - ESQUEMA: pagos
   ========================================================= */

CREATE TABLE pagos.Forma_De_Pago 
(
    Id_Forma_De_Pago int IDENTITY(1,1) PRIMARY KEY,
    Nombre varchar(50)
);

CREATE TABLE pagos.Pago 
(
    Id_Pago int IDENTITY(1,1) PRIMARY KEY,
    Id_Forma_De_Pago int,
    Fecha date,
    Cuenta_Origen varchar(22) NOT NULL,
    Importe decimal(9,2),
    Es_Pago_Asociado bit,
    CONSTRAINT FK_Pago_Forma FOREIGN KEY (Id_Forma_De_Pago) REFERENCES pagos.Forma_De_Pago(Id_Forma_De_Pago)
);

CREATE TABLE pagos.Tipo_ingreso 
(
    Id_Tipo_Ingreso int IDENTITY(1,1) PRIMARY KEY,
    Nombre varchar(50)
);

CREATE TABLE pagos.Detalle_Pago 
(
    Id_Detalle_Pago int IDENTITY(1,1) PRIMARY KEY,
    Id_Pago int,
    Id_Detalle_Expensa int,
    Id_Tipo_Ingreso int,
    Importe_Usado decimal(10,2),
    CONSTRAINT FK_DP_Pago FOREIGN KEY (Id_Pago) REFERENCES pagos.Pago(Id_Pago),
    CONSTRAINT FK_DP_Expensa FOREIGN KEY (Id_Detalle_Expensa) REFERENCES liquidacion.Detalle_Expensa_UF(Id_Detalle_Expensa),
    CONSTRAINT FK_DP_TipoIng FOREIGN KEY (Id_Tipo_Ingreso) REFERENCES pagos.Tipo_ingreso(Id_Tipo_Ingreso)
);
