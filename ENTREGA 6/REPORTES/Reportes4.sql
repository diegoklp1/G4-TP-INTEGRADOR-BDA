---Reporte 4
--Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos.
CREATE OR ALTER PROCEDURE sp_top_meses_ingresos_gastos
    @IdConsorcio INT,
    @IdTipoGasto INT = NULL,  -- puede ser NULL si se quiere traer todos
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    -----------------------------------
    --GASTOS ORDINARIOS
    -----------------------------------
    ;WITH GastosOrdinarios AS (
        SELECT 
            MONTH(go.Fecha) AS Mes,
            YEAR(go.Fecha) AS Anio,
            SUM(go.Importe_Total) AS TotalGasto,
            'Gasto Ordinario' AS Tipo
        FROM Gasto_Ordinario go
        WHERE 
            go.Id_Consorcio = @IdConsorcio
            AND YEAR(go.Fecha) = @Anio
            AND (@IdTipoGasto IS NULL OR go.Id_Tipo_Gasto = @IdTipoGasto)
        GROUP BY YEAR(go.Fecha), MONTH(go.Fecha)
    ),
    -----------------------------------
    -- GASTOS EXTRAORDINARIOS
    -----------------------------------
    GastosExtraordinarios AS (
        SELECT 
            MONTH(ge.Fecha) AS Mes,
            YEAR(ge.Fecha) AS Anio,
            SUM(ge.Importe) AS TotalGasto,
            'Gasto Extraordinario' AS Tipo
        FROM Gasto_Extraordinario ge
        WHERE 
            ge.Id_Consorcio = @IdConsorcio
            AND YEAR(ge.Fecha) = @Anio
        GROUP BY YEAR(ge.Fecha), MONTH(ge.Fecha)
    ),
    -----------------------------------
    --UNION de ambos tipos de gasto
    -----------------------------------
    TodosLosGastos AS (
        SELECT * FROM GastosOrdinarios
        UNION ALL
        SELECT * FROM GastosExtraordinarios
    )

    SELECT TOP 5 
        Mes,
        Anio,
        SUM(TotalGasto) AS TotalGasto,
        STRING_AGG(Tipo, ', ') AS TiposIncluidos
    FROM TodosLosGastos
    GROUP BY Anio, Mes
    ORDER BY TotalGasto DESC;

    PRINT '---------------------------------';

    -----------------------------------
    -- INGRESOS
    -----------------------------------
    ;WITH IngresosMensuales AS (
        SELECT 
            MONTH(p.Fecha) AS Mes,
            YEAR(p.Fecha) AS Anio,
            SUM(dp.Importe_Usado) AS TotalIngreso
        FROM Pago p
        INNER JOIN Detalle_Pago dp ON dp.Id_Pago = p.Id_Pago
        INNER JOIN Detalle_Expensa_UF dexp ON dp.Id_Detalle_Expensa = dexp.Id_Detalle_Expensa
        WHERE 
            dexp.Id_Consorcio = @IdConsorcio
            AND YEAR(p.Fecha) = @Anio
        GROUP BY YEAR(p.Fecha), MONTH(p.Fecha)
    )
    SELECT TOP 5 
        Mes,
        Anio,
        TotalIngreso
    FROM IngresosMensuales
    ORDER BY TotalIngreso DESC;
END;
GO
