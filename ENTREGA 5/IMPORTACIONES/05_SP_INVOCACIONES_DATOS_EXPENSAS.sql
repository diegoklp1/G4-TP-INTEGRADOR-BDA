USE COM5600_G04;
GO

IF NOT EXISTS (SELECT 1 FROM SYS.COLUMNS 
               WHERE OBJECT_ID = OBJECT_ID('Pago') 
               AND NAME = 'Procesado')
BEGIN
    ALTER TABLE Pago
    ADD Procesado BIT NOT NULL DEFAULT 0;
    PRINT 'Columna [Procesado] agregada a la tabla Pago.';
END
GO
USE COM5600_G04
GO

-- 1. LIMPIEZA (Solo para pruebas)
PRINT 'Limpiando tablas...';
DELETE FROM Detalle_Pago;
DELETE FROM Pago;
DELETE FROM Detalle_Expensa_UF;
DELETE FROM Liquidacion_Mensual;
GO
USE COM5600_G04;
GO

PRINT '--- INICIO DEL JUEGO DE PRUEBA (ACTUALIZADO) ---';
PRINT 'Asegúrese de haber cargado los datos de "Setup"...';
RAISERROR ('Presione "Run" de nuevo para continuar...', 0, 1) WITH NOWAIT;
WAITFOR DELAY '00:00:05';
GO

----------------------------------------------------------------------
-- PRUEBAS MES 1 (Abril 2025) - Lote Unificado
----------------------------------------------------------------------
PRINT '--- PRUEBAS 1 y 2: Generando Liquidación y Detalles (Mes 1: Abril) ---';

DECLARE @IdLiquidacionMes1 INT;
DECLARE @IdConsorcioPrueba INT = 1;

BEGIN TRY
    EXEC sp_Generar_Liquidacion_Mensual
        @Id_Consorcio = @IdConsorcioPrueba,
        @Anio = 2025,
        @Mes = 4,
        @Id_Liquidacion_Generada = @IdLiquidacionMes1 OUTPUT;

    PRINT 'Liquidación Mes 1 (Abril) Generada con ID: ' + CAST(@IdLiquidacionMes1 AS VARCHAR);
    SELECT * FROM Liquidacion_Mensual WHERE Id_Liquidacion_Mensual = @IdLiquidacionMes1;

    IF @IdLiquidacionMes1 IS NULL OR @IdLiquidacionMes1 <= 0
    BEGIN
        THROW 50002, 'sp_Generar_Liquidacion_Mensual no devolvió un ID válido.', 1;
    END

    PRINT 'Generando Detalles para Liquidación ID: ' + CAST(@IdLiquidacionMes1 AS VARCHAR);
    EXEC sp_Generar_Detalle_Expensas @Id_Liquidacion_Mensual = @IdLiquidacionMes1;

    PRINT 'Detalles generados para Mes 1:';
    SELECT * FROM Detalle_Expensa_UF WHERE Id_Expensa = @IdLiquidacionMes1;
    PRINT '/* VERIFICAR: Que Saldo_Anterior sea 0 (primer mes) y Total_A_Pagar esté calculado. */';

END TRY
BEGIN CATCH
    PRINT '--- ERROR EN EL LOTE DE PRUEBAS 1 y 2 ---';
    PRINT ERROR_MESSAGE();
END CATCH
GO

RAISERROR ('--- Pausa (5 seg). Siguiente prueba: Procesar Pagos ---', 0, 1) WITH NOWAIT;
WAITFOR DELAY '00:00:05';
GO

----------------------------------------------------------------------
-- PRUEBA 3: Procesando Pagos MÚLTIPLES VECES (Mes 1)
----------------------------------------------------------------------
PRINT '--- PRUEBA 3.1: Procesando Pagos (Tanda 1) ---';

-- *** LA CORRECCIÓN ESTÁ AQUÍ ***
DECLARE @IdLiquidacionMes1 INT = (
    SELECT Id_Liquidacion_Mensual FROM Liquidacion_Mensual 
    WHERE CAST(Periodo AS DATE) = '2025-04-01' AND Id_Consorcio = 1
);

IF @IdLiquidacionMes1 IS NULL
BEGIN
    RAISERROR('No se encontró la liquidación del Mes 1. Deteniendo prueba de pagos.', 16, 1);
END
ELSE
BEGIN
    PRINT 'Estado ANTES de procesar pagos (Tanda 1):';
    SELECT Id_Detalle_Expensa, NroUf, Pagos_Recibidos_Mes, Total_A_Pagar 
    FROM Detalle_Expensa_UF 
    WHERE Id_Expensa = @IdLiquidacionMes1;

    EXEC sp_Procesar_Pagos;

    PRINT 'Estado DESPUÉS de procesar pagos (Tanda 1):';
    SELECT Id_Detalle_Expensa, NroUf, Pagos_Recibidos_Mes, Total_A_Pagar 
    FROM Detalle_Expensa_UF 
    WHERE Id_Expensa = @IdLiquidacionMes1;
    PRINT '/* VERIFICAR: Que [Pagos_Recibidos_Mes] tenga el monto de los pagos (Tanda 1). */';
