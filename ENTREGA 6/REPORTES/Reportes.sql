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

CREATE PROCEDURE dbo.sp_ReporteRecaudacionSemanal
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

    ;WITH RecaudacionBase AS (
        /* 1. Obtenemos todos los pagos y los componentes de la expensa a la que se aplicaron */
        SELECT 
            FORMAT(p.Fecha, 'yyyy-MM') AS Periodo,
            dp.Importe_Usado,
            
            -- Componentes de la expensa
            dexp.Importe_Ordinario_Prorrateado,
            dexp.Importe_Extraordinario_Prorrateado,
            dexp.Interes_Por_Mora,
            
            -- Calculamos el total de los componentes de esa expensa
            (dexp.Importe_Ordinario_Prorrateado + dexp.Importe_Extraordinario_Prorrateado + dexp.Interes_Por_Mora) AS TotalComponentes
            
        FROM Pago p
        INNER JOIN Detalle_Pago dp ON dp.Id_Pago = p.Id_Pago
        INNER JOIN Detalle_Expensa_UF dexp ON dp.Id_Detalle_Expensa = dexp.Id_Detalle_Expensa
        WHERE 
            p.Fecha BETWEEN @FechaInicio AND @FechaFin
            AND dexp.Id_Consorcio = @IdConsorcio
    ),
    PagosProporcionales AS (
        /* 2. Distribuimos proporcionalmente el 'Importe_Usado' */
        SELECT
            Periodo,
            
            -- Pago Ordinario
            CASE 
                WHEN TotalComponentes = 0 THEN 0
                ELSE Importe_Usado * (Importe_Ordinario_Prorrateado / TotalComponentes)
            END AS PagoOrdinario,
            
            -- Pago Extraordinario
            CASE 
                WHEN TotalComponentes = 0 THEN 0
                ELSE Importe_Usado * (Importe_Extraordinario_Prorrateado / TotalComponentes)
            END AS PagoExtraordinario,
            
            -- Pago Mora
            CASE 
                WHEN TotalComponentes = 0 THEN 0
                ELSE Importe_Usado * (Interes_Por_Mora / TotalComponentes)
            END AS PagoMora
            
        FROM RecaudacionBase
        WHERE TotalComponentes > 0 
    )
    /* 3. Agrupamos por período. Esto crea el "cuadro cruzado" que pide el PIVOT, 
          pero de forma más simple y robusta.
    */
    SELECT 
        Periodo,
        ISNULL(SUM(PagoOrdinario), 0) AS [Ordinario],
        ISNULL(SUM(PagoExtraordinario), 0) AS [Extraordinario],
        ISNULL(SUM(PagoMora), 0) AS [Mora]       
    FROM PagosProporcionales
    GROUP BY Periodo
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

/*
  VERSIÓN CORREGIDA DE SP_REPORTETOP3MOROSOS
  - La lógica se basa en la deuda pendiente (Total - Pagos)
    de la tabla Detalle_Expensa_UF.
  - Ya no se une con Pago/Detalle_Pago, lo que nos permite
    encontrar a la gente que NO pagó.
*/
CREATE OR ALTER PROCEDURE sp_ReporteTop3MorososPorConsorcioPisoAnio
    @Id_Consorcio INT,
    @Piso VARCHAR(5),
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH CTE_Deuda AS (
        SELECT 
            p.Id_Persona,
            -- Desciframos los datos personales para el reporte
            p.Apellido,
            p.Nombre,
            p.DNI,
            p.Email,
            p.Telefono,
            uf.Piso,
            lm.Periodo,
            (deu.Total_A_Pagar - deu.Pagos_Recibidos_Mes) AS Saldo_Pendiente
        FROM Detalle_Expensa_UF deu
        INNER JOIN Liquidacion_Mensual lm ON lm.Id_Liquidacion_Mensual = deu.Id_Expensa
        INNER JOIN Unidad_Funcional uf ON uf.Id_Consorcio = deu.Id_Consorcio AND uf.NroUF = deu.NroUF
        INNER JOIN Unidad_Persona up ON up.Id_Consorcio = uf.Id_Consorcio AND up.NroUF = uf.NroUF
        INNER JOIN Persona p ON p.Id_Persona = up.Id_Persona
        WHERE 
            deu.Id_Consorcio = @Id_Consorcio
            AND uf.Piso = @Piso
            AND YEAR(lm.Periodo) = @Anio
            AND up.Fecha_Fin IS NULL
            AND (deu.Total_A_Pagar - deu.Pagos_Recibidos_Mes) > 0.00
    )
    SELECT TOP 3
        Nombre,
		Apellido,
        DNI,
        Email,
        Telefono,
        Piso,
        SUM(Saldo_Pendiente) AS DeudaTotalAcumulada,
        COUNT(DISTINCT Periodo) AS Cant_Periodos_Adeudados
    FROM CTE_Deuda
    GROUP BY Nombre,Apellido,DNI, Email, Telefono, Piso
    ORDER BY DeudaTotalAcumulada DESC;

