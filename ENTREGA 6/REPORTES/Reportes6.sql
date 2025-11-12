---Reporte 6
--Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de días que
--pasan entre un pago y el siguiente, para el conjunto examinado.
CREATE OR ALTER PROCEDURE sp_intervalo_pagos_ordinarios
    @FechaInicio DATE,
    @FechaFin DATE,
    @IdConsorcio INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PagosOrdinarios AS (
        SELECT 
            uf.NroUF,
            p.Fecha AS FechaPago,
            LEAD(p.Fecha) OVER (PARTITION BY uf.NroUF ORDER BY p.Fecha) AS FechaPagoSiguiente
        FROM Pago p
        INNER JOIN Detalle_Pago dp ON dp.Id_Pago = p.Id_Pago
        INNER JOIN Tipo_Ingreso ti ON ti.Id_Tipo_Ingreso = dp.Id_Tipo_Ingreso
        INNER JOIN Detalle_Expensa_UF dexp ON dp.Id_Detalle_Expensa = dexp.Id_Detalle_Expensa
        INNER JOIN Unidad_Funcional uf ON uf.Id_Consorcio = dexp.Id_Consorcio AND uf.NroUF = dexp.NroUF
        WHERE 
            ti.Nombre = 'Ordinario'
            AND p.Fecha BETWEEN @FechaInicio AND @FechaFin
            AND dexp.Id_Consorcio = @IdConsorcio
    )
    SELECT 
        NroUF,
        CONVERT(varchar(10), FechaPago, 23) AS FechaPago,
        CONVERT(varchar(10), FechaPagoSiguiente, 23) AS FechaPagoSiguiente,
        DATEDIFF(DAY, FechaPago, FechaPagoSiguiente) AS DiasEntrePagos
    FROM PagosOrdinarios
    WHERE FechaPagoSiguiente IS NOT NULL
    ORDER BY NroUF, FechaPago;
END;
GO

