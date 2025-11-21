-- =============================================================
-- SCRIPT: 06_SP_INVOCACIONES_DATOS_EXPENSAS.sql
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
SET NOCOUNT ON;

-- Gasto de prueba
INSERT INTO gastos.Gasto_Extraordinario 
    (Id_Consorcio, Id_tipo_pago, detalle_trabajo, Nro_Cuotas_Actual, Total_Cuotas, Importe, Fecha)
VALUES 
    (1, 1, 'Reparacion Porton Cochera', 1, 2, 150000.00, '2025-04-10');

-- Declaramos variables globales para reutilizar en todo el script
DECLARE @IdLiq INT;
DECLARE @EsHabilResultado INT;
DECLARE @FechaHoy DATE = CAST(GETDATE() AS DATE); -- Usamos fecha real para validar API

PRINT '';
PRINT '=== MES 1: ABRIL 2025 ===';

SELECT @IdLiq = Id_Liquidacion_Mensual FROM liquidacion.Liquidacion_Mensual WHERE Id_Consorcio = 1 AND CAST(Periodo AS DATE) = '2025-04-01';

IF @IdLiq IS NULL
BEGIN
    -- Consultamos API
    EXEC dbo.EsDiaNoHabil @fecha = @FechaHoy, @EsNoHabil = @EsHabilResultado OUTPUT;

    IF @EsHabilResultado = 1
    BEGIN
        PRINT 'Dia Habil confirmado. Generando Abril...';
        EXEC sp_Generar_Liquidacion_Mensual @Id_Consorcio = 1, @Anio = 2025, @Mes = 4, @Id_Liquidacion_Generada = @IdLiq OUTPUT;
        EXEC sp_Generar_Detalle_Expensas @Id_Liquidacion_Mensual = @IdLiq;
    END
    ELSE
    BEGIN
        PRINT 'AVISO: Hoy NO es habil. No se genera Abril.';
    END
END
ELSE
BEGIN
    PRINT 'Abril ya existe.';
END

-- Procesar pagos si existe el mes
IF @IdLiq IS NOT NULL EXEC sp_Procesar_Pagos @FechaCorte = '2025-04-30';


PRINT '';
PRINT '=== MES 2: MAYO 2025 ===';

SET @IdLiq = NULL; -- Limpiamos variable
SELECT @IdLiq = Id_Liquidacion_Mensual FROM liquidacion.Liquidacion_Mensual WHERE Id_Consorcio = 1 AND CAST(Periodo AS DATE) = '2025-05-01';

IF @IdLiq IS NULL
BEGIN
    EXEC dbo.EsDiaNoHabil @fecha = @FechaHoy, @EsNoHabil = @EsHabilResultado OUTPUT;

    IF @EsHabilResultado = 1
    BEGIN
        PRINT 'Dia Habil confirmado. Generando Mayo...';
        EXEC sp_Generar_Liquidacion_Mensual @Id_Consorcio = 1, @Anio = 2025, @Mes = 5, @Id_Liquidacion_Generada = @IdLiq OUTPUT;
        EXEC sp_Generar_Detalle_Expensas @Id_Liquidacion_Mensual = @IdLiq;
    END
    ELSE PRINT 'AVISO: Hoy NO es habil. No se genera Mayo.';
END
ELSE PRINT 'Mayo ya existe.';

IF @IdLiq IS NOT NULL EXEC sp_Procesar_Pagos @FechaCorte = '2025-05-31';


PRINT '';
PRINT '=== MES 3: JUNIO 2025 ===';

SET @IdLiq = NULL;
SELECT @IdLiq = Id_Liquidacion_Mensual FROM liquidacion.Liquidacion_Mensual WHERE Id_Consorcio = 1 AND CAST(Periodo AS DATE) = '2025-06-01';

IF @IdLiq IS NULL
BEGIN
    EXEC dbo.EsDiaNoHabil @fecha = @FechaHoy, @EsNoHabil = @EsHabilResultado OUTPUT;

    IF @EsHabilResultado = 1
    BEGIN
        PRINT 'Dia Habil confirmado. Generando Junio...';
        EXEC sp_Generar_Liquidacion_Mensual @Id_Consorcio = 1, @Anio = 2025, @Mes = 6, @Id_Liquidacion_Generada = @IdLiq OUTPUT;
        EXEC sp_Generar_Detalle_Expensas @Id_Liquidacion_Mensual = @IdLiq;
    END
    ELSE PRINT 'AVISO: Hoy NO es habil. No se genera Junio.';
END
ELSE PRINT 'Junio ya existe.';

IF @IdLiq IS NOT NULL EXEC sp_Procesar_Pagos @FechaCorte = '2025-06-30';

PRINT '=== PROCESO FINALIZADO ===';
GO

/*
use COM5600_G04
SELECT * FROM liquidacion.Liquidacion_Mensual 

SELECT * FROM liquidacion.Detalle_Expensa_UF 
where NroUF = 1
order by CAST(NroUF AS INT),Id_Expensa 

select *FROM unidades.Unidad_Persona ORDER BY cast(NroUF as int)

INSERT INTO pagos.Pago (Id_Pago, Id_Forma_De_Pago,Fecha,Cuenta_Origen,Importe,Es_Pago_Asociado, Procesado)
VALUES
('11804',1,'2025-04-12', 3622546757575540000000, 70232.63, 1, 0)

INSERT INTO pagos.Pago (Id_Pago, Id_Forma_De_Pago,Fecha,Cuenta_Origen,Importe,Es_Pago_Asociado, Procesado)
VALUES
('11806',1,'2025-04-12', 8899158762922760000000, 70232.63, 1, 0)
c

*/
/*
--LIMPIEZA
DELETE FROM pagos.Detalle_Pago;
DELETE FROM liquidacion.Detalle_Expensa_UF;
DELETE FROM liquidacion.Liquidacion_Mensual;
DELETE FROM gastos.Gasto_Extraordinario;
DBCC CHECKIDENT ('liquidacion.Liquidacion_Mensual', RESEED, 0);
DBCC CHECKIDENT ('liquidacion.Detalle_Expensa_UF', RESEED, 0);
UPDATE pagos.Pago SET Procesado = 0 WHERE Fecha BETWEEN '2025-04-01' AND '2025-06-30';
*/