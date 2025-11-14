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

-- =========================================================
-- SCRIPT: Reportes2.sql
-- PROPÓSITO: Generación del Store Procedure para generación
-- del reporte donde se vea el total de recaudación por mes 
-- y departamento en formato de tabla cruzada.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

---Reporte 2
---Presente el total de recaudación por mes y departamento en formato de tabla cruzada.
USE COM5600_G04;
GO

CREATE OR ALTER PROCEDURE sp_ReporteRecaudacionMensualDepartamento
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

-- =========================================================
-- SCRIPT: Reportes3.sql
-- PROPÓSITO: Generación del Store Procedure para generación
-- del reporte con la recaudación total desagregada según 
-- su procedencia.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

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

-- =========================================================
-- SCRIPT: Reportes5.sql
-- PROPÓSITO: Generación del Store Procedure para generación
-- del reporte para obtener los 3 (tres) propietarios con 
-- mayor morosidad. 
-- Presente información de contacto y DNI de los propietarios 
-- para que la administración los pueda contactar o remitir 
-- el trámite al estudio jurídico.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

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


-- =========================================================
-- SCRIPT: Reportes6.sql
-- PROPÓSITO: Generación del Store Procedure para generación
-- del reporte que uestre las fechas de pagos de expensas 
-- ordinarias de cada UF y la cantidad de días que pasan 
-- entre un pago y el siguiente, para el conjunto examinado.

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

---Reporte 6
--Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de días que
--pasan entre un pago y el siguiente, para el conjunto examinado.
USE COM5600_G04;
GO

CREATE OR ALTER PROCEDURE sp_ReporteIntervaloPagosOrdinarios
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

