-- =========================================================
-- SCRIPT: Indices.sql (Corregido con Esquemas)
-- PROPOSITO: Generar los indices para mejorar el rendimiento
-- al buscar la informacion para la generacion de reportes.
--
-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387
-- =========================================================

---Script de Generacion de Indices
USE COM5600_G04;
GO

--Pago (Esquema: pagos)
--Optimizado para filtros por fecha en reportes.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Pago_Fecha')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Pago_Fecha
	ON pagos.Pago (Fecha);
END;
GO

--Detalle Pago (Esquema: pagos)
--Optimizado para los JOINs entre Pago y Detalle_Expensa_UF.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Detalle_Pago_Joins')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Detalle_Pago_Joins
	ON pagos.Detalle_Pago (Id_Pago, Id_Detalle_Expensa)
	INCLUDE (Id_Tipo_Ingreso, Importe_Usado);
END;
GO

--Detalle Expensa UF (Esquema: liquidacion)
--Optimizado para JOINs con Unidad_Funcional y Liquidacion_Mensual.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Detalle_Expensa_UF_Joins')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Detalle_Expensa_UF_Joins
	ON liquidacion.Detalle_Expensa_UF (Id_Expensa, Id_Consorcio, NroUF)
	INCLUDE (Importe_Ordinario_Prorrateado, Importe_Extraordinario_Prorrateado, Total_A_Pagar, Pagos_Recibidos_Mes);
END;
GO

--Liquidacion Mensual (Esquema: liquidacion)
--Optimizado para filtros de Reportes (Id_Consorcio, Periodo).
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Liquidacion_Mensual_Filtro')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Liquidacion_Mensual_Filtro
	ON liquidacion.Liquidacion_Mensual (Id_Consorcio, Periodo)
	INCLUDE (Fecha_Vencimiento1);
END;
GO

--Unidad Funcional (Esquema: unidades)
--Optimizado para Reporte 5 (Filtro por Piso).
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Unidad_Funcional_Filtro')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Unidad_Funcional_Filtro
	ON unidades.Unidad_Funcional (Id_Consorcio, Piso)
	INCLUDE (Departamento, NroUF);
END;
GO

--Tipo Ingreso (Esquema: pagos)
--(Mantenido sobre PK, ya que la tabla es muy pequeña)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Tipo_Ingreso')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Tipo_Ingreso
	ON pagos.Tipo_ingreso (Id_Tipo_Ingreso)
	INCLUDE (Nombre);
END;
GO

--Gasto Ordinario (Esquema: gastos)
--Optimizado para Reporte 4 (Filtros).
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Gasto_Ordinario_Filtro')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Gasto_Ordinario_Filtro
	ON gastos.Gasto_Ordinario (Id_Consorcio, Fecha, Id_Tipo_Gasto)
	INCLUDE (Importe_Total);
END;
GO

--Gasto Extraordinario (Esquema: gastos)
--Optimizado para Reporte 4 (Filtros).
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Gasto_Extraordinario_Filtro')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Gasto_Extraordinario_Filtro
	ON gastos.Gasto_Extraordinario (Id_Consorcio, Fecha)
	INCLUDE (Importe);
END;
GO

--Consorcio (Esquema: negocio)
--(Mantenido sobre PK, la PK es Id_Consorcio)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Consorcio')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Consorcio
	ON negocio.Consorcio (Id_Consorcio)
	INCLUDE (Id_Administracion);
END;
GO

--Unidad Persona (Esquema: unidades)
--Optimizado para JOINs en Reporte 5.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Unidad_Persona_Joins')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Unidad_Persona_Joins
	ON unidades.Unidad_Persona (Id_Persona, Id_Consorcio, NroUF)
	INCLUDE (Id_TipoRelacion, Fecha_Fin);
END;
GO

--Persona (Esquema: unidades)
--(Mantenido sobre PK, la PK es Id_Persona)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Persona')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Persona
	ON unidades.Persona (Id_Persona)
	INCLUDE (DNI);
END;
GO