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
            THROW 50001, 'La liquidación para este consorcio y período ya existe.', 1;
            RETURN;
        END

        -- 2. Calcular totales de gastos del período
        SELECT @TotalOrdinarios = ISNULL(SUM(Importe_Total), 0)
        FROM Gasto_Ordinario
        WHERE Id_Consorcio = @Id_Consorcio
          AND YEAR(Fecha) = @Anio AND MONTH(Fecha) = @Mes;

        SELECT @TotalExtraordinarios = ISNULL(SUM(Importe), 0)
        FROM Gasto_Extraordinario
        WHERE Id_Consorcio = @Id_Consorcio
          AND YEAR(Fecha) = @Anio AND MONTH(Fecha) = @Mes;

        -- 3. Insertar la liquidación mensual (encabezado)
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
            DATEADD(DAY, 10, @FechaEmision), -- 1er Vencimiento en 10 días
            DATEADD(DAY, 20, @FechaEmision), -- 2do Vencimiento en 20 días
            @TotalOrdinarios,
            @TotalExtraordinarios
        );

        SET @Id_Liquidacion_Generada = SCOPE_IDENTITY();
        
        PRINT 'Liquidación mensual generada exitosamente con ID: ' + CAST(@Id_Liquidacion_Generada AS VARCHAR);

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo generar la liquidación mensual.';
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
        -- 1. Obtener datos de la liquidación "padre" y del consorcio
        SELECT 
            @Id_Consorcio = L.Id_Consorcio,
            -- Importante: Convertimos el PERIODO (datetime) a DATE aquí
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
            THROW 50001, 'No se encontró la liquidación mensual especificada.', 1;
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
            (ISNULL(PREV_DET.Total_A_Pagar - PREV_DET.Pagos_Recibidos_Mes, 0) * 0.05) + -- Interés
            (@TotalOrd * UF.Coeficiente / 100) + 
            (CASE WHEN UF.Cochera = 1 THEN @PrecioCochera ELSE 0 END) +
            (CASE WHEN UF.Baulera = 1 THEN @PrecioBaulera ELSE 0 END) +
            (@TotalExt * UF.Coeficiente / 100)
            AS Total_A_Pagar

        FROM Unidad_Funcional AS UF
        
        -- Buscamos la liquidación del mes anterior
        LEFT JOIN Liquidacion_Mensual AS PREV_LIQ 
            ON PREV_LIQ.Id_Consorcio = UF.Id_Consorcio
            -- *** LA CORRECCIÓN ESTÁ AQUÍ ***
            -- Comparamos DATE vs DATE, en lugar de DATETIME vs DATE
            AND CAST(PREV_LIQ.Periodo AS DATE) = DATEADD(MONTH, -1, @Periodo)

        -- Buscamos el detalle de expensa de esa liquidación anterior
        LEFT JOIN Detalle_Expensa_UF AS PREV_DET
            ON PREV_DET.Id_Expensa = PREV_LIQ.Id_Liquidacion_Mensual
            AND PREV_DET.NroUf = UF.NroUf

        WHERE UF.Id_Consorcio = @Id_Consorcio;

        PRINT 'Detalles de expensas (CORREGIDOS) generados para la liquidación ID: ' + CAST(@Id_Liquidacion_Mensual AS VARCHAR);

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

    -- 1. Identificar pagos "Asociados" que NO hayan sido procesados
    SELECT 
        P.Id_Pago,
        P.Importe,
        P.Cuenta_Origen,
        UP.Id_Consorcio,
        UP.NroUf
    INTO #PagosAProcesar
    FROM Pago AS P
    -- Cruce para encontrar la UF dueña del CBU/CVU
    JOIN Persona AS PER ON P.Cuenta_Origen = PER.Cbu_Cvu
    JOIN Unidad_Persona AS UP ON PER.Id_Persona = UP.Id_Persona AND UP.Fecha_Fin IS NULL
    -- Condición: El pago está asociado Y NO está procesado
    WHERE P.Es_Pago_Asociado = 1
      AND P.Procesado = 0; -- <-- ESTA ES LA CLAVE NUEVA

    PRINT 'Pagos nuevos a procesar encontrados: ' + CAST(@@ROWCOUNT AS VARCHAR);

    -- 2. Declarar cursor para iterar pago por pago
    DECLARE @IdPago INT, @ImportePago DECIMAL(9,2), @IdConsorcio INT, @NroUF VARCHAR(10);
    DECLARE @MontoRestantePago DECIMAL(9,2);

    DECLARE PagosCursor CURSOR FOR 
        SELECT Id_Pago, Importe, Id_Consorcio, NroUf 
        FROM #PagosAProcesar
        WHERE Id_Consorcio IS NOT NULL; -- Solo procesamos los que encontramos UF

    OPEN PagosCursor;
    FETCH NEXT FROM PagosCursor INTO @IdPago, @ImportePago, @IdConsorcio, @NroUF;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @MontoRestantePago = @ImportePago;
        PRINT 'Procesando Pago ID: ' + CAST(@IdPago AS VARCHAR) + ' por ' + CAST(@ImportePago AS VARCHAR) + ' para UF: ' + @NroUF;

        -- 3. Loop interno: Aplicar el pago a las deudas (expensas) más antiguas primero
        WHILE @MontoRestantePago > 0
        BEGIN
            DECLARE @IdDetalleExpensa INT = NULL;
            DECLARE @MontoAdeudado DECIMAL(9,2) = 0;

            -- Buscamos la expensa más antigua con saldo deudor
            SELECT TOP 1
                @IdDetalleExpensa = DE.Id_Detalle_Expensa,
                -- La deuda es el total MENOS lo que ya se haya pagado (quizás de un pago anterior)
                @MontoAdeudado = (DE.Total_A_Pagar - DE.Pagos_Recibidos_Mes)
            FROM Detalle_Expensa_UF AS DE
            JOIN Liquidacion_Mensual AS LM ON DE.Id_Expensa = LM.Id_Liquidacion_Mensual
            WHERE DE.Id_Consorcio = @IdConsorcio
              AND DE.NroUf = @NroUF
              AND (DE.Total_A_Pagar - DE.Pagos_Recibidos_Mes) > 0.01 -- Umbral de deuda
            ORDER BY LM.Periodo ASC; -- DEUDA MÁS ANTIGUA

            -- Si no hay más deuda para esta UF, salimos del loop interno
            IF @IdDetalleExpensa IS NULL
            BEGIN
                PRINT 'No hay más deuda para la UF: ' + @NroUF + '. (Sobrante: ' + CAST(@MontoRestantePago AS VARCHAR) + ')';
                BREAK; -- Rompe el WHILE interno
            END

            DECLARE @MontoAAplicar DECIMAL(9,2);

            IF @MontoRestantePago >= @MontoAdeudado
                SET @MontoAAplicar = @MontoAdeudado; -- El pago cubre la deuda
            ELSE
                SET @MontoAAplicar = @MontoRestantePago; -- El pago es parcial

            BEGIN TRY
                -- 4. Actualizar la tabla de expensas
                UPDATE Detalle_Expensa_UF
                SET Pagos_Recibidos_Mes = Pagos_Recibidos_Mes + @MontoAAplicar
                WHERE Id_Detalle_Expensa = @IdDetalleExpensa;
                
                -- Reducimos el monto restante del pago
                SET @MontoRestantePago = @MontoRestantePago - @MontoAAplicar;
                PRINT '  -> Aplicados ' + CAST(@MontoAAplicar AS VARCHAR) + ' a Expensa ID: ' + CAST(@IdDetalleExpensa AS VARCHAR) + '. Restante: ' + CAST(@MontoRestantePago AS VARCHAR);

            END TRY
            BEGIN CATCH
                PRINT 'ERROR: Falla al aplicar pago ID ' + CAST(@IdPago AS VARCHAR) + ' a expensa ID ' + CAST(@IdDetalleExpensa AS VARCHAR);
                PRINT ERROR_MESSAGE();
                BREAK; 
            END CATCH
        END -- Fin loop interno (aplicación de un pago)

        -- 5. MARCAMOS EL PAGO COMO PROCESADO
        -- Lo hacemos fuera del loop interno, una vez que el pago se consumió
        -- o ya no hay más deuda donde aplicarlo.
        UPDATE Pago
        SET Procesado = 1
        WHERE Id_Pago = @IdPago;
        
        PRINT 'Pago ID ' + CAST(@IdPago AS VARCHAR) + ' marcado como Procesado.';

        FETCH NEXT FROM PagosCursor INTO @IdPago, @ImportePago, @IdConsorcio, @NroUF;
    END -- Fin loop externo (cursor de pagos)

    CLOSE PagosCursor;
    DEALLOCATE PagosCursor;

    DROP TABLE #PagosAProcesar;
    PRINT 'Proceso de imputación de pagos (CORREGIDO) finalizado.';
    SET NOCOUNT OFF;
END
GO
