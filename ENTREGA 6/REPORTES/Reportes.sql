---Reporte 1
--Store Procedure para generar reporte
CREATE OR ALTER PROCEDURE sp_ReporteRecaudacionSemanal
    @FechaInicio DATE,
    @FechaFin DATE,
    @IdConsorcio INT
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------------------
    -- 1. Filtrar pagos por consorcio y rango de fecha
    --------------------------------------------------------------------
    ;WITH PagosFiltrados AS (
        SELECT 
            P.Id_Pago,
            P.Fecha,
            DP.Importe_Usado,
            DEU.Importe_Ordinario_Prorrateado,
            DEU.Importe_Extraordinario_Prorrateado
        FROM Pago P
        INNER JOIN Detalle_Pago DP ON DP.Id_Pago = P.Id_Pago
        INNER JOIN Detalle_Expensa_UF DEU ON DEU.Id_Detalle_Expensa = DP.Id_Detalle_Expensa
        INNER JOIN Liquidacion_Mensual LM ON LM.Id_Liquidacion_Mensual = DEU.Id_Expensa
        WHERE 
            LM.Id_Consorcio = @IdConsorcio
            AND P.Fecha BETWEEN @FechaInicio AND @FechaFin
    ),

    --------------------------------------------------------------------
    -- 2. Proporción de ordinario / extraordinario por expensa
    --------------------------------------------------------------------
    PagosClasificados AS (
        SELECT 
            Fecha,
            Importe_Usado,
            CASE 
                WHEN (Importe_Ordinario_Prorrateado + Importe_Extraordinario_Prorrateado) = 0 
                     THEN 0
                ELSE Importe_Usado * (Importe_Ordinario_Prorrateado /
                        (Importe_Ordinario_Prorrateado + Importe_Extraordinario_Prorrateado))
            END AS PagoOrdinario,
            CASE 
                WHEN (Importe_Ordinario_Prorrateado + Importe_Extraordinario_Prorrateado) = 0 
                     THEN 0
                ELSE Importe_Usado * (Importe_Extraordinario_Prorrateado /
                        (Importe_Ordinario_Prorrateado + Importe_Extraordinario_Prorrateado))
            END AS PagoExtraordinario
        FROM PagosFiltrados
    ),

    --------------------------------------------------------------------
    -- 3. Agregado semanal
    --------------------------------------------------------------------
    Semanas AS (
        SELECT
            DATEPART(YEAR, Fecha) AS Anio,
            DATEPART(WEEK, Fecha) AS SemanaISO,
            SUM(PagoOrdinario) AS TotalOrdinario,
            SUM(PagoExtraordinario) AS TotalExtraordinario,
            SUM(Importe_Usado) AS TotalSemana
        FROM PagosClasificados
        GROUP BY DATEPART(YEAR, Fecha), DATEPART(WEEK, Fecha)
    ),

    --------------------------------------------------------------------
    -- 4. Acumulado progresivo y promedio del periodo
    --------------------------------------------------------------------
    Resultado AS (
        SELECT
            *,
            SUM(TotalSemana) OVER (ORDER BY Anio, SemanaISO) AS AcumuladoProgresivo,
            AVG(TotalSemana) OVER () AS PromedioPeriodo
        FROM Semanas
    )

    SELECT *
    FROM Resultado
    ORDER BY Anio, SemanaISO;

END
