-- =============================================================
-- SCRIPT: 03_SP_CREACION_DATOS_EXPENSAS.sql
-- PROPOSITO: STORED PROCEDURE QUE CARGA LAS TABLAS RESTANES
-- LIQUIDACION MENSUAL, EXPENSAS, APLICACION DE PAGOS
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

-- GENERACION DE LIQUIDACION MENSUAL
IF OBJECT_ID('dbo.sp_Generar_Liquidacion_Mensual', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Generar_Liquidacion_Mensual;
GO
CREATE PROCEDURE dbo.sp_Generar_Liquidacion_Mensual
    @Id_Consorcio INT,
    @Anio INT,
    @Mes INT,
    @Id_Liquidacion_Generada INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Periodo DATE = DATEFROMPARTS(@Anio, @Mes, 1);
    DECLARE @TotalOrdinarios DECIMAL(10, 2);
    DECLARE @TotalExtraordinarios DECIMAL(10, 2);
    DECLARE @FechaEmision DATE = GETDATE();

    BEGIN TRY
        -- 1. Validar que no exista
        IF EXISTS (SELECT 1 FROM liquidacion.Liquidacion_Mensual 
                   WHERE Id_Consorcio = @Id_Consorcio AND Periodo = @Periodo)
        BEGIN
            THROW 50001, 'La liquidacion para este consorcio y periodo ya existe.', 1;
            RETURN;
        END

        -- 2. Calcular totales de gastos del periodo
        SELECT @TotalOrdinarios = ISNULL(SUM(Importe_Total), 0)
        FROM gastos.Gasto_Ordinario
        WHERE Id_Consorcio = @Id_Consorcio
          AND YEAR(Fecha) = @Anio AND MONTH(Fecha) = @Mes;

        SELECT @TotalExtraordinarios = ISNULL(SUM(Importe), 0)
        FROM gastos.Gasto_Extraordinario
        WHERE Id_Consorcio = @Id_Consorcio
          AND YEAR(Fecha) = @Anio AND MONTH(Fecha) = @Mes;

        -- 3. Insertar la liquidacion mensual (encabezado)
        INSERT INTO liquidacion.Liquidacion_Mensual (
            Id_Consorcio,
            Periodo,
            Fecha_Emision,
            Fecha_Vencimiento1,
            Fecha_Vencimiento2,
            Total_Gasto_Ordinarios,
            Total_Gasto_Extraordinarios
        )
        VALUES (
            @Id_Consorcio,
            @Periodo,
            @FechaEmision,
            DATEADD(DAY, 10, @FechaEmision), -- 1er Vencimiento en 10 dias
            DATEADD(DAY, 20, @FechaEmision), -- 2do Vencimiento en 20 dias
            @TotalOrdinarios,
            @TotalExtraordinarios
        );

        SET @Id_Liquidacion_Generada = SCOPE_IDENTITY();
        
        PRINT 'Liquidacion mensual generada exitosamente con ID: ' + CAST(@Id_Liquidacion_Generada AS VARCHAR);

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo generar la liquidacion mensual.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


-- GENERACION DE EXPENSAS
IF OBJECT_ID('dbo.sp_Generar_Detalle_Expensas', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Generar_Detalle_Expensas;
GO

CREATE PROCEDURE dbo.sp_Generar_Detalle_Expensas
    @Id_Liquidacion_Mensual INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Id_Consorcio INT, @Periodo DATE, @TotalOrd DECIMAL(10,2), @TotalExt DECIMAL(10,2);
    DECLARE @PrecioCochera DECIMAL(9,2), @PrecioBaulera DECIMAL(9,2);

    BEGIN TRY
        -- 1. Obtener datos de la liquidacion "padre" y del consorcio
        SELECT 
            @Id_Consorcio = L.Id_Consorcio,
            -- Importante: Convertimos el PERIODO (datetime) a DATE aqui
            @Periodo = CAST(L.Periodo AS DATE),
            @TotalOrd = L.Total_Gasto_Ordinarios,
            @TotalExt = L.Total_Gasto_Extraordinarios,
            @PrecioCochera = C.Precio_Cochera,
            @PrecioBaulera = C.Precio_Baulera
        FROM liquidacion.Liquidacion_Mensual AS L
        JOIN negocio.Consorcio AS C ON L.Id_Consorcio = C.Id_Consorcio
        WHERE L.Id_Liquidacion_Mensual = @Id_Liquidacion_Mensual;

        IF @Id_Consorcio IS NULL
        BEGIN
            THROW 50001, 'No se encontro la liquidacion mensual especificada.', 1;
            RETURN;
        END

        -- 2. (Re)generar los detalles
        DELETE FROM liquidacion.Detalle_Expensa_UF WHERE Id_Expensa = @Id_Liquidacion_Mensual;

        -- 3. Insertar todos los detalles de expensas (uno por UF)
        INSERT INTO liquidacion.Detalle_Expensa_UF (
            Id_Expensa, Id_Consorcio, NroUf, Saldo_Anterior, Pagos_Recibidos_Mes,
            Deuda, Interes_Por_Mora, Importe_Ordinario_Prorrateado,
            Importe_Extraordinario_Prorrateado, Total_A_Pagar
        )
        SELECT
            @Id_Liquidacion_Mensual AS Id_Expensa,
            UF.Id_Consorcio, UF.NroUf,
            
            ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0) AS Saldo_Anterior,
            0 AS Pagos_Recibidos_Mes,
            ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0) AS Deuda,
            ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0) * 0.05 AS Interes_Por_Mora,

            (@TotalOrd * UF.Coeficiente / 100) + 
            (CASE WHEN UF.Cochera = 1 THEN @PrecioCochera ELSE 0 END) +
            (CASE WHEN UF.Baulera = 1 THEN @PrecioBaulera ELSE 0 END)
            AS Importe_Ordinario_Prorrateado,

            (@TotalExt * UF.Coeficiente / 100) AS Importe_Extraordinario_Prorrateado,
            
            (ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0)) + -- Deuda
            (ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0) * 0.05) + -- Interes
            (@TotalOrd * UF.Coeficiente / 100) + 
            (CASE WHEN UF.Cochera = 1 THEN @PrecioCochera ELSE 0 END) +
            (CASE WHEN UF.Baulera = 1 THEN @PrecioBaulera ELSE 0 END) +
            (@TotalExt * UF.Coeficiente / 100)
            AS Total_A_Pagar

        FROM unidades.Unidad_Funcional AS UF
        
        -- Buscamos la liquidacion del mes anterior
        LEFT JOIN liquidacion.Liquidacion_Mensual AS PREV_LIQ 
            ON PREV_LIQ.Id_Consorcio = UF.Id_Consorcio
            -- Comparamos DATE vs DATE, en lugar de DATETIME vs DATE
            AND CAST(PREV_LIQ.Periodo AS DATE) = DATEADD(MONTH, -1, @Periodo)

        -- Buscamos el detalle de expensa de esa liquidacion anterior
        LEFT JOIN liquidacion.Detalle_Expensa_UF AS PREV_DET
            ON PREV_DET.Id_Expensa = PREV_LIQ.Id_Liquidacion_Mensual
            AND PREV_DET.NroUf = UF.NroUf

        WHERE UF.Id_Consorcio = @Id_Consorcio;

        PRINT 'Detalles de expensas generados para la liquidacion ID: ' + CAST(@Id_Liquidacion_Mensual AS VARCHAR);

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo generar el detalle de expensas.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