END;
GO
/*
CREATE OR ALTER PROCEDURE sp_ReporteTop3MorososPorConsorcioPisoAnio
    @Id_Consorcio INT,
    @Piso VARCHAR(5),
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Abrir la clave para descifrar los datos
    OPEN SYMMETRIC KEY Key_DatosSensibles
    DECRYPTION BY CERTIFICATE Cert_Cifrado_Datos;

    ;WITH CTE_Deuda AS (
        SELECT 
            p.Id_Persona,
            -- Desciframos los datos personales para el reporte
            CONVERT(VARCHAR, DECRYPTBYKEY(p.Apellido)) + ', ' + 
            CONVERT(VARCHAR, DECRYPTBYKEY(p.Nombre)) AS Propietario,
            CONVERT(VARCHAR, DECRYPTBYKEY(p.DNI)) AS DNI,
            CONVERT(VARCHAR, DECRYPTBYKEY(p.Email)) AS Email,
            CONVERT(VARCHAR, DECRYPTBYKEY(p.Telefono)) AS Telefono,
            uf.Piso,
            lm.Periodo,
            -- Esta es la verdadera medida de morosidad: el saldo pendiente
            (deu.Total_A_Pagar - deu.Pagos_Recibidos_Mes) AS Saldo_Pendiente
        FROM Detalle_Expensa_UF deu
        INNER JOIN Liquidacion_Mensual lm ON lm.Id_Liquidacion_Mensual = deu.Id_Expensa
        INNER JOIN Unidad_Funcional uf ON uf.Id_Consorcio = deu.Id_Consorcio AND uf.NroUF = deu.NroUF
        INNER JOIN Unidad_Persona up ON up.Id_Consorcio = uf.Id_Consorcio AND up.NroUF = uf.NroUF
        INNER JOIN Persona p ON p.Id_Persona = up.Id_Persona
        WHERE 
            deu.Id_Consorcio = @Id_Consorcio
            AND uf.Piso = @Piso
            AND YEAR(lm.Periodo) = @Anio
            AND up.Fecha_Fin IS NULL
            -- Buscamos expensas que tengan un saldo pendiente
            AND (deu.Total_A_Pagar - deu.Pagos_Recibidos_Mes) > 0.01 
    )
    SELECT TOP 3
        Propietario,
        DNI,
        Email,
        Telefono,
        Piso,
        SUM(Saldo_Pendiente) AS DeudaTotalAcumulada,
        COUNT(DISTINCT Periodo) AS Cant_Periodos_Adeudados
    FROM CTE_Deuda
    GROUP BY Propietario, DNI, Email, Telefono, Piso
    ORDER BY DeudaTotalAcumulada DESC;

    -- 2. Cerrar la clave
    CLOSE SYMMETRIC KEY Key_DatosSensibles;
END;
GO
*/

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
        INNER JOIN Detalle_Expensa_UF dexp ON dp.Id_Detalle_Expensa = dexp.Id_Detalle_Expensa
        INNER JOIN Unidad_Funcional uf ON uf.Id_Consorcio = dexp.Id_Consorcio AND uf.NroUF = dexp.NroUF
        WHERE 
            dexp.Importe_Ordinario_Prorrateado > 0
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
    GROUP BY NroUF, FechaPago, FechaPagoSiguiente
    ORDER BY NroUF, FechaPago;;
END;
GO


