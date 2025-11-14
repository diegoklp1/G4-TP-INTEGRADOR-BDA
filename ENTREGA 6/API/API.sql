-- =========================================================
-- SCRIPT: API.sql
-- PROPOSITO: Implementacion de API Feriados para busqueda
-- de dias habiles o no habiles.
--
-- IMPORTANTE: Puede que necesite configurar el protocolo de
-- conexion desde powershell
-- Ejecutar desde powershell la siguiente linea de codigo:
-- [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

-- Fecha de entrega:	14/11/2025
-- Comision:			5600
-- Grupo:				04
-- Materia:				Bases de datos aplicada
-- Integrantes:
-- - Llanos Franco , DNI: 43629080
-- - Varela Daniel , DNI: 40388978
-- - Llanos Diego  , DNI: 45748387

-- =========================================================

CREATE OR ALTER PROCEDURE dbo.EsDiaNoHabil
    @fecha DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET DATEFIRST 1; -- Lunes = 1

    DECLARE @anio INT = YEAR(@fecha);

    -- 1. Llamar API de feriados
    DECLARE @URL NVARCHAR(500) = 
        'https://api.argentinadatos.com/v1/feriados/' + CONVERT(VARCHAR(4), @anio);

    DECLARE @Object INT,
            @ResponseText NVARCHAR(MAX);

    EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
    EXEC sp_OAMethod @Object, 'open', NULL, 'GET', @URL, false;
    EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'User-Agent', 'SQLServer';
    EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'Accept', 'application/json';
    EXEC sp_OAMethod @Object, 'send';
    EXEC sp_OAMethod @Object, 'responseText', @ResponseText OUTPUT;
    EXEC sp_OADestroy @Object;

    -- 2. Parsear feriados
    ;WITH Feriados AS (
        SELECT CAST(fecha AS DATE) AS fecha
        FROM OPENJSON(@ResponseText)
             WITH (fecha DATE '$.fecha')
    )

    -- 3. Devolver 1 (habil) o 0 (no habil)
    SELECT 
        CASE 
            WHEN DATEPART(weekday, @fecha) IN (6, 7)
                 OR EXISTS (SELECT 1 FROM Feriados WHERE fecha = @fecha)
            THEN 0
            ELSE 1
        END AS EsNoHabil;
END
GO
