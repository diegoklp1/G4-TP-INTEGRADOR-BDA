---Reporte 5
--Obtenga los 3 (tres) propietarios con mayor morosidad. Presente información de contacto y
--DNI de los propietarios para que la administración los pueda contactar o remitir el trámite al
--estudio jurídico.
USE COM5600_G04;
GO

CREATE OR ALTER PROCEDURE sp_ReporteTop3MorososPorConsorcioPisoAnio
    @Id_Consorcio INT,
    @Piso VARCHAR(5),
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH CTE_Morosidad AS (
        SELECT 
            c.Id_Consorcio,
            uf.NroUF,
            uf.Piso,
            p.Id_Persona,
            p.Apellido + ', ' + p.Nombre AS Propietario,
            p.DNI,
            p.Email,
            p.Telefono,
            lm.Periodo,
            lm.Fecha_Vencimiento1,
            pag.Fecha AS Fecha_Pago,
            DATEDIFF(DAY, lm.Fecha_Vencimiento1, pag.Fecha) AS Dias_Mora
        FROM Pago pag
        INNER JOIN Detalle_Pago dp ON pag.Id_Pago = dp.Id_Pago
        INNER JOIN Detalle_Expensa_UF deu ON dp.Id_Detalle_Expensa = deu.Id_Detalle_Expensa
        INNER JOIN Liquidacion_Mensual lm ON lm.Id_Liquidacion_Mensual = deu.Id_Expensa
        INNER JOIN Unidad_Funcional uf ON uf.Id_Consorcio = deu.Id_Consorcio AND uf.NroUF = deu.NroUF
        INNER JOIN Unidad_Persona up ON up.Id_Consorcio = uf.Id_Consorcio AND up.NroUF = uf.NroUF
        INNER JOIN Persona p ON p.Id_Persona = up.Id_Persona
        INNER JOIN Consorcio c ON c.Id_Consorcio = uf.Id_Consorcio
        WHERE 
            c.Id_Consorcio = @Id_Consorcio
            AND uf.Piso = @Piso
            AND YEAR(lm.Periodo) = @Anio
            AND up.Fecha_Fin IS NULL
            AND DATEDIFF(DAY, lm.Fecha_Vencimiento1, pag.Fecha) > 0
    )
    SELECT TOP 3
        Propietario,
        DNI,
        Email,
        Telefono,
        Piso,
        AVG(Dias_Mora) AS Promedio_Dias_Mora,
        COUNT(DISTINCT Periodo) AS Cant_Periodos_Moroso,
        SUM(CASE WHEN Dias_Mora > 0 THEN 1 ELSE 0 END) AS Cant_Pagos_Tardios
    FROM CTE_Morosidad
    GROUP BY Propietario, DNI, Email, Telefono, Piso
    ORDER BY Promedio_Dias_Mora DESC, Cant_Pagos_Tardios DESC;
END;
GO


