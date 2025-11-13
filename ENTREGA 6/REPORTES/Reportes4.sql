-- =========================================================
-- SCRIPT: Reportes4.sql
-- PROPÓSITO: Generación del Store Procedure para generación
-- del reporte para obtener los 5 (cinco) meses de mayores 
-- gastos y los 5 (cinco) de mayores ingresos.
-- Implementamos el formato del reporte en XML.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

---Reporte 4
--Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos.
USE COM5600_G04;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ReporteTopMesesIngresosGastos
    @IdConsorcio INT,
    @IdTipoGasto INT = NULL,  -- puede ser NULL si se quiere traer todos
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    -----------------------------------
    -- GASTOS (ordinarios + extraordinarios)
    -----------------------------------
    ;WITH GastosOrdinarios AS (
        SELECT 
            MONTH(go.Fecha) AS Mes,
            YEAR(go.Fecha) AS Anio,
            SUM(go.Importe_Total) AS TotalGasto,
            'Gasto Ordinario' AS Tipo
        FROM dbo.Gasto_Ordinario go
        WHERE 
            go.Id_Consorcio = @IdConsorcio
            AND YEAR(go.Fecha) = @Anio
            AND (@IdTipoGasto IS NULL OR go.Id_Tipo_Gasto = @IdTipoGasto)
        GROUP BY YEAR(go.Fecha), MONTH(go.Fecha)
    ),
    GastosExtraordinarios AS (
        SELECT 
            MONTH(ge.Fecha) AS Mes,
            YEAR(ge.Fecha) AS Anio,
            SUM(ge.Importe) AS TotalGasto,
            'Gasto Extraordinario' AS Tipo
        FROM dbo.Gasto_Extraordinario ge
        WHERE 
            ge.Id_Consorcio = @IdConsorcio
            AND YEAR(ge.Fecha) = @Anio
        GROUP BY YEAR(ge.Fecha), MONTH(ge.Fecha)
    ),
    TodosLosGastos AS (
        SELECT * FROM GastosOrdinarios
        UNION ALL
        SELECT * FROM GastosExtraordinarios
    ),
    TopGastos AS (
        SELECT TOP 5 
            Mes,
            Anio,
            SUM(TotalGasto) AS TotalGasto,
            STRING_AGG(Tipo, ', ') AS TiposIncluidos
        FROM TodosLosGastos
        GROUP BY Anio, Mes
        ORDER BY TotalGasto DESC
    ),
    -----------------------------------
    -- INGRESOS
    -----------------------------------
    IngresosMensuales AS (
        SELECT 
            MONTH(p.Fecha) AS Mes,
            YEAR(p.Fecha) AS Anio,
            SUM(dp.Importe_Usado) AS TotalIngreso
        FROM dbo.Pago p
        INNER JOIN dbo.Detalle_Pago dp ON dp.Id_Pago = p.Id_Pago
        INNER JOIN dbo.Detalle_Expensa_UF dexp ON dp.Id_Detalle_Expensa = dexp.Id_Detalle_Expensa
        WHERE 
            dexp.Id_Consorcio = @IdConsorcio
            AND YEAR(p.Fecha) = @Anio
        GROUP BY YEAR(p.Fecha), MONTH(p.Fecha)
    ),
    TopIngresos AS (
        SELECT TOP 5 
            Mes,
            Anio,
            TotalIngreso
        FROM IngresosMensuales
        ORDER BY TotalIngreso DESC
    )

    -----------------------------------
    -- SALIDA EN FORMATO XML
    -----------------------------------
    SELECT
        (SELECT 
            Mes,
            Anio,
            TotalGasto,
            TiposIncluidos
         FROM TopGastos
         FOR XML RAW('FilaGasto'), ELEMENTS, ROOT('TopGastos'), TYPE),

        (SELECT 
            Mes,
            Anio,
            TotalIngreso
         FROM TopIngresos
         FOR XML RAW('FilaIngreso'), ELEMENTS, ROOT('TopIngresos'), TYPE)
    FOR XML PATH('ReporteTopMesesIngresosGastos');
END;
GO