END
GO

RAISERROR ('--- Pausa (5 seg). Siguiente prueba: Simulación Tanda 2 ---', 0, 1) WITH NOWAIT;
WAITFOR DELAY '00:00:05';
GO

----------------------------------------------------------------------
-- PRUEBA 3.2: Simulación de NUEVA importación y procesamiento (Tanda 2)
----------------------------------------------------------------------
PRINT '--- PRUEBA 3.2: Simulación de NUEVA importación y procesamiento (Tanda 2) ---';

-- *** LA CORRECCIÓN ESTÁ AQUÍ ***
DECLARE @IdLiquidacionMes1 INT = (
    SELECT Id_Liquidacion_Mensual FROM Liquidacion_Mensual 
    WHERE CAST(Periodo AS DATE) = '2025-04-01' AND Id_Consorcio = 1
);

IF @IdLiquidacionMes1 IS NULL
BEGIN
    RAISERROR('No se encontró la liquidación del Mes 1. Deteniendo prueba de pagos Tanda 2.', 16, 1);
END
ELSE
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Pago WHERE Id_Pago = 99999)
        BEGIN
            INSERT INTO Pago (Id_Pago, Id_Forma_De_Pago, Fecha, Cuenta_Origen, Importe, Es_Pago_Asociado, Procesado)
            VALUES (99999, 1, '2025-04-10', '1112192065530490000000', 500.00, 1, 0); -- Asumimos CBU de UF 10
            PRINT 'Nuevo pago (Tanda 2) insertado para simulación.';
        END
        ELSE
        BEGIN
            PRINT 'El pago de simulación (99999) ya existe. Reseteando a Procesado = 0.';
            UPDATE Pago SET Procesado = 0 WHERE Id_Pago = 99999; 
        END
    END TRY
    BEGIN CATCH
        PRINT 'Error insertando pago de simulación (99999).';
        PRINT ERROR_MESSAGE();
    END CATCH

    EXEC sp_Procesar_Pagos;

    PRINT 'Estado FINAL después de procesar pagos (Tanda 2):';
    SELECT Id_Detalle_Expensa, NroUf, Pagos_Recibidos_Mes, Total_A_Pagar 
    FROM Detalle_Expensa_UF 
    WHERE Id_Expensa = @IdLiquidacionMes1 AND NroUf = '10'; -- Filtramos solo la UF que pagó
    PRINT '/* VERIFICACIÓN CLAVE (Tanda 2): Que [Pagos_Recibidos_Mes] sea la SUMA de (Tanda 1 + Tanda 2). */';
END
GO

RAISERROR ('--- Pausa (5 seg). Siguiente prueba: Generar Mes 2 (Prueba de Deuda) ---', 0, 1) WITH NOWAIT;
WAITFOR DELAY '00:00:05';
GO

----------------------------------------------------------------------
-- PRUEBAS MES 2 (Mayo 2025) - Prueba de Arrastre de Deuda
----------------------------------------------------------------------
PRINT '--- PRUEBA 4 y 5: Generando Liquidación y Detalles (Mes 2: Mayo) ---';

DECLARE @IdLiquidacionMes2 INT;
DECLARE @IdConsorcioPrueba INT = 1;

BEGIN TRY
    EXEC sp_Generar_Liquidacion_Mensual
        @Id_Consorcio = @IdConsorcioPrueba,
        @Anio = 2025,
        @Mes = 5,
        @Id_Liquidacion_Generada = @IdLiquidacionMes2 OUTPUT;

    PRINT 'Liquidación Mes 2 (Mayo) Generada con ID: ' + CAST(@IdLiquidacionMes2 AS VARCHAR);

    IF @IdLiquidacionMes2 IS NULL OR @IdLiquidacionMes2 <= 0
    BEGIN
        THROW 50003, 'sp_Generar_Liquidacion_Mensual no devolvió un ID válido para Mes 2.', 1;
    END

    PRINT '--- ESTA ES LA PRUEBA MÁS IMPORTANTE (SALDO ANTERIOR CORREGIDO) ---';
    EXEC sp_Generar_Detalle_Expensas @Id_Liquidacion_Mensual = @IdLiquidacionMes2;

    PRINT 'Detalles generados para Mes 2:';
    SELECT * FROM Detalle_Expensa_UF WHERE Id_Expensa = @IdLiquidacionMes2;
    PRINT '/* VERIFICACIÓN CLAVE (CORREGIDA): 
        1. Para la UF que NO pagó: [Saldo_Anterior] debe ser el [Total_A_Pagar] de Abril.
        2. Para la UF que SÍ pagó: [Saldo_Anterior] debe ser ([Total_A_Pagar] Abril - [Pagos_Recibidos_Mes] Abril).
    */';

END TRY
BEGIN CATCH
    PRINT '--- ERROR EN EL LOTE DE PRUEBAS 4 y 5 ---';
    PRINT ERROR_MESSAGE();
END CATCH
GO

PRINT '--- FIN DEL JUEGO DE PRUEBA ---';
GO


SELECT * FROM Detalle_Expensa_UF ORDER BY NroUf
select * from pago order by Cuenta_Origen