IF OBJECT_ID('dbo.sp_Recalcular_Saldos_UF', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Recalcular_Saldos_UF;
GO
CREATE PROCEDURE dbo.sp_Recalcular_Saldos_UF
    @Id_Consorcio INT,
    @NroUF VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Preparar datos en orden cronologico
    ;WITH DatosBase AS (
        SELECT 
            D.Id_Detalle_Expensa,
            (D.Importe_Ordinario_Prorrateado + D.Importe_Extraordinario_Prorrateado) AS GastosPuros,
            D.Pagos_Recibidos_Mes,
            D.Total_A_Pagar,
            D.Saldo_Anterior,
            L.Periodo,
            ROW_NUMBER() OVER (ORDER BY L.Periodo ASC) AS NumFila
        FROM liquidacion.Detalle_Expensa_UF D
        JOIN liquidacion.Liquidacion_Mensual L ON D.Id_Expensa = L.Id_Liquidacion_Mensual
        WHERE D.Id_Consorcio = @Id_Consorcio AND D.NroUf = @NroUF
    ),
    CalculoRecursivo AS (
		--TOMAR EL SALDO ACUMULADO INICIAL (primer mes)
        SELECT 
            Id_Detalle_Expensa,
            NumFila,
            GastosPuros,
            Pagos_Recibidos_Mes,
            -- Valores originales para el primer mes
            CAST(Saldo_Anterior AS DECIMAL(12,2)) AS Nuevo_Saldo_Anterior,
            CAST(0 AS DECIMAL(12,2)) AS Nuevo_Interes, 
            CAST(Total_A_Pagar AS DECIMAL(12,2)) AS Nuevo_Total_A_Pagar,
            -- Calculamos el Saldo Acumulado que pasará al mes siguiente
            CAST((Total_A_Pagar - Pagos_Recibidos_Mes) AS DECIMAL(12,2)) AS Saldo_Acumulado_Pasante
        FROM DatosBase
        WHERE NumFila = 1

        UNION ALL
		--Unir fila actual con la anterior

        SELECT 
            Curr.Id_Detalle_Expensa,
            Curr.NumFila,
            Curr.GastosPuros,
            Curr.Pagos_Recibidos_Mes,
            -- El Saldo Anterior es el acumulado del mes previo
            Prev.Saldo_Acumulado_Pasante, 
            -- Calculo Interés
            CAST(CASE WHEN Prev.Saldo_Acumulado_Pasante > 0 
                 THEN Prev.Saldo_Acumulado_Pasante * 0.05 
                 ELSE 0 
            END AS DECIMAL(12,2)),
            -- Nuevo total para pagar = SaldoAnt + Interes + Gastos
            CAST((Prev.Saldo_Acumulado_Pasante + 
                  (CASE WHEN Prev.Saldo_Acumulado_Pasante > 0 THEN Prev.Saldo_Acumulado_Pasante * 0.05 ELSE 0 END) + 
                  Curr.GastosPuros) AS DECIMAL(12,2)),
            -- Nuevo Acumulado para el siguiente mes = NuevoTotal - Pagos
            CAST(((Prev.Saldo_Acumulado_Pasante + 
                   (CASE WHEN Prev.Saldo_Acumulado_Pasante > 0 THEN Prev.Saldo_Acumulado_Pasante * 0.05 ELSE 0 END) + 
                   Curr.GastosPuros) - Curr.Pagos_Recibidos_Mes) AS DECIMAL(12,2))
        FROM DatosBase Curr
        INNER JOIN CalculoRecursivo Prev ON Curr.NumFila = Prev.NumFila + 1
    )
    -- Actualización
    UPDATE T
    SET 
        T.Saldo_Anterior   = C.Nuevo_Saldo_Anterior,
        T.Interes_Por_Mora = C.Nuevo_Interes,
        T.Total_A_Pagar    = C.Nuevo_Total_A_Pagar,
        T.Deuda            = CASE WHEN C.Nuevo_Saldo_Anterior > 0 THEN C.Nuevo_Saldo_Anterior ELSE 0 END
    FROM liquidacion.Detalle_Expensa_UF T
    INNER JOIN CalculoRecursivo C ON T.Id_Detalle_Expensa = C.Id_Detalle_Expensa
    WHERE C.NumFila > 1 -- Lo del primer mes no no se toca
    OPTION (MAXRECURSION 0);

END
GO
-- APLICACION DE PAGOS
IF OBJECT_ID('dbo.sp_Procesar_Pagos', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Procesar_Pagos;
GO
CREATE PROCEDURE dbo.sp_Procesar_Pagos
    @FechaCorte DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Identificar pagos a procesar (para la primer UF activa por persona)
        WITH Pagos_CTE AS (
            SELECT 
                P.Id_Pago,
                P.Importe,
                P.Fecha,
                UP.Id_Consorcio,
                UP.NroUf,
                ROW_NUMBER() OVER (PARTITION BY P.Id_Pago ORDER BY UP.Id_Consorcio, UP.NroUf) as rn
            FROM pagos.Pago P
            JOIN unidades.Persona PER ON P.Cuenta_Origen = PER.Cbu_Cvu
            JOIN unidades.Unidad_Persona UP ON PER.Id_Persona = UP.Id_Persona 
            WHERE P.Es_Pago_Asociado = 1 AND P.Procesado = 0 
              AND P.Fecha <= @FechaCorte AND UP.Fecha_Fin IS NULL
        )
        SELECT Id_Pago, Importe, Fecha, Id_Consorcio, NroUf 
        INTO #PagosPendientes FROM Pagos_CTE WHERE rn = 1;

        DECLARE @TotalPagos INT = (SELECT COUNT(*) FROM #PagosPendientes);
        PRINT 'Procesando ' + CAST(@TotalPagos AS VARCHAR) + ' pagos.';

        -- Procesamiento secuencial para la tabla temporal
        DECLARE @IdPago INT, @MontoRestante DECIMAL(12,2), @IdConsorcio INT, @NroUF VARCHAR(10);

        WHILE EXISTS (SELECT 1 FROM #PagosPendientes)
        BEGIN
            SELECT TOP 1 
                @IdPago = Id_Pago, 
                @MontoRestante = Importe, 
                @IdConsorcio = Id_Consorcio, 
                @NroUF = NroUf 
            FROM #PagosPendientes;

            -- Imputar deuda mientras quede saldo
            WHILE @MontoRestante > 0
            BEGIN
                DECLARE @IdDetalleDestino INT = NULL;
                DECLARE @SaldoPendiente DECIMAL(12,2) = 0;
                DECLARE @TipoIngreso INT = 1; 

                -- Buscar deuda más antigua
                SELECT TOP 1 
                    @IdDetalleDestino = DE.Id_Detalle_Expensa,
                    @SaldoPendiente = CAST((DE.Total_A_Pagar - DE.Pagos_Recibidos_Mes) AS DECIMAL(12,2))
                FROM liquidacion.Detalle_Expensa_UF DE
                JOIN liquidacion.Liquidacion_Mensual LM ON DE.Id_Expensa = LM.Id_Liquidacion_Mensual
                WHERE DE.Id_Consorcio = @IdConsorcio AND DE.NroUf = @NroUF
                  AND (DE.Total_A_Pagar - DE.Pagos_Recibidos_Mes) > 0.01
                ORDER BY LM.Periodo ASC;

                -- Si no hay deuda, imputar a cuenta en la última expensa
                IF @IdDetalleDestino IS NULL
                BEGIN
                    SELECT TOP 1 
                        @IdDetalleDestino = DE.Id_Detalle_Expensa, 
                        @SaldoPendiente = @MontoRestante 
                    FROM liquidacion.Detalle_Expensa_UF DE 
                    JOIN liquidacion.Liquidacion_Mensual LM ON DE.Id_Expensa = LM.Id_Liquidacion_Mensual
                    WHERE DE.Id_Consorcio = @IdConsorcio AND DE.NroUf = @NroUF 
                    ORDER BY LM.Periodo DESC;
                    
                    SET @TipoIngreso = 3; 
                END

                IF @IdDetalleDestino IS NULL BREAK;

                -- Calcular monto a aplicar
                DECLARE @Aplicar DECIMAL(12,2) = CASE WHEN @MontoRestante >= @SaldoPendiente THEN @SaldoPendiente ELSE @MontoRestante END;

                -- Actualizar y registrar detalle
                UPDATE liquidacion.Detalle_Expensa_UF 
                SET Pagos_Recibidos_Mes = Pagos_Recibidos_Mes + @Aplicar 
                WHERE Id_Detalle_Expensa = @IdDetalleDestino;

                INSERT INTO pagos.Detalle_Pago (Id_Pago, Id_Detalle_Expensa, Id_Tipo_Ingreso, Importe_Usado)
                VALUES (@IdPago, @IdDetalleDestino, @TipoIngreso, @Aplicar);

                SET @MontoRestante = @MontoRestante - @Aplicar;
            END

            -- Finalizar pago y recalcular saldos futuros
            UPDATE pagos.Pago SET Procesado = 1 WHERE Id_Pago = @IdPago;
            
			EXEC dbo.sp_Recalcular_Saldos_UF @Id_Consorcio = @IdConsorcio, @NroUF = @NroUF;

            DELETE FROM #PagosPendientes WHERE Id_Pago = @IdPago;
        END

        DROP TABLE #PagosPendientes;
    END TRY
    BEGIN CATCH
        PRINT 'ERROR en sp_Procesar_Pagos: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

USE COM5600_G04;
GO
