--FALTA - CONTINUAR
CREATE OR ALTER PROCEDURE sp_ReporteRecaudacionSemanal
(
    @FechaDesde DATE,
    @FechaHasta DATE,
    @SoloTipo VARCHAR(20) = 'Todos'     -- 'Ordinario', 'Extraordinario' o 'Todos'
)
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- 1) Filtrar datos base según los parámetros
    -------------------------------------------------------------
    ;WITH Datos AS (
        SELECT 
            fecha,
            monto,
            tipo
        FROM Pagos
        WHERE fecha BETWEEN @FechaDesde AND @FechaHasta
          AND (
                @SoloTipo = 'Todos'
                OR tipo = @SoloTipo
              )
    ),

    -------------------------------------------------------------
    -- 2) Agrupar por semana
    -------------------------------------------------------------
    Semanas AS (
        SELECT 
            DATEPART(YEAR, fecha)  AS Anio,
            DATEPART(WEEK, fecha)  AS Semana,
            SUM(CASE WHEN tipo = 'Ordinario'     THEN monto ELSE 0 END) AS TotalOrdinario,
            SUM(CASE WHEN tipo = 'Extraordinario' THEN monto ELSE 0 END) AS TotalExtraordinario,
            SUM(monto) AS TotalSemana
        FROM Datos
        GROUP BY 
            DATEPART(YEAR, fecha),
            DATEPART(WEEK, fecha)
    ),

    -------------------------------------------------------------
    -- 3) Agregar acumulado progresivo
    -------------------------------------------------------------
    SemanasConAcumulado AS (
        SELECT 
            Anio,
            Semana,
            TotalOrdinario,
            TotalExtraordinario,
            TotalSemana,
            SUM(TotalSemana) OVER (ORDER BY Anio, Semana) AS AcumuladoProgresivo
        FROM Semanas
    ),

    -------------------------------------------------------------
    -- 4) Promedio semanal del periodo
    -------------------------------------------------------------
    Promedio AS (
        SELECT AVG(TotalSemana * 1.0) AS PromedioSemanal
        FROM Semanas
    )

    -------------------------------------------------------------
    -- 5) Reporte final
    -------------------------------------------------------------
    SELECT 
        s.Anio,
        s.Semana,
        s.TotalOrdinario,
        s.TotalExtraordinario,
        s.TotalSemana,
        s.AcumuladoProgresivo,
        p.PromedioSemanal
    FROM SemanasConAcumulado s CROSS JOIN Promedio p
    ORDER BY s.Anio, s.SeMana;
END;
GO
