---Reporte 2
---Presente el total de recaudación por mes y departamento en formato de tabla cruzada.
CREATE OR ALTER PROCEDURE sp_reporte_recaudacion_mensual_departamento
    @FechaInicio DATE,
    @FechaFin DATE,
    @IdConsorcio INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tabla temporal con recaudaciones base
    ;WITH Recaudacion AS (
        SELECT 
            uf.Departamento,
            FORMAT(p.Fecha, 'yyyy-MM') AS Periodo,
            SUM(dp.Importe_Usado) AS Total_Recaudado
        FROM Pago p
        INNER JOIN Detalle_Pago dp ON dp.Id_Pago = p.Id_Pago
        INNER JOIN Detalle_Expensa_UF dexp ON dexp.Id_Detalle_Expensa = dp.Id_Detalle_Expensa
        INNER JOIN Unidad_Funcional uf ON uf.Id_Consorcio = dexp.Id_Consorcio AND uf.NroUF = dexp.NroUF
        WHERE 
            p.Fecha BETWEEN @FechaInicio AND @FechaFin
            AND dexp.Id_Consorcio = @IdConsorcio
        GROUP BY uf.Departamento, FORMAT(p.Fecha, 'yyyy-MM')
    )

    -- Pivoteamos los meses
    SELECT *
    FROM Recaudacion
    PIVOT (
        SUM(Total_Recaudado)
        FOR Periodo IN ([2025-01], [2025-02], [2025-03], [2025-04], [2025-05],
                        [2025-06], [2025-07], [2025-08], [2025-09], [2025-10], [2025-11], [2025-12])
    ) AS TablaCruzada
    ORDER BY Departamento;
END;
GO
