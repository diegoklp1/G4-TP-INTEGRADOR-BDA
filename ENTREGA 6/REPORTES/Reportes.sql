-- =========================================================
-- SCRIPT: Reportes.sql
-- PROPÓSITO: Generación del Store Procedure para generación
-- del reporte para analizar el flujo de caja en forma 
-- semanal.
-- Implementación de formato XML.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

---Reporte 1
--Se desea analizar el flujo de caja en forma semanal. Debe presentar la recaudación por
--pagos ordinarios y extraordinarios de cada semana, el promedio en el periodo, y el
--acumulado progresivo.
USE COM5600_G04;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ReporteRecaudacionSemanal
    @FechaInicio DATE,
    @FechaFin DATE,
    @IdConsorcio INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PagosFiltrados AS (
        SELECT 
            P.Id_Pago,
            P.Fecha,
            DP.Importe_Usado,
            DEU.Importe_Ordinario_Prorrateado,
            DEU.Importe_Extraordinario_Prorrateado
        FROM dbo.Pago P
        INNER JOIN dbo.Detalle_Pago DP ON DP.Id_Pago = P.Id_Pago
        INNER JOIN dbo.Detalle_Expensa_UF DEU ON DEU.Id_Detalle_Expensa = DP.Id_Detalle_Expensa
        INNER JOIN dbo.Liquidacion_Mensual LM ON LM.Id_Liquidacion_Mensual = DEU.Id_Expensa
        WHERE 
            LM.Id_Consorcio = @IdConsorcio
            AND P.Fecha BETWEEN @FechaInicio AND @FechaFin
    ),
    PagosClasificados AS (
        SELECT 
            Fecha,
            Importe_Usado,
            CASE 
                WHEN (Importe_Ordinario_Prorrateado + Importe_Extraordinario_Prorrateado) = 0 THEN 0
                ELSE Importe_Usado * (Importe_Ordinario_Prorrateado /
                        (Importe_Ordinario_Prorrateado + Importe_Extraordinario_Prorrateado))
            END AS PagoOrdinario,
            CASE 
                WHEN (Importe_Ordinario_Prorrateado + Importe_Extraordinario_Prorrateado) = 0 THEN 0
                ELSE Importe_Usado * (Importe_Extraordinario_Prorrateado /
                        (Importe_Ordinario_Prorrateado + Importe_Extraordinario_Prorrateado))
            END AS PagoExtraordinario
        FROM PagosFiltrados
    ),
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
    Resultado AS (
        SELECT
            *,
            SUM(TotalSemana) OVER (ORDER BY Anio, SemanaISO) AS AcumuladoProgresivo,
            AVG(TotalSemana) OVER () AS PromedioPeriodo
        FROM Semanas
    )
    SELECT
        Anio,
        SemanaISO,
        TotalOrdinario,
        TotalExtraordinario,
        TotalSemana,
        AcumuladoProgresivo,
        PromedioPeriodo
    FROM Resultado
    ORDER BY Anio, SemanaISO
    FOR XML RAW('Fila'), ROOT('RecaudacionSemanal'), ELEMENTS;
END
GO
