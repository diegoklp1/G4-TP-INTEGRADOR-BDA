---Reporte 3
--Presente un cuadro cruzado con la recaudación total desagregada según su procedencia
--(ordinario, extraordinario, etc.) según el periodo.
USE COM5600_G04;
GO

CREATE OR ALTER PROCEDURE sp_ReporteRecaudacionPorTipo
    @FechaInicio DATE,
    @FechaFin DATE,
    @IdConsorcio INT
AS
BEGIN
    SET NOCOUNT ON;

    /*
        El detalle de pagos se une con los tipos de ingreso (Tipo_Ingreso)
        y las fechas de los pagos. Filtramos por el consorcio y el rango de fechas.
    */

    ;WITH Recaudacion AS (
        SELECT 
            FORMAT(p.Fecha, 'yyyy-MM') AS Periodo,
            ti.Nombre AS TipoIngreso,
            SUM(dp.Importe_Usado) AS TotalRecaudado
        FROM Pago p
        INNER JOIN Detalle_Pago dp ON dp.Id_Pago = p.Id_Pago
        INNER JOIN Detalle_Expensa_UF dexp ON dp.Id_Detalle_Expensa = dexp.Id_Detalle_Expensa
        INNER JOIN Tipo_Ingreso ti ON ti.Id_Tipo_Ingreso = dp.Id_Tipo_Ingreso
        WHERE 
            p.Fecha BETWEEN @FechaInicio AND @FechaFin
            AND dexp.Id_Consorcio = @IdConsorcio
        GROUP BY FORMAT(p.Fecha, 'yyyy-MM'), ti.Nombre
    )

    -- Tabla cruzada (PIVOT) que muestra las recaudaciones por tipo de ingreso
    SELECT *
    FROM Recaudacion
    PIVOT (
        SUM(TotalRecaudado)
        FOR TipoIngreso IN ([Ordinario], [Extraordinario], [Mora], [Adelantado], [Otros])
    ) AS TablaCruzada
    ORDER BY Periodo;
END;
GO
