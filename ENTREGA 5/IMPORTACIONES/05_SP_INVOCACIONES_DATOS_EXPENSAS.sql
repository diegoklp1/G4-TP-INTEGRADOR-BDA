-- =============================================================
-- SCRIPT: 05_SP_INVOCACIONES_DATOS_EXPENSAS.sql
-- PROPOSITO: SCRIPT DE EJECUCION DE DATOS EXPENSAS
-- 
-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387
-- =============================================================

USE COM5600_G04;
GO
IF NOT EXISTS (SELECT 1 FROM SYS.COLUMNS 
 				WHERE OBJECT_ID = OBJECT_ID('pagos.Pago') 
 				AND NAME = 'Procesado')
BEGIN
	ALTER TABLE pagos.Pago
	ADD Procesado BIT NOT NULL DEFAULT 0;
	PRINT 'Columna [Procesado] agregada a la tabla pagos.Pago.';
END
GO
USE COM5600_G04
GO

-- 1. LIMPIEZA (Solo para pruebas)
PRINT 'Limpiando tablas...';
DELETE FROM pagos.Detalle_Pago;
DELETE FROM pagos.Pago;
DELETE FROM liquidacion.Detalle_Expensa_UF;
DELETE FROM liquidacion.Liquidacion_Mensual;
GO
USE COM5600_G04;
GO


----------------------------------------------------------------------
-- GASTO EXTRAORDINARIO - Abril 2025
----------------------------------------------------------------------
GO
INSERT INTO gastos.Gasto_Extraordinario 
	(Id_Consorcio, Id_tipo_pago, detalle_trabajo, Nro_Cuotas_Actual, Total_Cuotas, Importe, Fecha)
VALUES 
	(1, 1, 'Reparacion Porton Cochera', 1, 1, 45000.00, '2025-04-10');
GO
----------------------------------------------------------------------
-- MES 1 - Abril 2025
----------------------------------------------------------------------
DECLARE @IdLiquidacionMes1 INT;

SELECT @IdLiquidacionMes1 = Id_Liquidacion_Mensual
FROM liquidacion.Liquidacion_Mensual
WHERE Id_Consorcio = 1
  AND CAST(Periodo AS DATE) = '2025-04-01';

IF @IdLiquidacionMes1 IS NULL
BEGIN
    -- Uso de la API
    -- 1. Declarar una variable para capturar el valor de retorno.
    DECLARE @EsNoHabil INT;
    DECLARE @Fecha DATE = CONVERT(DATE, GETDATE());

    -- 2. Ejecutar el Stored Procedure y asignar su valor de retorno a la variable.
    EXEC @EsNoHabil = dbo.EsDiaNoHabil @Fecha;

	PRINT 'Generando liquidación Abril 2025';

    IF @EsNoHabil = 0
    BEGIN
		EXEC sp_Generar_Liquidacion_Mensual
				@Id_Consorcio = 1, -- Se reemplaza variable por ID 1
				@Anio = 2025,
				@Mes = 4,
				@Id_Liquidacion_Generada = @IdLiquidacionMes1 OUTPUT;

		EXEC sp_Generar_Detalle_Expensas 
				@Id_Liquidacion_Mensual = @IdLiquidacionMes1;
    END

END
ELSE
BEGIN
	PRINT 'La liquidación Abril 2025 ya existe. No se genera nuevamente.';
END
GO


----------------------------------------------------------------------
-- PROCESAR PAGOS (Tanda 1)
----------------------------------------------------------------------
DECLARE @IdLiquidacionMes1 INT =
(
	SELECT Id_Liquidacion_Mensual
	FROM liquidacion.Liquidacion_Mensual
	WHERE Id_Consorcio = 1
	  AND CAST(Periodo AS DATE) = '2025-04-01'
);

IF @IdLiquidacionMes1 IS NULL
	RAISERROR('No se encontro la liquidacion del Mes 1.', 16, 1);
ELSE
BEGIN
	EXEC sp_Procesar_Pagos;

	SELECT Id_Detalle_Expensa, NroUf, Pagos_Recibidos_Mes, Total_A_Pagar
	FROM liquidacion.Detalle_Expensa_UF
	WHERE Id_Expensa = @IdLiquidacionMes1;
