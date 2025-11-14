-- =============================================================
-- SCRIPT: 03_SP_CREACION_DATOS_EXPENSAS.sql
-- PROPOSITO: STORED PROCEDURE QUE CARGA LAS TABLAS RESTANES
-- LIQUIDACION MENSUAL, EXPENSAS, APLICACION DE PAGOS

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =============================================================
USE COM5600_G04


-- GENERACION DE LIQUIDACION MENSUAL
IF OBJECT_ID('sp_Generar_Liquidacion_Mensual', 'P') IS NOT NULL
    DROP PROCEDURE sp_Generar_Liquidacion_Mensual;
GO
CREATE PROCEDURE sp_Generar_Liquidacion_Mensual
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
        IF EXISTS (SELECT 1 FROM Liquidacion_Mensual 
                   WHERE Id_Consorcio = @Id_Consorcio AND Periodo = @Periodo)
        BEGIN
            THROW 50001, 'La liquidacion para este consorcio y periodo ya existe.', 1;
            RETURN;
        END

        -- 2. Calcular totales de gastos del periodo
        SELECT @TotalOrdinarios = ISNULL(SUM(Importe_Total), 0)
        FROM Gasto_Ordinario
        WHERE Id_Consorcio = @Id_Consorcio
          AND YEAR(Fecha) = @Anio AND MONTH(Fecha) = @Mes;

        SELECT @TotalExtraordinarios = ISNULL(SUM(Importe), 0)
        FROM Gasto_Extraordinario
        WHERE Id_Consorcio = @Id_Consorcio
          AND YEAR(Fecha) = @Anio AND MONTH(Fecha) = @Mes;

        -- 3. Insertar la liquidacion mensual (encabezado)
        INSERT INTO Liquidacion_Mensual (
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
IF OBJECT_ID('sp_Generar_Detalle_Expensas', 'P') IS NOT NULL
    DROP PROCEDURE sp_Generar_Detalle_Expensas;
GO

CREATE PROCEDURE sp_Generar_Detalle_Expensas
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
        FROM Liquidacion_Mensual AS L
        JOIN Consorcio AS C ON L.Id_Consorcio = C.Id_Consorcio
        WHERE L.Id_Liquidacion_Mensual = @Id_Liquidacion_Mensual;

        IF @Id_Consorcio IS NULL
        BEGIN
            THROW 50001, 'No se encontro la liquidacion mensual especificada.', 1;
            RETURN;
        END

        -- 2. (Re)generar los detalles
        DELETE FROM Detalle_Expensa_UF WHERE Id_Expensa = @Id_Liquidacion_Mensual;

        -- 3. Insertar todos los detalles de expensas (uno por UF)
        INSERT INTO Detalle_Expensa_UF (
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

        FROM Unidad_Funcional AS UF
        
        -- Buscamos la liquidacion del mes anterior
        LEFT JOIN Liquidacion_Mensual AS PREV_LIQ 
            ON PREV_LIQ.Id_Consorcio = UF.Id_Consorcio
            -- Comparamos DATE vs DATE, en lugar de DATETIME vs DATE
            AND CAST(PREV_LIQ.Periodo AS DATE) = DATEADD(MONTH, -1, @Periodo)

        -- Buscamos el detalle de expensa de esa liquidacion anterior
        LEFT JOIN Detalle_Expensa_UF AS PREV_DET
            ON PREV_DET.Id_Expensa = PREV_LIQ.Id_Liquidacion_Mensual
            AND PREV_DET.NroUf = UF.NroUf

        WHERE UF.Id_Consorcio = @Id_Consorcio;

        PRINT 'Detalles de expensas (CORREGIDOS) generados para la liquidacion ID: ' + CAST(@Id_Liquidacion_Mensual AS VARCHAR);

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo generar el detalle de expensas.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO


-- APLICACION DE PAGOS
IF OBJECT_ID('sp_Procesar_Pagos', 'P') IS NOT NULL
    DROP PROCEDURE sp_Procesar_Pagos;
GO
CREATE PROCEDURE sp_Procesar_Pagos
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            P.Id_Pago,
            P.Importe,
            P.Cuenta_Origen,
            UP.Id_Consorcio,
            UP.NroUf,
            P.Fecha AS Fecha_Pago,
            ROW_NUMBER() OVER (ORDER BY P.Fecha, P.Id_Pago) AS RowId
        INTO #PagosAProcesar
        FROM Pago AS P
        JOIN Persona AS PER 
            ON P.Cuenta_Origen = PER.Cbu_Cvu
        JOIN Unidad_Persona AS UP 
            ON PER.Id_Persona = UP.Id_Persona AND UP.Fecha_Fin IS NULL
        WHERE P.Es_Pago_Asociado = 1
          AND P.Procesado = 0;

        DECLARE @RowCount INT = @@ROWCOUNT;
        PRINT 'Pagos nuevos a procesar encontrados: ' + CAST(@RowCount AS VARCHAR);

        DECLARE @i INT = 1;
        DECLARE @IdPago INT, @ImportePago DECIMAL(9,2), @IdConsorcio INT, @NroUF VARCHAR(10);
        DECLARE @MontoRestantePago DECIMAL(9,2);
        DECLARE @FechaPago DATE;

        WHILE @i <= @RowCount
        BEGIN
            SELECT 
                @IdPago = Id_Pago,
                @ImportePago = Importe,
                @IdConsorcio = Id_Consorcio,
                @NroUF = NroUf,
                @FechaPago = Fecha_Pago
            FROM #PagosAProcesar
            WHERE RowId = @i;
            
            
            SET @MontoRestantePago = @ImportePago;
            --PRINT 'Procesando Pago ID: ' + CAST(@IdPago AS VARCHAR) + ' por ' + CAST(@ImportePago AS VARCHAR) + ' para UF: ' + @NroUF;

            -- 3. Loop interno: Aplicar el pago a las deudas más antiguas
            WHILE @MontoRestantePago > 0
            BEGIN
                DECLARE @IdDetalleExpensa INT = NULL;
                DECLARE @MontoAdeudado DECIMAL(9,2) = 0;
                DECLARE @FechaVencimiento1 DATE;
                DECLARE @IdTipoIngreso INT;

                SELECT TOP 1
                    @IdDetalleExpensa = DE.Id_Detalle_Expensa,
                    @MontoAdeudado = (DE.Total_A_Pagar - DE.Pagos_Recibidos_Mes),
                    @FechaVencimiento1 = LM.Fecha_Vencimiento1
                FROM Detalle_Expensa_UF AS DE
                JOIN Liquidacion_Mensual AS LM ON DE.Id_Expensa = LM.Id_Liquidacion_Mensual
                WHERE DE.Id_Consorcio = @IdConsorcio
                  AND DE.NroUf = @NroUF
                  AND (DE.Total_A_Pagar - DE.Pagos_Recibidos_Mes) > 0.01
                ORDER BY LM.Periodo ASC;

                IF @IdDetalleExpensa IS NULL
                BEGIN
                    --PRINT 'No hay más deuda para la UF: ' + @NroUF + '. (Sobrante: ' + CAST(@MontoRestantePago AS VARCHAR) + ')';
                    BREAK;
                END

                IF @FechaPago <= @FechaVencimiento1
                    SET @IdTipoIngreso = 1; -- EN TERMINO
                ELSE
                    SET @IdTipoIngreso = 2; -- ADEUDADO

                DECLARE @MontoAAplicar DECIMAL(9,2);

                IF @MontoRestantePago >= @MontoAdeudado
                    SET @MontoAAplicar = @MontoAdeudado;
                ELSE
                    SET @MontoAAplicar = @MontoRestantePago;

                BEGIN TRY
                    UPDATE Detalle_Expensa_UF
                    SET Pagos_Recibidos_Mes = Pagos_Recibidos_Mes + @MontoAAplicar
                    WHERE Id_Detalle_Expensa = @IdDetalleExpensa;
                    
                    INSERT INTO Detalle_Pago 
                        (Id_Pago, Id_Detalle_Expensa, Id_Tipo_Ingreso, Importe_Usado)
                    VALUES 
                        (@IdPago, @IdDetalleExpensa, @IdTipoIngreso, @MontoAAplicar);

                    SET @MontoRestantePago = @MontoRestantePago - @MontoAAplicar;
                    --PRINT '  -> Aplicados ' + CAST(@MontoAAplicar AS VARCHAR) + ' a Expensa ID: ' + CAST(@IdDetalleExpensa AS VARCHAR) + '. Restante: ' + CAST(@MontoRestantePago AS VARCHAR);

                END TRY
                BEGIN CATCH
                    PRINT 'ERROR: Falla al aplicar pago ID ' + CAST(@IdPago AS VARCHAR) + ' a expensa ID ' + CAST(@IdDetalleExpensa AS VARCHAR);
                    PRINT ERROR_MESSAGE();
                    BREAK; 
                END CATCH
            END 
            UPDATE Pago
            SET Procesado = 1
            WHERE Id_Pago = @IdPago;
            SET @i = @i + 1;
        END 

        DROP TABLE #PagosAProcesar;
        --PRINT 'Proceso de imputación de pagos finalizado.';

    END TRY
    BEGIN CATCH  
        PRINT 'ERROR: Falla en el procesamiento de pagos.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    SET NOCOUNT OFF;
END
GO