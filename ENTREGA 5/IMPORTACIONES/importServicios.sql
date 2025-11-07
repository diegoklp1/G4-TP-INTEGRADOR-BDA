USE bd_tp_testeo;
GO
PRINT 'Insertando datos maestros en Tipo_Gasto...';
INSERT INTO Tipo_Gasto (Nombre) VALUES
('BANCARIOS'),
('LIMPIEZA'),
('ADMINISTRACION'),
('SEGUROS'),
('GASTOS GENERALES'),
('SERVICIOS PUBLICOS');

INSERT INTO Tipo_Servicio (Nombre) VALUES
('Agua'),
('Luz'),
('Gas'); 
GO

SELECT * FROM Tipo_Gasto
SELECT * FROM Tipo_Servicio
GO

USE bd_tp_testeo
GO

IF OBJECT_ID('sp_Importar_Gastos_JSON', 'P') IS NOT NULL
    DROP PROCEDURE sp_Importar_Gastos_JSON;
GO

CREATE PROCEDURE sp_Importar_Gastos_JSON
    @RutaArchivoJSON VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @JsonData NVARCHAR(MAX);
    DECLARE @Sql NVARCHAR(MAX);

    BEGIN TRY
        -- LECTURA
        PRINT 'Leyendo archivo JSON...';
        SET @Sql = N'
            SELECT @JsonDataOUT = BulkColumn
            FROM OPENROWSET (BULK ''' + @RutaArchivoJSON + ''', SINGLE_CLOB) AS J;';

        EXEC sp_executesql 
            @Sql, N'@JsonDataOUT NVARCHAR(MAX) OUTPUT', @JsonDataOUT = @JsonData OUTPUT;

        IF @JsonData IS NULL
        BEGIN
            THROW 50001, 'El archivo JSON está vacío o no se pudo leer.', 1;
        END

        PRINT 'Archivo JSON leído. Procesando...';


        CREATE TABLE #TempGastos (
            Id_Consorcio INT,
            Id_Tipo_Gasto INT,
            Fecha_Gasto DATE,
            Importe_Total DECIMAL(10, 2),
            Descripcion_Gasto VARCHAR(100)
        );

        -- ETL
        DECLARE @AnioActual INT = YEAR(GETDATE());
        
        INSERT INTO #TempGastos (Id_Consorcio, Id_Tipo_Gasto, Fecha_Gasto, Importe_Total, Descripcion_Gasto)
        SELECT
            C.Id_Consorcio,
            TG.Id_Tipo_Gasto,
            DATEFROMPARTS(@AnioActual, MesNumero.MesN, 1) AS Fecha_Gasto,
            TRY_CONVERT(DECIMAL(10, 2), 
                STUFF(REPLACE(REPLACE(Gastos_Unpivot.Importe_JSON, '.', ''), ',', ''), 
                      LEN(REPLACE(REPLACE(Gastos_Unpivot.Importe_JSON, '.', ''), ',', '')) - 1, 
                      0, 
                      '.')
            ) AS Importe_Total,

            Gastos_Unpivot.Tipo_Nombre + ' ' + JSON_Pivote.Mes_JSON AS Descripcion_Gasto

        FROM OPENJSON (@JsonData)
        WITH (
            NombreConsorcio_JSON VARCHAR(100) '$."Nombre del consorcio"',
            Mes_JSON VARCHAR(20) '$.Mes',
            Bancarios_JSON VARCHAR(50) '$.BANCARIOS',
            Limpieza_JSON VARCHAR(50) '$.LIMPIEZA',
            Admin_JSON VARCHAR(50) '$.ADMINISTRACION',
            Seguros_JSON VARCHAR(50) '$.SEGUROS',
            Generales_JSON VARCHAR(50) '$."GASTOS GENERALES"',
            Agua_JSON VARCHAR(50) '$."SERVICIOS PUBLICOS-Agua"',
            Luz_JSON VARCHAR(50) '$."SERVICIOS PUBLICOS-Luz"'
        ) AS JSON_Pivote
        
        CROSS APPLY (VALUES
            ('BANCARIOS', Bancarios_JSON),
            ('LIMPIEZA', Limpieza_JSON),
            ('ADMINISTRACION', Admin_JSON),
            ('SEGUROS', Seguros_JSON),
            ('GASTOS GENERALES', Generales_JSON),
            ('SERVICIOS PUBLICOS-Agua', Agua_JSON),
            ('SERVICIOS PUBLICOS-Luz', Luz_JSON)
        ) AS Gastos_Unpivot(Tipo_Nombre, Importe_JSON)

        CROSS APPLY (
            SELECT CASE LOWER(LTRIM(RTRIM(JSON_Pivote.Mes_JSON)))
                WHEN 'enero' THEN 1 WHEN 'febrero' THEN 2 WHEN 'marzo' THEN 3
                WHEN 'abril' THEN 4 WHEN 'mayo' THEN 5 WHEN 'junio' THEN 6
                WHEN 'julio' THEN 7 WHEN 'agosto' THEN 8 WHEN 'septiembre' THEN 9
                WHEN 'octubre' THEN 10 WHEN 'noviembre' THEN 11 WHEN 'diciembre' THEN 12
                ELSE NULL
            END AS MesN
        ) AS MesNumero

        JOIN Consorcio C ON C.Nombre = JSON_Pivote.NombreConsorcio_JSON
        JOIN Tipo_Gasto TG ON TG.Nombre = 
            CASE 
                WHEN Gastos_Unpivot.Tipo_Nombre LIKE 'SERVICIOS PUBLICOS%' THEN 'SERVICIOS PUBLICOS'
                ELSE Gastos_Unpivot.Tipo_Nombre 
            END
        
        WHERE Gastos_Unpivot.Importe_JSON IS NOT NULL 
          AND MesNumero.MesN IS NOT NULL; 

        
        -- INSERTAR
        PRINT 'Insertando datos en Gasto_Ordinario...';

        MERGE INTO Gasto_Ordinario AS T
        USING #TempGastos AS S
        ON (T.Id_Consorcio = S.Id_Consorcio AND T.Id_Tipo_Gasto = S.Id_Tipo_Gasto AND T.Fecha = S.Fecha_Gasto)

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (Id_Consorcio, Id_Tipo_Gasto, Fecha, Importe_Total, Descripcion)
            VALUES (S.Id_Consorcio, S.Id_Tipo_Gasto, S.Fecha_Gasto, S.Importe_Total, S.Descripcion_Gasto)
        
        WHEN MATCHED THEN
            UPDATE SET
                T.Importe_Total = S.Importe_Total,
                T.Descripcion = S.Descripcion_Gasto;
        
        PRINT 'Importación de Gastos JSON completada.';

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: No se pudo importar el archivo JSON.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    DROP TABLE #TempGastos;
    SET NOCOUNT OFF;
END
GO
 
USE bd_tp_testeo
EXEC sp_Importar_Gastos_JSON @RutaArchivoJSON = 'D:\Diego\Downloads\ARCHIVOS_TP_BDA\ARCHIVOS\Servicios.Servicios.json';
GO

SELECT * FROM Gasto_Ordinario