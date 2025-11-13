-- =========================================================
-- SCRIPT: Ejecucion.sql
-- PROPÓSITO: Generar los indices para mejorar el rendimiento
-- al buscar la información para la generación de reportes.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

---Script de Generación de Indices
USE COM5600_G04;
GO

--Pago
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Pago')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Pago
	ON Pago (Id_Pago)
	INCLUDE (Fecha);
END;

--Detalle Pago
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Detalle_Pago')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Detalle_Pago
	ON Detalle_Pago (Id_Detalle_Pago)
	INCLUDE (Id_Pago, Id_Detalle_Expensa, Id_Tipo_Ingreso, Importe_Usado);
END;

--Detalle Expensa UF
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Detalle_Expensa_UF')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Detalle_Expensa_UF
	ON Detalle_Expensa_UF (Id_Detalle_Expensa)
	INCLUDE (Id_Expensa, Id_Consorcio, NroUF, Importe_Ordinario_Prorrateado, Importe_Extraordinario_Prorrateado);
END;

--Liquidacion Mensual
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Liquidacion_Mensual')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Liquidacion_Mensual
	ON Liquidacion_Mensual (Id_Liquidacion_Mensual)
	INCLUDE (Id_Consorcio, Fecha_Vencimiento1, Periodo);
END;

--Unidad Funcional
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Unidad_Funcional')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Unidad_Funcional
	ON Unidad_Funcional (Id_Consorcio, NroUF)
	INCLUDE (Piso, Departamento);
END;

--Tipo Ingreso
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Tipo_Ingreso')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Tipo_Ingreso
	ON Tipo_Ingreso (Id_Tipo_Ingreso)
	INCLUDE (Nombre);
END;

--Gasto Ordinario
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Gasto_Ordinario')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Gasto_Ordinario
	ON Gasto_Ordinario (Id_Gasto)
	INCLUDE (Id_Tipo_Gasto, Id_Consorcio, Fecha);
END;

--Gasto Extraordinario
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Gasto_Extraordinario')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Gasto_Extraordinario
	ON Gasto_Extraordinario (Id_Gasto)
	INCLUDE (Id_Consorcio, Id_Tipo_Pago, Fecha);
END;

--Consorcio
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Consorcio')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Consorcio
	ON Consorcio (Id_Consorcio)
	INCLUDE (Id_Administracion);
END;

--Unidad Persona
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Unidad_Persona')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Unidad_Persona
	ON Unidad_Persona (ID_U_P)
	INCLUDE (Id_Consorcio, Id_Persona, NroUF, Id_TipoRelacion);
END;

--Persona
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Persona')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Persona
	ON Persona (Id_Persona)
	INCLUDE (DNI);
END;

Go
