--FALTA - CONTINUAR
--Seteo la fecha con uno para los lunes
SET DATEFIRST 1; -- Lunes = 1

DECLARE @fecha DATE = GETDATE();
-- DECLARE @fecha DATE = '2025-11-01';

DECLARE @año INT = YEAR(@fecha);

-- 1. Llamar API de feriados
DECLARE @URL NVARCHAR(500) = 'https://api.argentinadatos.com/v1/feriados/' + CONVERT(VARCHAR(4), @año);
DECLARE @Object INT,
        @ResponseText NVARCHAR(MAX);

EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
EXEC sp_OAMethod @Object, 'open', NULL, 'GET', @URL, false;
EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'User-Agent', 'SQLServer';
EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'Accept', 'application/json';
EXEC sp_OAMethod @Object, 'send';
EXEC sp_OAMethod @Object, 'responseText', @ResponseText OUTPUT;
EXEC sp_OADestroy @Object;

-- 2. Parsear feriados en tabla temporal
;WITH Feriados AS (
    SELECT CAST(fecha AS DATE) AS fecha
    FROM OPENJSON(@ResponseText)
         WITH (fecha DATE '$.fecha')
)

-- 3. Generar días del mes, filtrar hábiles no feriados, numerar
, DiasMes AS (
    SELECT DATEADD(day, v.number, DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)) AS fecha
    FROM master..spt_values v
    WHERE v.type = 'P'
      AND v.number BETWEEN 0 AND 31
      AND MONTH(DATEADD(day, v.number, DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1))) = MONTH(@fecha)
)
, DiasHabilesNoFeriados AS (
    SELECT d.fecha
    FROM DiasMes d
    LEFT JOIN Feriados f
      ON d.fecha = f.fecha
    WHERE DATEPART(weekday, d.fecha) NOT IN (6,7)  -- lunes-viernes
      AND f.fecha IS NULL                          -- no feriado
)
, DiasConRanking AS (
    SELECT fecha,
           ROW_NUMBER() OVER (ORDER BY fecha) AS NumeroDiaHabil
    FROM DiasHabilesNoFeriados
)
, QuintoDia AS (
    SELECT fecha AS QuintoDiaHabil
    FROM DiasConRanking
    WHERE NumeroDiaHabil = 5
)

-- 4. Resultado final
SELECT
    DATENAME(weekday, @fecha) AS NombreDia,
    DATEPART(weekday, @fecha) AS NumeroDiaISO,
    CONVERT(VARCHAR(10), @fecha, 23) AS Fecha_YYYYMMDD,
    CASE
      WHEN DATEPART(weekday, @fecha) IN (6, 7) THEN 'Es Fin de Semana'
      WHEN EXISTS (SELECT 1 FROM Feriados WHERE fecha = @fecha) THEN 'Es Feriado'
      ELSE 'Es día habil'
    END AS EstadoDia,
    CONVERT(VARCHAR(10), (SELECT QuintoDiaHabil FROM QuintoDia), 23) AS QuintoDiaHabilDelMes,
    CASE
      WHEN @fecha = (SELECT QuintoDiaHabil FROM QuintoDia) THEN 'SI'
      ELSE 'NO'
    END AS EsHoyElQuintoDiaHabil;