END
GO


----------------------------------------------------------------------
-- Tanda 2 - Nuevo Pago
----------------------------------------------------------------------
DECLARE @IdLiquidacionMes1 INT =
(
	SELECT Id_Liquidacion_Mensual
	FROM liquidacion.Liquidacion_Mensual
	WHERE Id_Consorcio = 1
	  AND CAST(Periodo AS DATE) = '2025-04-01'
);

IF @IdLiquidacionMes1 IS NULL
	RAISERROR('No se encontro la liquidacion del Mes 1.', 16, 1);
ELSE
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pagos.Pago WHERE Id_Pago = 99999)
	BEGIN
		INSERT INTO pagos.Pago (Id_Pago, Id_Forma_De_Pago, Fecha, Cuenta_Origen, Importe, Es_Pago_Asociado, Procesado)
		VALUES (99991, 1, '2025-04-10', '1112192065530490000000', 500.00, 1, 0);
		
		-- Pago que no va a tener un cbu asociado
		INSERT INTO pagos.Pago (Id_Pago, Id_Forma_De_Pago, Fecha, Cuenta_Origen, Importe, Es_Pago_Asociado, Procesado)
		VALUES (99990, 1, '2025-04-10', '1112192065530490000999', 500.00, 1, 0);
	END
	ELSE

	EXEC sp_Procesar_Pagos;

	/* -- Se agrega esquema 'liquidacion'
	SELECT Id_Detalle_Expensa, NroUf, Pagos_Recibidos_Mes, Total_A_Pagar
	FROM liquidacion.Detalle_Expensa_UF
	WHERE Id_Expensa = @IdLiquidacionMes1
	  AND NroUf = '10';
	*/
END
GO


----------------------------------------------------------------------
-- MES 2 - Mayo 2025
----------------------------------------------------------------------
DECLARE @IdLiquidacionMes2 INT;

SELECT @IdLiquidacionMes2 = Id_Liquidacion_Mensual
FROM liquidacion.Liquidacion_Mensual
WHERE Id_Consorcio = 1
  AND CAST(Periodo AS DATE) = '2025-05-01';

IF @IdLiquidacionMes2 IS NULL
BEGIN
	PRINT 'Generando liquidación Mayo 2025';

    IF @EsNoHabil = 0
    BEGIN
		EXEC sp_Generar_Liquidacion_Mensual
				@Id_Consorcio = 1,
				@Anio = 2025,
				@Mes = 5,
				@Id_Liquidacion_Generada = @IdLiquidacionMes2 OUTPUT;

		EXEC sp_Generar_Detalle_Expensas 
				@Id_Liquidacion_Mensual = @IdLiquidacionMes2;
    END
END
ELSE
BEGIN
	PRINT 'La liquidación Mayo 2025 ya existe.';
END

SELECT *
FROM liquidacion.Detalle_Expensa_UF
WHERE Id_Expensa = @IdLiquidacionMes2;
GO


----------------------------------------------------------------------
-- MES 3 - Junio 2025
----------------------------------------------------------------------
DECLARE @IdLiquidacionMes3 INT;

SELECT @IdLiquidacionMes3 = Id_Liquidacion_Mensual
FROM liquidacion.Liquidacion_Mensual
WHERE Id_Consorcio = 1
  AND CAST(Periodo AS DATE) = '2025-06-01';

IF @IdLiquidacionMes3 IS NULL
BEGIN
	PRINT 'Generando liquidación Junio 2025';

    IF @EsNoHabil = 0
    BEGIN
		EXEC sp_Generar_Liquidacion_Mensual
				@Id_Consorcio = 1,
				@Anio = 2025,
				@Mes = 6,
				@Id_Liquidacion_Generada = @IdLiquidacionMes3 OUTPUT;

		EXEC sp_Generar_Detalle_Expensas 
				@Id_Liquidacion_Mensual = @IdLiquidacionMes3;
    END
END
ELSE
BEGIN
	PRINT 'La liquidación Junio 2025 ya existe.';
END

SELECT *
FROM liquidacion.Detalle_Expensa_UF
WHERE Id_Expensa = @IdLiquidacionMes3;
GO
